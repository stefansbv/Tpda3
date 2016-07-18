package Tpda3::Engine::odbcfb;

# ABSTRACT: Connect with ODBC to a Firebird database

use 5.010001;
use Moose;
use Locale::TextDomain qw(Tpda3);
use Try::Tiny;
use Regexp::Common;
use Log::Log4perl qw(:levels);
use namespace::autoclean;

use Tpda3::Exceptions;

extends 'Tpda3::Engine';
sub dbh;                                     # required by DBIEngine;
with qw(Tpda3::Role::DBIEngine
        Tpda3::Role::DBIMessages);

has conn => (
    is      => 'rw',
    isa     => 'DBIx::Connector',
    lazy    => 1,
    clearer => 'reset_conn',
    default => sub {
        my $self = shift;
        my $uri  = $self->uri;
        my $dsn  = $uri->dbi_dsn . ';ib_dialect=3;ib_charset=UTF8';
        $self->use_driver;
        $self->logger->debug("Connecting: $dsn");
        return DBIx::Connector->new($dsn, $uri->user, $uri->password, {
            $uri->query_params,
            PrintError       => 0,
            RaiseError       => 0,
            AutoCommit       => 1,
            ib_enable_utf8   => 1,
            ib_time_all      => 'ISO',
            FetchHashKeyName => 'NAME_lc',
            LongReadLen      => 524288,
            HandleError      => sub { $self->handle_error(@_) },
        });
     },
);

has dbh => (
    is      => 'rw',
    isa     => 'DBI::db',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->conn->dbh;
    },
);

sub parse_error {
    my ( $self, $err ) = @_;

    $self->logger->error("DBErr: $err");

    my $message_name
        = $err eq q{} ? "nomessage"
        : $err =~ m/operation for file ($RE{quoted})/smi ? "dbnotfound:$1"
        : $err =~ m/\-Table unknown\s*\-(.*)\-/smi       ? "relnotfound:$1"
        : $err =~ m/\-Token unknown -\s*(.*)/smi         ? "badtoken:$1"
        : $err =~ m/\-Column unknown\s*\-(.*)/smi        ? "colnotfound:$1"
        : $err =~ m/Your user name and password/smi      ? "userpass"
        : $err =~ m/no route to host/smi                 ? "network"
        : $err =~ m/network request to host ($RE{quoted})/smi ? "nethost:$1"
        : $err =~ m/install_driver($RE{balanced}{-parens=>'()'})/smi ? "driver:$1"
        : $err =~ m/not connected/smi                    ? "notconn"
        :                                                  "unknown";

    my ( $name, $param ) = split /:/x, $message_name, 2;
    return ('errstr', $err) if $ name eq "unknown";
    $param = $param ? $param : '';
    $name =~ s{\n\-}{\ }xgsm;         # remove the dashes from the messag

    return ($name, $param);
}

sub key    { 'odbcfb' }
sub name   { 'odbcfb' }
sub driver { 'DBD::ODBC 1.43' }

sub get_info {
    my ($self, $table, $key_field) = @_;

    die "Missing required arguments: table" unless $table;

    $key_field ||= 'name';

    my $sql = qq(SELECT RDB\$FIELD_POSITION AS pos
                    , LOWER(r.RDB\$FIELD_NAME) AS name
                    , r.RDB\$DEFAULT_VALUE AS defa
                    , CASE
                       WHEN r.RDB\$NULL_FLAG IS NULL THEN 1
                       ELSE 0
                      END AS is_nullable
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
                    WHERE r.RDB\$RELATION_NAME = UPPER('$table')
                    ORDER BY r.RDB\$FIELD_POSITION;
    );

    my $dbh = $self->dbh;

    $dbh->{ChopBlanks} = 1;    # trim CHAR fields

    my $flds_ref;
    try {
        my $sth = $dbh->prepare($sql);
        $sth->execute;
        $flds_ref = $sth->fetchall_hashref($key_field);
    }
    catch {
        $self->logger->error("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $flds_ref;
}

sub table_keys {
    my ( $self, $table, $foreign ) = @_;

    die "Missing required arguments: table" unless $table;

    my $type = $foreign ? 'FOREIGN KEY' : 'PRIMARY KEY';

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
                      ORDER BY s.RDB\$FIELD_POSITION;
    );

    my $dbh = $self->dbh;
    $dbh->{AutoCommit} = 1;    # disable transactions
    $dbh->{RaiseError} = 0;
    $dbh->{ChopBlanks} = 1;    # trim CHAR fields

    my $pkf_aref;
    try {
        $pkf_aref = $dbh->selectcol_arrayref($sql);
    }
    catch {
        $self->logger->error("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $pkf_aref;
}

sub get_columns {
    my ($self, $table) = @_;

    die "Missing required arguments: table" unless $table;

    my $sql = qq(SELECT LOWER(r.RDB\$FIELD_NAME) AS name
                    FROM RDB\$RELATION_FIELDS r
                    WHERE r.RDB\$RELATION_NAME = UPPER('$table')
                    ORDER BY r.RDB\$FIELD_POSITION;
    );

    my $dbh = $self->dbh;

    $dbh->{ChopBlanks} = 1;    # trim CHAR fields

    my $column_list;
    try {
        $column_list = $dbh->selectcol_arrayref($sql);
    }
    catch {
        $self->logger->error("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $column_list;
}

sub table_exists {
    my ( $self, $table ) = @_;

    die "Missing required arguments: table" unless $table;

    my $sql = qq(SELECT COUNT(RDB\$RELATION_NAME)
                     FROM RDB\$RELATIONS
                     WHERE RDB\$SYSTEM_FLAG=0
                         AND RDB\$VIEW_BLR IS NULL
                         AND RDB\$RELATION_NAME = UPPER('$table');
    );

    my $val_ret;
    try {
        ($val_ret) = $self->dbh->selectrow_array($sql);
    }
    catch {
        $self->logger->error("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $val_ret;
}

sub table_list {
    my $self = shift;

    my $sql = q{SELECT TRIM(LOWER(RDB$RELATION_NAME)) AS table_name
                   FROM RDB$RELATIONS
                    WHERE RDB$SYSTEM_FLAG=0
                      AND RDB$VIEW_BLR IS NULL
    };

    my $dbh = $self->dbh;
    $dbh->{AutoCommit} = 1;    # disable transactions
    $dbh->{RaiseError} = 0;

    my $table_list;
    try {
        $table_list = $dbh->selectcol_arrayref($sql);
    }
    catch {
        $self->logger->error("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $table_list;
}

sub view_list {
    my $self = shift;

    my $sql = q{SELECT DISTINCT TRIM(LOWER(RDB$VIEW_NAME)) AS view_name
                    FROM RDB$VIEW_RELATIONS;
    };

    my $dbh = $self->dbh;
    $dbh->{AutoCommit} = 1;    # disable transactions
    $dbh->{RaiseError} = 0;

    my $view_list;
    try {
        $view_list = $dbh->selectcol_arrayref($sql);
    }
    catch {
        $self->logger->error("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $view_list;
}

sub procedure_list {
    my $self = shift;

    my $sql = q{SELECT TRIM(LOWER(RDB$PROCEDURE_NAME)) AS proc_name
                    FROM RDB$PROCEDURES;
    };

    my $dbh = $self->dbh;
    $dbh->{AutoCommit} = 1;    # disable transactions
    $dbh->{RaiseError} = 0;

    my $proc_list;
    try {
        $proc_list = $dbh->selectcol_arrayref($sql);
    }
    catch {
        $self->logger->error("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $proc_list;
}

sub trigger_list {
    my $self = shift;

    my $sql = q{SELECT TRIM(LOWER(RDB$TRIGGER_NAME)) AS trigger_name,
                       TRIM(LOWER(RDB$RELATION_NAME)) AS table_name
                    FROM RDB$TRIGGERS
                    WHERE RDB$SYSTEM_FLAG=0;
    };

    my $dbh = $self->dbh;
    $dbh->{AutoCommit} = 1;    # disable transactions
    $dbh->{RaiseError} = 0;

    my $triggers;
    try {
        $triggers = $dbh->selectall_arrayref(
            $sql, { Slice => {} }
        );                                   # return an AoH
    }
    catch {
        $self->logger->error("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $triggers;
}

sub sequences_list {
    my $self = shift;

    my $sql = q{SELECT TRIM(RDB$GENERATOR_NAME)
                    FROM RDB$GENERATORS
                    WHERE RDB$SYSTEM_FLAG=0;
    };

    my $dbh = $self->dbh;
    $dbh->{AutoCommit} = 1;    # disable transactions
    $dbh->{RaiseError} = 0;

    my $seq_list;
    try {
        $seq_list = $dbh->selectcol_arrayref($sql);
    }
    catch {
        $self->logger->error("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $seq_list;
}

sub has_feature_returning { 1 }

__PACKAGE__->meta->make_immutable;

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
