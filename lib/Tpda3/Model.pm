package Tpda3::Model;

use strict;
use warnings;

use Data::Dumper;
use Carp;

use Try::Tiny;
use SQL::Abstract;

use Tpda3::Config;
use Tpda3::Observable;
use Tpda3::Db;
use Tpda3::Codings;
use Tpda3::Utils;

=head1 NAME

Tpda3::Model - The Model

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use Tpda3::Model;

    my $model = Tpda3::Model->new();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {
        _connected => Tpda3::Observable->new(),
        _stdout    => Tpda3::Observable->new(),
        _appmode   => Tpda3::Observable->new(),
        _modified  => Tpda3::Observable->new(),
        _cfg       => Tpda3::Config->instance(),
    };

    bless $self, $class;

    return $self;
}

=head2 _cfg

Return config instance variable

=cut

sub _cfg {
    my $self = shift;

    return $self->{_cfg};
}

=head2 toggle_db_connect

Toggle database connection

=cut

sub toggle_db_connect {
    my $self = shift;

    if ( $self->is_connected ) {
        $self->_disconnect();
    }
    else {
        $self->_connect();
    }

    return $self;
}

=head2 _connect

Connect to the database

=cut

sub _connect {
    my $self = shift;

    # Connect to database
    $self->{_dbh} = Tpda3::Db->instance->dbh;

    # Is realy connected ?
    if ( ref( $self->{_dbh} ) =~ m{DBI} ) {
        $self->get_connection_observable->set( 1 ); # yes
        $self->_print('Connected');
        # print "Connected\n";
    }
    else {
        $self->get_connection_observable->set( 0 ); # no ;)
        $self->_print('Connection error!');
        print "Connection error!\n";
    }

    return;
}

=head2 _disconnect

Disconnect from the database

=cut

sub _disconnect {
    my $self = shift;

    $self->{_dbh}->disconnect;
    $self->get_connection_observable->set( 0 );
    $self->_print('Disconnected');

    return;
}

=head2 is_connected

Return true if connected

=cut

sub is_connected {
    my $self = shift;

    # TODO: What if the connection is lost?

    return $self->get_connection_observable->get;
}

=head2 get_connection_observable

Get connection observable status

=cut

sub get_connection_observable {
    my $self = shift;

    return $self->{_connected};
}

=head2 get_stdout_observable

Get STDOUT observable status

=cut

sub get_stdout_observable {
    my $self = shift;

    return $self->{_stdout};
}

=head2 _print

Put a message on a text controll

=cut

sub _print {
    my ( $self, $msg ) = @_;

    $self->get_stdout_observable->set($msg);

    return;
}

=head2 set_mode

Set mode

=cut

sub set_mode {
    my ($self, $mode) = @_;

    $self->get_appmode_observable->set($mode);

    return;
}

=head2 is_mode

Return true if is mode

=cut

sub is_mode {
    my ($self, $mode) = @_;

    if ($self->get_appmode_observable->get eq $mode) {
        return 1;
    }
    else {
        return;
    }
}

=head2 get_appmode_observable

Return add mode observable status

=cut

sub get_appmode_observable {
    my $self = shift;

    return $self->{_appmode};
}

=head2 get_appmode

Return application mode

=cut

sub get_appmode {
    my $self = shift;

    return $self->get_appmode_observable->get;
}

=head2 set_modified

Set modified

=cut

sub set_modified {
    my ($self, $state) = @_;

    $self->get_modified_observable->set($state);

    return;
}

=head2 get_modified_observable

Return add mode observable status

=cut

sub get_modified_observable {
    my $self = shift;

    return $self->{_modified};
}

=head2 is_modified

Return true if record is modified

=cut

sub is_modified {
    my $self = shift;

    if ($self->get_modified_observable->get) {
        return 1;
    }
    else {
        return;
    }
}

=head2 query_records_count

Count records in table

=cut

sub query_records_count {
    my ( $self, $data_hr ) = @_;

    my $table = $data_hr->{table};
    my $pkcol = $data_hr->{pkcol};

    my $where = $self->build_where($data_hr);

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select(
        $table, ["COUNT($pkcol)"], $where );

    # print "SQL : $stmt\n";
    # print "bind: @bind\n";

    my $record_count;
    try {
        my $sth = $self->{_dbh}->prepare($stmt);

        $sth->execute(@bind);

        ($record_count) = $sth->fetchrow_array();
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    $self->_print("$record_count records found") ;

    return;
}

=head2 query_records_find

Count records in table.  Here we need the contents of the screen to
build an sql where clause and also the column names from the
I<columns> configuration.

=cut

sub query_records_find {
    my ( $self, $data_hr ) = @_;

    my $table = $data_hr->{table};
    my $pkcol = $data_hr->{pkcol};

    my $where = $self->build_where($data_hr);

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $data_hr->{columns}, $where );

    # print "SQL : $stmt\n";
    # print "bind: @bind\n";

    my $search_limit = $self->_cfg->application->{limits}{search} || 100;
    my $args = { MaxRows => $search_limit }; # limit search result
    my $ary_ref;
    try {
        $ary_ref = $self->{_dbh}->selectall_arrayref( $stmt, $args, @bind );
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    my $record_count = scalar @{$ary_ref};
    $self->_print("$record_count records listed") ;

    return $ary_ref;
}

=head2 query_record

Return a record as hash reference

=cut

sub query_record {
    my ( $self, $data_hr ) = @_;

    my $table = $data_hr->{table};
    my $pkcol = $data_hr->{pkcol};

    my $where = $self->build_where($data_hr);

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, undef, $where );

    # print "SQL : $stmt\n";
    # print "bind: @bind\n";

    my $hash_ref;
    try {
        $hash_ref = $self->{_dbh}->selectrow_hashref( $stmt, undef, @bind );
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    return $hash_ref;
}

=head2 query_record_batch

Query records.

=cut

sub query_record_batch {
    my ( $self, $data_hr ) = @_;

    my $table  = $data_hr->{table};
    my $pkcol  = $data_hr->{pkcol};
    my $order  = $data_hr->{fkcol};
    my $fields = $data_hr->{cols};

    my $where = $self->build_where($data_hr);

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $fields, $where, $order );

    # print "SQL : $stmt\    # print "bind: @bind\n";

    my @records;
    try {
        my $sth = $self->{_dbh}->prepare($stmt);
        $sth->execute(@bind);

        while ( my $record = $sth->fetchrow_hashref('NAME_lc') ) {
            push( @records, $record );
        }
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    return \@records;
}

=head2 query_dictionary

Query a dictionary table

=cut

sub query_dictionary {
    my ( $self, $data_hr ) = @_;

    my $table = $data_hr->{table};
    my $opt   = $data_hr->{options};
    my $order = $data_hr->{order};
    my $cols  = $data_hr->{columns};

    my $where = $self->build_where($data_hr, $opt);

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $cols, $where, $order );

    # print "SQL : $stmt\n";
    # print "bind: @bind\n";

    my $lookup_limit = $self->_cfg->application->{limits}{lookup} || 50;
    my $args = { MaxRows => $lookup_limit }; # limit search result
    my $ary_ref;
    try {
        $ary_ref = $self->{_dbh}->selectall_arrayref( $stmt, $args, @bind );
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    return $ary_ref;
}

=head2 build_where

Return a hash reference containing where clause attributes.  Table
columns (fields) used in the screen has a configuration named
I<findtype> used for choosing which form to use in the ...

Valid configuration options are:

=over

=item contains - the field value contains the search string

=item allstr   - the field value equals the search string

=item date     - special case for date type fields

=item none     - no search for this field

=back

Second parameter 'option' is passed to quote4like.

=cut

sub build_where {
    my ( $self, $data_hr, $opt ) = @_;

    my $where = {};

    while ( my ( $field, $attrib ) = each( %{ $data_hr->{where} } ) ) {
        my $find_type = $attrib->[1];

        unless ($find_type) {
            croak "Config error: unknown 'findtype' configured for '$field'";
        }

        if ( $find_type eq 'contains' ) {
            $where->{$field} =
                { -like => Tpda3::Utils->quote4like( $attrib->[0], $opt ) };
        }
        elsif ( $find_type eq 'allstr' ) {
            $where->{$field} = $attrib->[0];
        }
        elsif ( $find_type eq 'date' ) {
            $where->{$field} =
              Tpda3::Utils->process_date_string( $attrib->[0] );
        }
        elsif ( $find_type eq 'none' ) {

            # just skip
        }
    }

    return $where;
}

=head2 get_codes

Return the data structure used to fill the list of choices.

=cut

sub get_codes {
    my ($self, $field, $para) = @_;

    my $codings = Tpda3::Codings->new();
    my $codes   = $codings->get_coding_init($field, $para);

    return $codes;
}

=head2 table_record_save

Save screen data to a record in the DB.

=cut

sub table_record_update {
    my ( $self, $data_hr, $record ) = @_;

    my $table = $data_hr->{table};
    my $where = $self->build_where($data_hr);

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->update( $table, $record, $where );

    # print "SQL : $stmt\n";
    # print Dumper( \@bind);

    try {
        my $sth = $self->{_dbh}->prepare($stmt);
        $sth->execute(@bind);
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    return 1;
}

=head2 table_record_insert

Insert new record in the DB.

=cut

sub table_record_insert {
    my ( $self, $data_hr, $record ) = @_;

    my $table = $data_hr->{table};
    my $pkcol = $data_hr->{pkcol};

    my $sql = SQL::Abstract->new();

    # Postgres version 8.2 or greater: RETURNING
    # Firebird version 2.1 or greater: RETURNING ???

    my ( $stmt, @bind ) = $sql->insert( $table, $record, {returning => $pkcol} );

    # print "SQL : $stmt\n";
    # print Dumper( \@bind);

    my $pk_id;
    try {
        my $sth = $self->{_dbh}->prepare($stmt);
        $sth->execute(@bind);
        $pk_id = $sth->fetch()->[0];
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    return $pk_id;
}

=head2 table_record_insert_batch

Save records from Table widget into DB.

Prepares the statement for every record, not only once!

TODO: Experiment with the example code from the I<PERFORMANCE> section
      in SQL::Abstract manual.

=cut

sub table_record_insert_batch {
    my ( $self, $data_hr, $records ) = @_;

    my $table = $data_hr->{table};
    my $pkref = $data_hr->{pkcol};           # pk field name and value

    my $sql = SQL::Abstract->new();

    # AoH refs
    foreach my $row ( @{$records} ) {
        while ( my ( $id, $rec ) = each( %{$row} ) ) {

            # Add pk_col to record data (merge hash refs)
            @{$rec}{ keys %{$pkref} } = values %{$pkref};

            my ( $stmt, @bind ) = $sql->insert( $table, $rec );

            # print "SQL : $stmt\n";
            # print Dumper( \@bind);

            try {
                my $sth = $self->{_dbh}->prepare($stmt);
                $sth->execute(@bind);
            }
            catch {
                $self->_print("Database error!") ;
                croak("Transaction aborted: $_");
            };
        }
    }

    return;
}

sub table_record_delete_batch {
    my ( $self, $data_hr, $records ) = @_;

    my $table = $data_hr->{table};

    my $sql = SQL::Abstract->new();

    my $where = $self->build_where($data_hr);

    croak "Empty SQL WHERE in DELETE command!"
        unless ( %{$where} );                # safety net

    my ( $stmt, @bind ) = $sql->delete( $table, $where );

    # print "SQL : $stmt\n";
    # print Dumper( \@bind);

    try {
        my $sth = $self->{_dbh}->prepare($stmt);
        $sth->execute(@bind);
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Tpda3::Model
