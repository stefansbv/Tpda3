package Tpda3::Engine::cubrid;

# ABSTRACT: Connect to a Cubrid database

use Moo;
use Locale::TextDomain 1.20 qw(Tpda3);
use Try::Tiny;
use Regexp::Common;
use Tpda3::Types qw(
    DBIxConnector
    DBIdb
);
use Tpda3::Exceptions;
use namespace::autoclean;

extends 'Tpda3::Engine';
sub dbh;                                     # required by DBIEngine;
with qw(Tpda3::Role::DBIEngine
        Tpda3::Role::DBIMessages);

has conn => (
    is      => 'rw',
    isa     => DBIxConnector,
    lazy    => 1,
    clearer => 'reset_conn',
    default => sub {
        my $self = shift;
        my $uri  = $self->uri;
        my $dsn  = $uri->dbi_dsn;
        $self->use_driver;
        $self->logger->debug("Connecting: $dsn");
        return DBIx::Connector->new($dsn, $uri->user, $uri->password, {
            $uri->query_params,
            PrintError       => 0,
            RaiseError       => 0,
            AutoCommit       => 1,
            HandleError      => sub { $self->handle_error(@_) },
        });
    }
);

has dbh => (
    is      => 'rw',
    isa     => DBIdb,
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->conn->dbh;
    },
);

sub parse_error {
    my ( $self, $err ) = @_;

    my $log = get_logger();

    $log->error("EE: $err");

    my $message_name
        = $err eq q{}                                         ? "nomessage"
        : $err =~ m/Cannot connect to CUBRID CAS/smi          ? "servererr"
        : $err =~ m/Failed to connect to database server, ($RE{quoted})/smi
                                                             ? "serverdb:$1"
        : $err =~ m/Cannot communicate with server/smi        ? "servererr"
        : $err =~ m/User ($RE{quoted}) is invalid/smi         ? "username:$1"
        : $err =~ m/Incorrect or missing password/smi         ? "password"
        : $err =~ m/Missing value for attribute ($RE{quoted}) with the NOT NULL constraint/smi
                                                             ? "attrib:$1"
        :                                                      "unknown"
        ;

    my ( $name, $param ) = split /:/x, $message_name, 2;
    $param = $param ? $param : '';

    return ($name, $param);

    # my $translations = {
    #     driver     => "error#Database driver for CUBRID not found",
    #     serverdb   => "error#Database not available $name",
    #     servererr  => "error#Server not available",
    #     username   => "error#User $name is invalid",
    #     attrib     => "error#Attribute $name error (NULL)",
    #     password   => "error#Incorrect or missing password",
    # };
}

sub key    { 'cubrid' }
sub name   { 'CUBRID' }
sub driver { 'cubrid' }

sub get_info {
    my ( $self, $table ) = @_;

    die "Missing required arguments: table" unless $table;

    my $sth = $self->dbh->column_info(undef, undef, $table, undef);
    my $flds_ref;
    try {
        while ( my $rec = $sth->fetchrow_hashref() ) {
            my ( $type, $length )
                = $self->type_and_length( $rec->{TYPE_NAME} );
            my $pos = $rec->{ORDINAL_POSITION};
            $flds_ref->{$pos} = {
                pos         => $pos,
                name        => $rec->{COLUMN_NAME},
                type        => $type,
                defa        => undef,                    # how to get?
                is_nullable => $rec->{NULLABLE},
                length      => $rec->{COLUMN_SIZE},      # $length?
                prec        => $rec->{COLUMN_SIZE},
                scale       => $rec->{DECIMAL_DIGITS},
            };
        }
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

    my $pkf;
    try {
        my $sth = $self->{_dbh}->primary_key_info( undef, undef, $table );
        # table_cat table_schem table_name COLUMN_NAME key_seq pk_name
        # 0         1           2          3           4       5
        $pkf = [ ( $sth->fetchall_arrayref() )->[0][3] ];
        # All keys
        # while ( my $row_rf = $sth->fetchrow_arrayref() ) {
        #     push @keys, $row_rf->[3];
        # }
    }
    catch {
        $self->logger->error("Transaction aborted because $_")
            or print STDERR "$_\n";
    };
    return $pkf;
}

sub get_columns {
    my ($self, $table) = @_;
    # die "Missing required arguments: table" unless $table;
    die "get_columns: Not implemented for CUBRID!";
    return;
}

sub table_exists {
    my ( $self, $table ) = @_;

    die "Missing required arguments: table" unless $table;

    my $sql = qq(SELECT class_name
                    FROM db_class
                    WHERE is_system_class = 'NO'
                           AND class_name = '$table';
    );
    my $val_ret;
    try {
        ($val_ret) = $self->{_dbh}->selectrow_array($sql);
    }
    catch {
         $self->logger->error("Transaction aborted because $_")
            or print STDERR "$_\n";
    };
    return $val_ret;
}

sub table_list {
    my $self = shift;

    my $sql = q{SELECT class_name
                    FROM db_class WHERE is_system_class = 'NO';
    };

    $self->{_dbh}{AutoCommit} = 1;    # disable transactions
    $self->{_dbh}{RaiseError} = 0;

    my $table_list;
    try {
        $table_list = $self->{_dbh}->selectcol_arrayref($sql);
    }
    catch {
        $self->logger->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };
    return $table_list;
}

#--- helper methods

sub type_and_length {
    my ($self, $type_name) = @_;
    my ($type, $length);
    if ( $type_name =~ /^(\w+)($RE{balanced}{-parens=>'()'})/ ) {
        $type   = $1;
        $length = $2;
        ( $length = $2 ) =~ s/[()]//g;
    }
    else {
        $type_name =~ /^(\w+)/;
        $type   = $1;
        $length = 10;
    }
    return (lc($type), $length);
}

sub has_feature_returning { 0 }

1;

__END__

=encoding utf8

=head1 NAME

Tpda3::Engine::pg - Tpda3 PostgreSQL engine

=head1 SYNOPSIS

  my $engine = Tpda3::Engine->load( engine => 'pg' );

=head1 DESCRIPTION

Tpda3::Engine::pg provides the Pg database engine
for Tpda3Dev.  It supports Pg X.X and higher XXX ???.

=head1 INTERFACE

=head3 dbh

=head3 key

=head3 name

=head3 driver

=head2 INSTANCE METHODS

=head2 C<parse_error>

Parse a database error message, and translate it for the user.

RDBMS specific (and maybe version specific?).

=head3 get_info

=head2 table_keys

Get the primary key field name of the table.

=head3 get_columns

=head3 table_exists

Check if table exists in the database.

=head2 table_list

Return list of tables from the database.

=head2 type_and_length

Parse the TYPE_NAME attribute and return SQL type and a length.  The
TYPE_NAME can be something like VARCHAR(30) or INTEGER.  If there is
no length, return 10.

=head2 has_feature_returning

Returns no for CUBRID, meaning that is has not the INSERT... RETURNING
feature.

=cut
