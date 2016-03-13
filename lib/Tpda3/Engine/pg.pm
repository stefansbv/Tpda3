package Tpda3::Engine::pg;

# ABSTRACT: The PostgreSQL engine

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(App-Tpda3Dev);
use Try::Tiny;
use Regexp::Common;
use namespace::autoclean;

use Tpda3::Exceptions;

extends 'Tpda3::Engine';
sub dbh;                                     # required by DBIEngine;
with qw(Tpda3::Role::DBIEngine
        Tpda3::Role::DBIMessages);

has dbh => (
    is      => 'rw',
    isa     => 'DBI::db',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $uri  = $self->uri;
        $self->use_driver;
        my $dsn = $uri->dbi_dsn;
        return DBI->connect($dsn, scalar $uri->user, scalar $uri->password, {
            $uri->query_params,
            PrintError       => 0,
            RaiseError       => 0,
            AutoCommit       => 1,
            pg_enable_utf8   => 1,
            FetchHashKeyName => 'NAME_lc',
            HandleError      => sub {
                my ($err, $dbh) = @_;
                my ($type, $error) = $self->parse_error($err);
                my $message = $self->get_message($type);
                Exception::Db::SQL->throw(
                    logmsg  => $error,
                    usermsg => $message,
                );

            },
        });
    }
);

sub parse_error {
    my ($self, $err) = @_;

    $self->log->error("EE: $err");

    my $message_type =
         $err eq q{}                                          ? "nomessage"
       : $err =~ m/database ($RE{quoted}) does not exist/smi  ? "dbnotfound:$1"
       : $err =~ m/column ($RE{quoted}) of relation ($RE{quoted}) does not exist/smi
                                                              ? "colnotfound:$2.$1"
       : $err =~ m/null value in column ($RE{quoted})/smi     ? "nullvalue:$1"
       : $err =~ m/syntax error at or near ($RE{quoted})/smi  ? "syntax:$1"
       : $err =~ m/violates check constraint ($RE{quoted})/smi ? "checkconstr:$1"
       : $err =~ m/relation ($RE{quoted}) does not exist/smi  ? "relnotfound:$1"
       : $err =~ m/authentication failed .* ($RE{quoted})/smi ? "passname:$1"
       : $err =~ m/no password supplied/smi                   ? "password"
       : $err =~ m/role ($RE{quoted}) does not exist/smi      ? "username:$1"
       : $err =~ m/no route to host/smi                       ? "network"
       : $err =~ m/Key ($RE{balanced}{-parens=>'()'})=/smi    ? "duplicate:$1"
       : $err =~ m/permission denied for relation/smi         ? "relforbid"
       : $err =~ m/could not connect to server/smi            ? "servererror"
       : $err =~ m/not connected/smi                          ? "notconn"
       :                                                       "unknown";

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    return ($type, $name);
}

sub key    { 'pg' }
sub name   { 'PostgreSQL' }
sub driver { 'DBD::Pg 2.0' }

sub get_info {
    my ($self, $table) = @_;

    die "The 'table' parameter is required for 'get_info'" unless $table;

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

    my $dbh = $self->dbh;

    $dbh->{ChopBlanks} = 1;    # trim CHAR fields

    my $flds_ref;
    try {
        my $sth = $dbh->prepare($sql);
        $sth->execute;
        $flds_ref = $sth->fetchall_hashref('name');
    }
    catch {
        $self->log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    # Pg has different names for the columns type than Firebird, so we
    # have to map (somehow) the type names to the corresponding plugin
    # method names.
    # TODO!
    my $flds_type = {};
    foreach my $field ( keys %{$flds_ref} ) {
        $flds_type->{$field} = $flds_ref->{$field};
        $flds_type->{$field}{type} = 'varchar'
            if $flds_type->{$field}{type} eq 'character varying';
        $flds_type->{$field}{type} = 'char'
            if $flds_type->{$field}{type} eq 'character';
    }

    return $flds_type;
}

sub get_columns {
    my ($self, $table) = @_;

    die "The 'table' parameter is required for 'get_columns'" unless $table;

    my $sql = qq( SELECT column_name AS name
               FROM information_schema.columns
               WHERE table_name = '$table'
               ORDER BY ordinal_position;
    );

    my $dbh = $self->dbh;

    $dbh->{ChopBlanks} = 1;    # trim CHAR fields

    my $column_list;
    try {
        $column_list = $dbh->selectcol_arrayref($sql);
    }
    catch {
        $self->log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $column_list;
}

sub table_exists {
    my ( $self, $table ) = @_;

    die "The 'table' parameter is required for 'table_exists'" unless $table;

    my $sql = qq( SELECT COUNT(table_name)
                FROM information_schema.tables
                WHERE table_type = 'BASE TABLE'
                    AND table_schema NOT IN
                    ('pg_catalog', 'information_schema')
                    AND table_name = '$table';
    );

    my $val_ret;
    try {
        ($val_ret) = $self->dbh->selectrow_array($sql);
    }
    catch {
        $self->log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $val_ret;
}

sub table_list {
    my $self = shift;

    my $sql = q{ SELECT table_name
                      FROM information_schema.tables
                      WHERE table_type = 'BASE TABLE'
                        AND table_schema NOT IN
                            ('pg_catalog', 'information_schema');
    };

    my $dbh = $self->dbh;
    $dbh->{AutoCommit} = 1;    # disable transactions
    $dbh->{RaiseError} = 0;

    my $table_list;
    try {
        $table_list = $dbh->selectcol_arrayref($sql);
    }
    catch {
        $self->log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $table_list;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

Tpda3::Engine::pg - Tpda3Dev PostgreSQL engine

=head1 Synopsis

  my $engine = Tpda3::Engine->load( engine => 'pg' );

=head1 Description

Tpda3::Engine::pg provides the Pg database engine
for Tpda3Dev.  It supports Pg X.X and higher XXX ???.

=head1 Interface

=head2 Instance Methods

=head3 C<parse_error>

Parse and categorize the database error strings.

=head3 C<get_info>

Return a table info hash reference data structure.

=head3 C<table_exists>

Return true if the table provided as parameter exists in the database.

=head1 Author

David E. Wheeler <david@justatheory.com>

Ștefan Suciu <stefan@s2i2.ro>

=head1 License

Copyright (c) 2012-2014 iovation Inc.

Copyright (c) 2014-2015 Ștefan Suciu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
