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
    };

    bless $self, $class;

    return $self;
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
    }
    else {
        $self->get_connection_observable->set( 0 ); # no ;)
        $self->_print('Connection error!');
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
    $self->_print('Disconnected.');

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

    $self->get_stdout_observable->set( "$msg" );

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

=head2 count_records

Count records in table

=cut

sub count_records {
    my ( $self, $data_hr ) = @_;

    my $table = $data_hr->{table};
    my $pkfld = $data_hr->{pkfld};

    my $where = {};
    while ( my ( $field, $attrib ) = each( %{ $data_hr->{where} } ) ) {
        if    ( $attrib->[1] eq 'contains' ) {
            $where->{ $field } = { -like => $self->quote4like($attrib->[0]) };
        }
        elsif ( $attrib->[1] eq 'allstr' ) {
            $where->{ $field } = $attrib->[0];
        }
        elsif ( $attrib->[1] eq 'none' ) {
            # just skip
        }
        else {
            warn "No find type defined for '$field'";
        }
    }

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select(
        $table, ["COUNT($pkfld)"], $where );

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
    my $pkfld = $data_hr->{pkfld};

    my $where = {};
    while ( my ( $field, $attrib ) = each( %{ $data_hr->{where} } ) ) {
        if    ( $attrib->[1] eq 'contains' ) {
            $where->{ $field } = { -like => $self->quote4like($attrib->[0]) };
        }
        elsif ( $attrib->[1] eq 'allstr' ) {
            $where->{ $field } = $attrib->[0];
        }
        elsif ( $attrib->[1] eq 'none' ) {
            # just skip
        }
        else {
            warn "No find type defined for '$field'";
        }
    }

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, $data_hr->{columns}, $where );

    # print "SQL : $stmt\n";
    # print "bind: @bind\n";

    my $args = { MaxRows => 100 }; # Limit search result to max 100 rows
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
    my $pkfld = $data_hr->{pkfld};

    my $where = {};
    while ( my ( $field, $attrib ) = each( %{ $data_hr->{where} } ) ) {
        if    ( $attrib->[1] eq 'contains' ) {
            $where->{ $field } = { -like => $self->quote4like($attrib->[0]) };
        }
        elsif ( $attrib->[1] eq 'allstr' ) {
            $where->{ $field } = $attrib->[0];
        }
        elsif ( $attrib->[1] eq 'none' ) {
            # just skip
        }
        else {
            warn "No find type defined for '$field'";
        }
    }

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, $data_hr->{columns}, $where );

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

=head2 quote4like

Surround text with '%' for SQL LIKE

=cut

sub quote4like {
    my ( $self, $text ) = @_;

    if ( $text =~ m{%}xm ) {
        return $text;
    }
    else {
        return qq{%$text%};
    }
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Tpda3::Model
