package Tpda3::Db::Connection::Firebird;

use strict;
use warnings;

use Regexp::Common;
use Log::Log4perl qw(get_logger);

use Try::Tiny;
use DBI;

=head1 NAME

Tpda3::Db::Connection::Firebird - Connect to a Firebird database.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use Tpda3::Db::Connection::Firebird;

    my $db = Tpda3::Db::Connection::Firebird->new();

    $db->db_connect($connection);


=head1 METHODS

=head2 new

Constructor

=cut

sub new {
    my ($class, $model) = @_;

    my $self = {};

    $self->{model} = $model;

    bless $self, $class;

    return $self;
}

=head2 db_connect

Connect to database

=cut

sub db_connect {
    my ( $self, $conf ) = @_;

    my $log = get_logger();

    $log->trace("Database driver is: $conf->{driver}");
    $log->trace("Parameters:");
    $log->trace(" > Database = ",$conf->{dbname} ? $conf->{dbname} : '?', "\n");
    $log->trace(" > Host     = ",$conf->{host} ? $conf->{hosst} : '?', "\n");
    $log->trace(" > User     = ",$conf->{user} ? $conf->{user} : '?', "\n");

    try {
        $self->{_dbh} = DBI->connect(
            "dbi:Firebird:"
                . "dbname="
                . $conf->{dbname}
                . ";host="
                . $conf->{host}
                . ";port="
                . $conf->{port}
                . ";ib_dialect=3"
                . ";ib_charset=UTF8",
            $conf->{user},
            $conf->{pass},
            {   FetchHashKeyName => 'NAME_lc',
                AutoCommit       => 1,
                RaiseError       => 1,
                PrintError       => 0,
                LongReadLen      => 524288,
            }
        );
    }
    catch {
        my $user_message = $self->parse_db_error($_);
        $self->{model}->exception_log($user_message);
    };

    ## Date format
    ## Default format: ISO
    $self->{_dbh}->{ib_timestampformat} = '%y-%m-%d %H:%M';
    $self->{_dbh}->{ib_dateformat}      = '%Y-%m-%d';
    $self->{_dbh}->{ib_timeformat}      = '%H:%M';

    $self->{_dbh}{ib_enable_utf8} = 1;

    $log->info("Connected to '$conf->{dbname}'");

    return $self->{_dbh};
}

=head2 parse_db_error

Parse a database error message, and translate it for the user.

RDBMS specific (and maybe version specific?).

=cut

sub parse_db_error {
    my ($self, $fb) = @_;

    # print "\nFB: $fb\n\n";

    my $message_type =
         $fb eq q{}                                          ? "nomessage"
       : $fb =~ m/operation for file ($RE{quoted})/smi       ? "dbnotfound:$1"
       : $fb =~ m/\-Table unknown\s*\-(.*)\-/smi             ? "relnotfound:$1"
       : $fb =~ m/user name and password/smi                 ? "userpass"
       : $fb =~ m/no route to host/smi                       ? "network"
       : $fb =~ m/network request to host ($RE{quoted})/smi  ? "nethost:$1"
       :                                                       "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        nomessage   => "weird#Error without message",
        dbnotfound  => "fatal#Database $name not found",
        relnotfound => "fatal#Relation $name not found",
        userpass    => "info#Authentication failed, password?",
        nethost     => "fatal#Network problem: host $name",
        network     => "fatal#Network problem",
        unknown     => "fatal#Database error",
    };

    my $message;
    if (exists $translations->{$type} ) {
        $message = $translations->{$type}
    }
    else {
        print "EE: Translation error!\n";
    }

    return $message;
}

=head2 table_list

Return list of tables from the database.

=cut

sub table_list {
    my $self = shift;

    my $log = get_logger();

    $log->info('Geting list of tables');

    my $sql = q{SELECT RDB$RELATION_NAME
                   FROM RDB$RELATIONS
                    WHERE RDB$SYSTEM_FLAG=0
                      AND RDB$VIEW_BLR IS NULL
    };

    $self->{_dbh}->{AutoCommit} = 1;    # disable transactions
    $self->{_dbh}->{RaiseError} = 0;

    my $table_list;
    try {
        $table_list = $self->{_dbh}->selectcol_arrayref($sql);
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $table_list;
}

=head2 table_info_short

Table info 'short'.  The 'table_info' method from the Firebird driver
doesn't seem to be reliable.

=cut

sub table_info_short {
    my ( $self, $table ) = @_;

    my $log = get_logger();
    $log->info("Geting table info for $table");

    $table = uc $table;

    my $sql = qq( SELECT RDB\$FIELD_POSITION AS pos
                    , r.RDB\$FIELD_NAME AS name
                    , r.RDB\$DESCRIPTION AS field_description
                    , r.RDB\$DEFAULT_VALUE AS defa
                    , r.RDB\$NULL_FLAG AS is_nullable
                    , f.RDB\$FIELD_LENGTH AS length
                    , f.RDB\$FIELD_PRECISION AS prec
                    , f.RDB\$FIELD_SCALE AS scale
                    FROM RDB\$RELATION_FIELDS r
                       LEFT JOIN RDB\$FIELDS f
                            ON r.RDB\$FIELD_SOURCE = f.RDB\$FIELD_NAME
                    WHERE r.RDB\$RELATION_NAME = '$table'
                    ORDER BY r.RDB\$FIELD_POSITION;
    );

    $self->{_dbh}{ChopBlanks} = 1;    # trim CHAR fields

    my $flds_ref;
    try {
        my $sth = $self->{_dbh}->prepare($sql);
        $sth->execute;
        $flds_ref = $sth->fetchall_hashref('pos');
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $flds_ref;
}


=head2 table_keys

Get the primary key field name of the table.

=cut

sub table_keys {
    my ( $self, $table, $foreign ) = @_;

    my $log = get_logger();

    my $type = 'PRIMARY KEY';
    $type = 'FOREIGN KEY' if $foreign;

    $log->info("Geting '$table' table primary key(s) names");

    $table = uc $table;

    my $sql = qq( SELECT s.RDB\$FIELD_NAME AS column_name
                     FROM RDB\$INDEX_SEGMENTS s
                        LEFT JOIN RDB\$INDICES i
                          ON i.RDB\$INDEX_NAME = s.RDB\$INDEX_NAME
                        LEFT JOIN RDB\$RELATION_CONSTRAINTS rc
                          ON rc.RDB\$INDEX_NAME = s.RDB\$INDEX_NAME
                        LEFT JOIN RDB\$REF_CONSTRAINTS refc
                          ON rc.RDB\$CONSTRAINT_NAME = refc.RDB\$CONSTRAINT_NAME
                        LEFT JOIN RDB\$RELATION_CONSTRAINTS rc2
                          ON rc2.RDB\$CONSTRAINT_NAME = refc.RDB\$CONST_NAME_UQ
                        LEFT JOIN RDB\$INDICES i2
                          ON i2.RDB\$INDEX_NAME = rc2.RDB\$INDEX_NAME
                        LEFT JOIN RDB\$INDEX_SEGMENTS s2
                          ON i2.RDB\$INDEX_NAME = s2.RDB\$INDEX_NAME
                      WHERE i.RDB\$RELATION_NAME = '$table'
                        AND rc.RDB\$CONSTRAINT_TYPE = '$type'
    );

    $log->trace("SQL= $sql");

    $self->{_dbh}{AutoCommit} = 1;    # disable transactions
    $self->{_dbh}{RaiseError} = 0;

    my $pkf;
    try {
        $pkf = $self->{_dbh}->selectcol_arrayref($sql);
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $pkf;
}

# SELECT rc.RDB$CONSTRAINT_NAME,
#           s.RDB$FIELD_NAME AS field_name,
#           rc.RDB$CONSTRAINT_TYPE AS constraint_type,
#           i.RDB$DESCRIPTION AS description,
#           rc.RDB$DEFERRABLE AS is_deferrable,
#           rc.RDB$INITIALLY_DEFERRED AS is_deferred,
#           refc.RDB$UPDATE_RULE AS on_update,
#           refc.RDB$DELETE_RULE AS on_delete,
#           refc.RDB$MATCH_OPTION AS match_type,
#           i2.RDB$RELATION_NAME AS references_table,
#           s2.RDB$FIELD_NAME AS references_field,
#           (s.RDB$FIELD_POSITION + 1) AS field_position
#      FROM RDB$INDEX_SEGMENTS s
# LEFT JOIN RDB$INDICES i ON i.RDB$INDEX_NAME = s.RDB$INDEX_NAME
# LEFT JOIN RDB$RELATION_CONSTRAINTS rc ON rc.RDB$INDEX_NAME = s.RDB$INDEX_NAME
# LEFT JOIN RDB$REF_CONSTRAINTS refc ON rc.RDB$CONSTRAINT_NAME = refc.RDB$CONSTRAINT_NAME
# LEFT JOIN RDB$RELATION_CONSTRAINTS rc2 ON rc2.RDB$CONSTRAINT_NAME = refc.RDB$CONST_NAME_UQ
# LEFT JOIN RDB$INDICES i2 ON i2.RDB$INDEX_NAME = rc2.RDB$INDEX_NAME
# LEFT JOIN RDB$INDEX_SEGMENTS s2 ON i2.RDB$INDEX_NAME = s2.RDB$INDEX_NAME
#     WHERE i.RDB$RELATION_NAME='FIRME'       -- table nam
#       AND rc.RDB$CONSTRAINT_TYPE IS NOT NULL
#  ORDER BY s.RDB$FIELD_POSITION

=head2 table_exists

Check if table exists in the database.

TODO: Implement using SQL::Abstract !

=cut

# sub table_exists {
#     my ($self, $table) = @_;

#     my $log = get_logger();
#     $log->info("Checking if $table table exists");

#     my $sql = qq( SELECT COUNT(table_name)
#                 FROM information_schema.tables
#                 WHERE table_type = 'BASE TABLE'
#                     AND table_schema NOT IN
#                     ('pg_catalog', 'information_schema')
#                     AND table_name = '$table';
#     );

#     $log->trace("SQL= $sql");

#     my $val_ret;
#     try {
#         ($val_ret) = $self->{_dbh}->selectrow_array($sql);
#     }
#     catch {
#         $log->fatal("Transaction aborted because $_")
#             or print STDERR "$_\n";
#     };

#     return $val_ret;
# }

=head2 table_keys

Get the primary key field name of the table.

TODO: Implement using SQL::Abstract !

=cut

# sub table_keys {
#     my ($self, $table, $foreign) = @_;

#     my $log = get_logger();

#     my $type = 'PRIMARY KEY';
#     $type = 'FOREIGN KEY' if $foreign;

#     $log->info("Geting '$table' table primary key(s) names");

#     #  From http://www.alberton.info/postgresql_meta_info.html
#     my $sql = qq( SELECT kcu.column_name
#                    FROM information_schema.table_constraints tc
#                      LEFT JOIN information_schema.key_column_usage kcu
#                           ON tc.constraint_catalog = kcu.constraint_catalog
#                             AND tc.constraint_schema = kcu.constraint_schema
#                             AND tc.constraint_name = kcu.constraint_name
#                    WHERE tc.table_name = '$table'
#                      AND tc.constraint_type = '$type';
#     );

#     $log->trace("SQL= $sql");

#     $self->{_dbh}{AutoCommit} = 1;    # disable transactions
#     $self->{_dbh}{RaiseError} = 0;

#     my $pkf = [];
#     try {
#         # List of lists
#         $pkf = $self->{_dbh}->selectall_arrayref( $sql );
#     }
#     catch {
#         $log->fatal("Transaction aborted because $_")
#             or print STDERR "$_\n";
#     };

#     return $pkf;
# }

=head2 table_deps

Return table dependencies and their Id field.

=cut

# sub table_deps {
#     my ($self, $table) = @_;

#     return;
# }

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.
=head1 ACKNOWLEDGEMENTS

Information schema queries by Lorenzo Alberton from
http://www.alberton.info/firebird_sql_meta_info.html

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Db::Connection::Firebird
