package Tpda3::Engine::sqlite;

# ABSTRACT: The SQLite engine

use 5.010001;
use Moose;
use Locale::TextDomain 1.20 qw(Tpda3);
use Tpda3::X qw(hurl);
use Try::Tiny;
use Regexp::Common;
use namespace::autoclean;

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
            sqlite_unicode   => 1,
            FetchHashKeyName => 'NAME_lc',
            HandleError      => sub {
                my ($err, $dbh) = @_;
                my ($type, $name) = $self->parse_error($err);
                my $message = $self->get_message($type);
                hurl sqlite => __x( $message, name => $name );
            },
            Callbacks         => {
                connected => sub {
                    my $dbh = shift;
                    $dbh->do('PRAGMA foreign_keys = ON');
                    return;
                },
            },
        });
    }
);

sub parse_error {
    my ($self, $err) = @_;

    # my $log = get_logger();
    # $log->error("EE: $err");

    my $message_type =
         $err eq q{}                                        ? "nomessage"
       : $err =~ m/prepare failed: no such table: (\w+)/smi ? "relnotfound:$1"
       : $err =~ m/prepare failed: near ($RE{quoted}):/smi  ? "notsuported:$1"
       : $err =~ m/not connected/smi                        ? "notconn"
       : $err =~ m/(.*) may not be NULL/smi                 ? "errnull:$1"
       :                                                     "unknown";

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    return ($type, $name);
}

sub key    { 'sqlite' }
sub name   { 'SQLite' }
sub driver { 'DBD::SQLite' }

sub get_info {
    my ( $self, $table, $key_field ) = @_;

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

sub table_exists {
    my ( $self, $table ) = @_;

    my $log = get_logger();
    $log->info("Checking if $table table exists");

    my $sql = qq( SELECT COUNT(name)
                FROM sqlite_master
                WHERE type = 'table'
                    AND name = '$table';
    );

    $log->trace("SQL= $sql");

    my $dbh = $self->dbh;
    my $val_ret;
    try {
        ($val_ret) = $dbh->selectrow_array($sql);
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $val_ret;
}

sub table_keys {
    my ( $self, $table ) = @_;

    my $dbh = $self->dbh;
    my @names = $dbh->primary_key(undef, undef, $table);

    return \@names;
}

sub table_list {
    my $self = shift;

    my $log = get_logger();

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
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $table_list;
}

sub get_testdb_filename {
    my $dbname = shift;
    return catfile(File::HomeDir->my_data, "$dbname.db");
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
