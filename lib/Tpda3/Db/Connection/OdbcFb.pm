package Tpda3::Db::Connection::OdbcFb;

# ABSTRACT: Connect with ODBC to a Firebird database

use strict;
use warnings;

use DBI;
use Log::Log4perl qw(get_logger :levels);
use Regexp::Common;
use Try::Tiny;

require Tpda3::Exceptions;

sub new {
    my ( $class, $model ) = @_;

    my $self = {};

    $self->{model} = $model;

    bless $self, $class;

    return $self;
}

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

    my $dsn = qq{dbi:ODBC:DSN=$dbname};

    $self->{_dbh} = DBI->connect(
        $dsn, $user, $pass,
        {   FetchHashKeyName => 'NAME_lc',
            AutoCommit       => 1,
            RaiseError       => 0,
            PrintError       => 0,
            LongReadLen      => 524288,
            LongTruncOk      => 1,
            HandleError      => sub { $self->handle_error() },
            odbc_enable_utf8 => 1,
        }
    );

    # Default date format: ISO?

    return $self->{_dbh};
}

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

sub parse_error {
    my ( $self, $fb ) = @_;

    my $log = get_logger();

    $log->error("EE: $fb");

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

sub table_list {
    my $self = shift;

    my $log = get_logger();

    $log->info('Geting list of tables');

    my $sql = q{SELECT TRIM(LOWER(RDB$RELATION_NAME))
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

sub table_keys {
    my ( $self, $table, $foreign ) = @_;

    my $log = get_logger();

    my $type = $foreign ? 'FOREIGN KEY' : 'PRIMARY KEY';

    $log->info("Geting '$table' table $type(s) names");

    $table = uc $table;

    my $sql = qq( SELECT TRIM(LOWER(s.RDB\$FIELD_NAME)) AS column_name
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

    my $pkf_aref;
    try {
        $pkf_aref = $self->{_dbh}->selectcol_arrayref($sql);
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $pkf_aref;
}

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

sub sequences_list {
    my $self = shift;

    my $log = get_logger();

    $log->info('Geting list of generators');

    my $sql = q{SELECT TRIM(RDB$GENERATOR_NAME)
                    FROM RDB$GENERATORS
                    WHERE RDB$SYSTEM_FLAG=0;
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

sub has_feature_returning { 1 }

1;

=head1 SYNOPSIS

    use Tpda3::Db::Connection::OdbcFb;

    my $db = Tpda3::Db::Connection::OdbcFb->new();

    $db->db_connect($connection);

=head2 new

Constructor method.

=head2 db_connect

Connect to the database.

=head2 handle_error

Log errors.

=head2 parse_error

Parse a database error message, and translate it for the user.

RDBMS specific (and maybe version specific?).

=head2 table_list

Return list of tables from the database.

=head2 table_info_short

Table info 'short'.  The 'table_info' method from the OdbcFb driver
doesn't seem to be reliable.

=head2 table_keys

Get the primary key field name of the table.

=head2 table_exists

Check if table exists in the database.

=head2 sequences_list

Return list of sequences from the database.

=head2 has_feature_returning

Returns yes for OdbcFb, meaning that is has the
INSERT... RETURNING feature.

Should check for the OdbcFb version?

=head1 ACKNOWLEDGEMENTS

Information schema queries inspired from:

 - http://www.alberton.info/firebird_sql_meta_info.html by Lorenzo Alberton
 - Flamerobin Copyright (c) 2004-2013 The FlameRobin Development Team

=cut
