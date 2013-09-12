package Tpda3::Db::Connection::Firebird;

use strict;
use warnings;

use DBI;
use Log::Log4perl qw(get_logger :levels);
use Regexp::Common;
use Try::Tiny;

require Tpda3::Exceptions;

=head1 NAME

Tpda3::Db::Connection::Firebird - Connect to a Firebird database.

=head1 VERSION

Version 0.69

=cut

our $VERSION = 0.69;

=head1 SYNOPSIS

    use Tpda3::Db::Connection::Firebird;

    my $db = Tpda3::Db::Connection::Firebird->new();

    $db->db_connect($connection);


=head1 METHODS

=head2 new

Constructor

=cut

sub new {
    my ( $class, $model ) = @_;

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

    my ( $dbname, $host, $port ) = @{$conf}{qw(dbname host port)};
    my ( $driver, $user, $pass ) = @{$conf}{qw(driver user pass)};

    $log->trace("Database driver is: $driver");
    $log->trace("Parameters:");
    $log->trace( " > Database = ", $dbname ? $dbname : '?', "\n" );
    $log->trace( " > Host     = ", $host   ? $host   : '?', "\n" );
    $log->trace( " > Port     = ", $port   ? $port   : '?', "\n" );
    $log->trace( " > User     = ", $user   ? $user   : '?', "\n" );

    my $dsn = qq{dbi:Firebird:dbname=$dbname;host=$host;port=$port};
    $dsn .= q{;ib_dialect=3;ib_charset=UTF8};

    $self->{_dbh} = DBI->connect(
        $dsn, $user, $pass,
        {   FetchHashKeyName => 'NAME_lc',
            AutoCommit       => 1,
            RaiseError       => 0,
            PrintError       => 0,
            LongReadLen      => 524288,
            HandleError      => sub { $self->handle_error() },
            ib_enable_utf8   => 1,
        }
    );

    # Default date format: ISO
    $self->{_dbh}{ib_timestampformat} = '%y-%m-%d %H:%M';
    $self->{_dbh}{ib_dateformat}      = '%Y-%m-%d';
    $self->{_dbh}{ib_timeformat}      = '%H:%M';

    return $self->{_dbh};
}

=head2 handle_error

Log errors.

=cut

sub handle_error {
    my $self = shift;

    my $errorstr;

    if ( defined $self->{_dbh} and $self->{_dbh}->isa('DBI::db') ) {
        $errorstr = $self->{_dbh}->errstr;
        Exception::Db::SQL->throw(
            logmsg  => $errorstr,
            usermsg => $self->parse_error($errorstr),
        );
    }
    else {
        $errorstr = DBI->errstr;
        Exception::Db::Connect->throw(
            logmsg  => $errorstr,
            usermsg => $self->parse_error($errorstr),
        );
    }

    return;
}

=head2 parse_error

Parse a database error message, and translate it for the user.

RDBMS specific (and maybe version specific?).

=cut

sub parse_error {
    my ( $self, $fb ) = @_;

    my $log = get_logger();

    print "\nFB: $fb\n\n";

    my $message_type
        = $fb eq q{} ? "nomessage"
        : $fb =~ m/operation for file ($RE{quoted})/smi ? "dbnotfound:$1"
        : $fb =~ m/\-Table unknown\s*\-(.*)\-/smi       ? "relnotfound:$1"
        : $fb =~ m/Your user name and password/smi      ? "userpass"
        : $fb =~ m/no route to host/smi                 ? "network"
        : $fb =~ m/network request to host ($RE{quoted})/smi ? "nethost:$1"
        : $fb =~ m/install_driver($RE{balanced}{-parens=>'()'})/smi
                                                        ? "driver:$1"
        : $fb =~ m/not connected/smi                    ? "notconn"
        :                                                 "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        driver      => "error#Database driver $name not found",
        dbnotfound  => "error#Database $name not found",
        relnotfound => "error#Relation $name not found",
        userpass    => "error#Authentication failed",
        nethost     => "error#Network problem: host $name",
        network     => "error#Network problem",
        unknown     => "error#Database error",
        notconn     => "error#Not connected",
    };

    my $message;
    if ( exists $translations->{$type} ) {
        $message = $translations->{$type};
    }
    else {
        $log->error('EE: Translation error for: $fb!');
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

    my $sql = q{SELECT LOWER(RDB$RELATION_NAME)
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

    my $sql = qq(SELECT RDB\$FIELD_POSITION AS pos
                    , LOWER(r.RDB\$FIELD_NAME) AS name
                    , r.RDB\$DEFAULT_VALUE AS defa
                    , r.RDB\$NULL_FLAG AS is_nullable
                    , f.RDB\$FIELD_LENGTH AS length
                    , f.RDB\$FIELD_PRECISION AS prec
                    , CASE
                        WHEN f.RDB\$FIELD_SCALE > 0 THEN (f.RDB\$FIELD_SCALE)
                        WHEN f.RDB\$FIELD_SCALE < 0 THEN (f.RDB\$FIELD_SCALE * -1)
                        ELSE 0
                      END AS scale
                    , CASE f.RDB\$FIELD_TYPE
                        WHEN 261 THEN 'blob'
                        WHEN 14  THEN 'char'
                        WHEN 40  THEN 'cstring'
                        WHEN 11  THEN 'd_float'
                        WHEN 27  THEN 'double'
                        WHEN 10  THEN 'float'
                        WHEN 16  THEN
                          CASE f.RDB\$FIELD_SCALE
                            WHEN 0 THEN 'int64'
                            ELSE 'numeric'
                          END
                        WHEN 8   THEN
                          CASE f.RDB\$FIELD_SCALE
                            WHEN 0 THEN 'integer'
                            ELSE 'numeric'
                          END
                        WHEN 9   THEN 'quad'
                        WHEN 7   THEN
                          CASE f.RDB\$FIELD_SCALE
                            WHEN 0 THEN 'smallint'
                            ELSE 'numeric'
                          END
                        WHEN 12  THEN 'date'
                        WHEN 13  THEN 'time'
                        WHEN 35  THEN 'timestamp'
                        WHEN 37  THEN 'varchar'
                      ELSE 'UNKNOWN'
                      END AS type
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

    my $sql = qq( SELECT LOWER(s.RDB\$FIELD_NAME) AS column_name
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

=head2 table_exists

Check if table exists in the database.

=cut

sub table_exists {
    my ( $self, $table ) = @_;

    my $log = get_logger();
    $log->info("Checking if $table table exists");

    $table = uc $table;

    my $sql = qq(SELECT COUNT(RDB\$RELATION_NAME)
                     FROM RDB\$RELATIONS
                     WHERE RDB\$SYSTEM_FLAG=0
                         AND RDB\$VIEW_BLR IS NULL
                         AND RDB\$RELATION_NAME = '$table';
    );

    $log->trace("SQL= $sql");

    my $val_ret;
    try {
        ($val_ret) = $self->{_dbh}->selectrow_array($sql);
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $val_ret;
}

=head2 has_feature_returning

Returns yes for Firebird, meaning that is has the
INSERT... RETURNING feature.

Should check for the Firebird version?

=cut

sub has_feature_returning { 1 }

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Information schema queries inspired from:

 - http://www.alberton.info/firebird_sql_meta_info.html by Lorenzo Alberton
 - Flamerobin Copyright (c) 2004-2013 The FlameRobin Development Team

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Db::Connection::Firebird
