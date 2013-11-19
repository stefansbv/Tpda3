package Tpda3::Db::Connection::Postgresql;

use strict;
use warnings;

use DBI;
use Log::Log4perl qw(get_logger :levels);
use Regexp::Common;
use Try::Tiny;

require Tpda3::Exceptions;

=head1 NAME

Tpda3::Db::Connection::Postgresql - Connect to a PostgreSQL database.

=head1 VERSION

Version 0.70

=cut

our $VERSION = 0.70;

=head1 SYNOPSIS

    use Tpda3::Db::Connection::Postgresql;

    my $db = Tpda3::Db::Connection::Postgresql->new();

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

    my ($dbname, $host, $port) = @{$conf}{qw(dbname host port)};
    my ($driver, $user, $pass) = @{$conf}{qw(driver user pass)};

    $log->trace("Database driver is: $driver");
    $log->trace("Parameters:");
    $log->trace(" > Database = ", $dbname ? $dbname : '?', "\n");
    $log->trace(" > Host     = ", $host   ? $host   : '?', "\n");
    $log->trace(" > Port     = ", $port   ? $port   : '?', "\n");
    $log->trace(" > User     = ", $user   ? $user   : '?', "\n");

    my $dsn = qq{dbi:Pg:dbname=$dbname;host=$host;port=$port};

    $self->{_dbh} = DBI->connect(
        $dsn, $user, $pass,
        {   FetchHashKeyName => 'NAME_lc',
            AutoCommit       => 1,
            RaiseError       => 1,
            PrintError       => 0,
            LongReadLen      => 524288,
            HandleError      => sub { $self->handle_error() },
            pg_enable_utf8   => 1,
        }
    );

    ## Date format
    # set: datestyle = 'iso' in postgresql.conf
    ##

    return $self->{_dbh};
}

=head2 handle_error

Log errors.

=cut

sub handle_error {
    my $self = shift;

    if ( defined $self->{_dbh} and $self->{_dbh}->isa('DBI::db') ) {
        my $errorstr = $self->{_dbh}->errstr;
        Exception::Db::SQL->throw(
            logmsg  => $errorstr,
            usermsg => $self->parse_error($errorstr),
        );
    }
    else {
        my $errorstr = DBI->errstr;
        Exception::Db::Connect->throw(
            logmsg  => $errorstr,
            usermsg => $self->parse_error($errorstr),
        );
    }

    return;
}

=head2 parse_error

Parse a database error message, and translate it for the user.

Better way to do this?

=cut

sub parse_error {
    my ($self, $pg) = @_;

    my $log = get_logger();

    print "\nPG: $pg\n\n";

    my $message_type =
         $pg eq q{}                                          ? "nomessage"
       : $pg =~ m/database ($RE{quoted}) does not exist/smi  ? "dbnotfound:$1"
       : $pg =~ m/ERROR:  column ($RE{quoted}) of relation ($RE{quoted}) does not exist/smi
                                                            ? "colnotfound:$2.$1"
       : $pg =~ m/ERROR:  null value in column ($RE{quoted})/smi ? "nullvalue:$1"
       : $pg =~ m/ERROR:  syntax error at or near ($RE{quoted})/smi ? "syntax:$1"
       : $pg =~ m/violates check constraint ($RE{quoted})/smi ? "checkconstr:$1"
       : $pg =~ m/relation ($RE{quoted}) does not exist/smi  ? "relnotfound:$1"
       : $pg =~ m/authentication failed .* ($RE{quoted})/smi ? "password:$1"
       : $pg =~ m/no password supplied/smi                   ? "password"
       : $pg =~ m/FATAL:  role ($RE{quoted}) does not exist/smi ? "username:$1"
       : $pg =~ m/no route to host/smi                       ? "network"
       : $pg =~ m/DETAIL:  Key ($RE{balanced}{-parens=>'()'})=/smi ? "duplicate:$1"
       : $pg =~ m/permission denied for relation/smi         ? "relforbid"
       : $pg =~ m/could not connect to server/smi            ? "servererror"
       : $pg =~ m/not connected/smi                          ? "notconn"
       :                                                       "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        dbnotfound  => "error#Database $name does not exists",
        relnotfound => "error#Relation $name does not exists",
        password    => "info#Authentication failed for $name",
        password    => "info#Authentication failed, password?",
        username    => "error#Wrong user name: $name",
        network     => "error#Network problem",
        unknown     => "error#Database error",
        servererror => "error#Server not available",
        duplicate   => "error#Duplicate $name",
        colnotfound => "error#Column not found $name",
        checkconstr => "error#Check: $name",
        nullvalue   => "error#Null value for $name",
        relforbid   => "error#Permission denied",
        notconn     => "error#Not connected",
        syntax      => "error#SQL syntax error",
    };

    my $message;
    if (exists $translations->{$type} ) {
        $message = $translations->{$type}
    }
    else {
        $log->error('EE: Translation error for: $pg!');
    }

    return $message;
}

=head2 table_info_short

Table info 'short'.  The 'table_info' method from the Pg driver
doesn't seem to be reliable.

=cut

sub table_info_short {
    my ( $self, $table ) = @_;

    my $log = get_logger();
    $log->info("Geting table info for $table");

    my $sql = qq( SELECT ordinal_position  AS pos
                    , column_name       AS name
                    , data_type         AS type
                    , column_default    AS defa
                    , is_nullable
                    , character_maximum_length AS length
                    , numeric_precision AS prec
                    , numeric_scale     AS scale
               FROM information_schema.columns
               WHERE table_name = '$table'
               ORDER BY ordinal_position;
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

=head2 table_exists

Check if table exists in the database.

=cut

sub table_exists {
    my ( $self, $table ) = @_;

    my $log = get_logger();
    $log->info("Checking if $table table exists");

    my $sql = qq( SELECT COUNT(table_name)
                FROM information_schema.tables
                WHERE table_type = 'BASE TABLE'
                    AND table_schema NOT IN
                    ('pg_catalog', 'information_schema')
                    AND table_name = '$table';
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

=head2 table_keys

Get the primary key field name of the table.

=cut

sub table_keys {
    my ( $self, $table, $foreign ) = @_;

    my $log = get_logger();

    my $type = $foreign ? 'FOREIGN KEY' : 'PRIMARY KEY';

    $log->info("Geting '$table' table primary key(s) names");

    my $sql = qq( SELECT kcu.column_name
                   FROM information_schema.table_constraints tc
                     LEFT JOIN information_schema.key_column_usage kcu
                          ON tc.constraint_catalog = kcu.constraint_catalog
                            AND tc.constraint_schema = kcu.constraint_schema
                            AND tc.constraint_name = kcu.constraint_name
                   WHERE tc.table_name = '$table'
                     AND tc.constraint_type = '$type';
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

=head2 table_deps

Return table dependencies and their Id field.

=cut

sub table_deps {
    my ( $self, $table ) = @_;

    return;
}

=head2 table_list

Return list of tables from the database.

=cut

sub table_list {
    my $self = shift;

    my $log = get_logger();

    $log->info('Geting list of tables');

    my $sql = q{ SELECT table_name
                      FROM information_schema.tables
                      WHERE table_type = 'BASE TABLE'
                        AND table_schema NOT IN
                            ('pg_catalog', 'information_schema');
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

=head2 sequences_list

Return list of sequences from the database.

=cut

sub sequences_list {
    my $self = shift;

    my $log = get_logger();

    $log->info('Geting list of sequences');

    my $sql = q{SELECT relname
    FROM pg_class
    WHERE relkind = 'S' AND relnamespace IN (
        SELECT oid
            FROM pg_namespace
            WHERE nspname NOT LIKE 'pg_%' AND nspname != 'information_schema')
    };

    $self->{_dbh}->{AutoCommit} = 1;    # disable transactions
    $self->{_dbh}->{RaiseError} = 0;

    my $seq_list;
    try {
        $seq_list = $self->{_dbh}->selectcol_arrayref($sql);
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $seq_list;
}

=head2 constraints_list

Return list of constraints for a table from the database.

=cut

sub constraints_list {
    my ($self, $table) = @_;

    my $log = get_logger();

    $log->info('Geting list of constraints');

    my $sql = qq{SELECT tc.constraint_name
                      , tc.constraint_type
                      , kcu.column_name
                      , ccu.table_name AS references_table
                      , ccu.column_name AS references_field
                    FROM information_schema.table_constraints tc
                      LEFT JOIN information_schema.key_column_usage kcu
                        ON tc.constraint_catalog = kcu.constraint_catalog
                        AND tc.constraint_schema = kcu.constraint_schema
                        AND tc.constraint_name = kcu.constraint_name
                      LEFT JOIN information_schema.referential_constraints rc
                        ON tc.constraint_catalog = rc.constraint_catalog
                        AND tc.constraint_schema = rc.constraint_schema
                        AND tc.constraint_name = rc.constraint_name
                      LEFT JOIN information_schema.constraint_column_usage ccu
                        ON rc.unique_constraint_catalog = ccu.constraint_catalog
                        AND rc.unique_constraint_schema = ccu.constraint_schema
                        AND rc.unique_constraint_name = ccu.constraint_name
                  WHERE tc.table_name = '$table' AND constraint_type != 'CHECK'};

    $self->{_dbh}{ChopBlanks} = 1;    # trim CHAR fields

    my $flds_ref;
    try {
        my $sth = $self->{_dbh}->prepare($sql);
        $sth->execute;
        $flds_ref = $sth->fetchall_hashref('constraint_type');
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $flds_ref;
}

=head2 has_feature_returning

Returns yes for PostgreSQL, meaning that is has the
INSERT... RETURNING feature.

Should check for the PostgreSQL version?

=cut

sub has_feature_returning { 1 }

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Information schema queries by Lorenzo Alberton from
http://www.alberton.info/postgresql_meta_info.html

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Db::Connection::Postgresql
