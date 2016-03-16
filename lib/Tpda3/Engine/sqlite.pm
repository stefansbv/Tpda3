package Tpda3::Engine::sqlite;

# ABSTRACT: The SQLite engine

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(Tpda3);
use Try::Tiny;
use Regexp::Common;
use Path::Tiny;
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
        $self->alter_dsn;
        my $uri  = $self->uri;
        my $dsn  = $uri->dbi_dsn;
        $self->use_driver;
        $self->logger->debug("Connecting: $dsn");
        my $conn = DBIx::Connector->new($dsn, undef, undef, {
            $uri->query_params,
            PrintError       => 0,
            RaiseError       => 0,
            AutoCommit       => 1,
            sqlite_unicode   => 1,
            sqlite_use_immediate_transaction => 1,
            FetchHashKeyName => 'NAME_lc',
            HandleError      => sub { $self->handle_error(@_) },
            Callbacks        => {
                connected => sub {
                    my $dbh = shift;
                    $dbh->do('PRAGMA foreign_keys = ON');
                    return;
                },
            },
        });

        # Make sure we support this version.
        my @v = split /[.]/ => $conn->dbh->{sqlite_version};
        my $version = $conn->dbh->{sqlite_version};
        die
            "Tpda3 requires SQLite 3.7.11 or later; DBD::SQLite was built with $version"
            unless $v[0] > 3
            || ( $v[0] == 3
                 && ( $v[1] > 7 || ( $v[1] == 7 && $v[2] >= 11 ) ) );

        return $conn;
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
    my ($self, $err) = @_;

    $self->logger->error("DBErr: $err");

    my $message_name =
         $err eq q{}                                        ? "nomessage"
       : $err =~ m/prepare failed: no such table: (\w+)/smi ? "relnotfound:$1"
       : $err =~ m/prepare failed: near ($RE{quoted}):/smi  ? "notsuported:$1"
       : $err =~ m/not connected/smi                        ? "notconn"
       : $err =~ m/(.*) may not be NULL/smi                 ? "errnull:$1"
       :                                                     "unknown";

    my ( $name, $param ) = split /:/, $message_name, 2;
    $param = $param ? $param : '';

    return ($name, $param);
}

sub key    { 'sqlite' }
sub name   { 'SQLite' }
sub driver { 'DBD::SQLite' }

sub get_info {
    my ( $self, $table, $key_field ) = @_;

    die "Missing required arguments: table" unless $table;

    my $dbh = $self->dbh;

    $key_field ||= 'name';

    my $h_ref = $dbh ->selectall_hashref( "PRAGMA table_info($table)", 'cid' );

    my $flds_ref = {};
    foreach my $cid ( sort keys %{$h_ref} ) {
        my $name       = $h_ref->{$cid}{name};
        my $dflt_value = $h_ref->{$cid}{dflt_value};
        my $notnull    = $h_ref->{$cid}{notnull};
        # my $pk       = $h_ref->{$cid}{pk}; is part of PK ? index : undef
        my $data_type  = $h_ref->{$cid}{type};

        # Parse type;
        my ($type, $precision, $scale);
        if ( $data_type =~ m{
               (\w+)                           # data type
               (?:\((\d+)(?:,(\d+))?\))?       # optional (precision[,scale])
             }x
         ) {
            $type      = $1;
            $precision = $2;
            $scale     = $3;
        }

        my $info = {
            pos         => $cid,
            name        => $name,
            type        => $type,
            is_nullable => $notnull ? 0 : 1,
            defa        => $dflt_value,
            length      => $precision,
            prec        => $precision,
            scale       => $scale,
        };
        $flds_ref->{ $info->{$key_field} } = $info;
    }

    return $flds_ref;
}

sub get_columns {
    my ( $self, $table ) = @_;

    die "Missing required arguments: table" unless $table;

    my $dbh = $self->dbh;
    my $h_ref = $dbh ->selectall_hashref( "PRAGMA table_info($table)", 'cid' );
    my $column_list;
    foreach my $cid ( sort keys %{$h_ref} ) {
        push @{$column_list}, $h_ref->{$cid}{name};
    }
    return $column_list;
}

sub table_keys {
    my ( $self, $table, $foreign) = @_;

    die "Missing required arguments: table" unless $table;

    my $dbh = $self->dbh;
    if ($foreign) {
        my $sth = $dbh->foreign_key_info( undef, undef, undef, undef, undef,
            $foreign );
        my $info = $sth->fetchall_hashref('FKTABLE_NAME');
        return [ $info->{$foreign}{FKCOLUMN_NAME} ];
    }
    else {
        my @names = $dbh->primary_key(undef, undef, $table);
        return \@names;
    }
}

sub table_exists {
    my ( $self, $table ) = @_;

    die "Missing required arguments: table" unless $table;

    my $sql = qq( SELECT COUNT(name)
                FROM sqlite_master
                WHERE type = 'table'
                    AND name = '$table';
    );

    my $dbh = $self->dbh;
    my $val_ret;
    try {
        ($val_ret) = $dbh->selectrow_array($sql);
    }
    catch {
        $self->logger->error("Transaction aborted because $_")
            or print STDERR "$_\n";
    };
    return $val_ret;
}

sub table_list {
    my $self = shift;
    my $sql = qq( SELECT name
                FROM sqlite_master
                WHERE type = 'table';
    );
    my $dbh = $self->dbh;
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

sub alter_dsn {
    my $self   = shift;
    my $uri    = $self->uri;
    my $dbname = $uri->dbname;
    return if path($dbname)->is_absolute;
    my $dbfile = path( File::HomeDir->my_data, $dbname );
    $uri->dbname($dbfile);
    return;
}

sub has_feature_returning { 0 }

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Name

Tpda3::Engine::sqlite - Tpda3Dev SQLite engine

=head1 Synopsis

  my $engine = Tpda3::Engine->load( engine => 'sqlite' );

=head1 Description

Tpda3::Engine::sqlite provides the SQLite database engine
for Tpda3.

=head1 Interface

=head2 Instance Methods

=head3 C<parse_error>

Parse and categorize the database error strings.

=head3 C<get_info>

Return a table info hash reference data structure.

=head3 C<table_exists>

Return true if the table provided as parameter exists in the database.

=head3 C<alter_dsn>

Do nothing if the database is a full absolute path.  Alter the DSN
with a default path to the database name, as returned by the
C<my_data> method of the L<File::HomeDir> module.

In other words if the database name is <classicmodels.db>, the new DSN
will be something like C<dbi:SQLite:dbname=/home/user/.local/share/classicmodels.db>


=head1 Author

This module was written and is maintained by:

Ștefan Suciu <stefan@s2i2.ro>

It is based on code written by:

=over

=item David E. Wheeler <david@justatheory.com>

=back


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
