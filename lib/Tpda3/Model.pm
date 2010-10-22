package Tpda3::Model;

use strict;
use warnings;

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
        _status    => Tpda3::Observable->new(),
        _editmode  => Tpda3::Observable->new(),
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
        $self->_status_msg('connectyes16','cn');
        $self->_print('Connected.');
    }
    else {
        $self->get_connection_observable->set( 0 ); # no ;)
        $self->_print('Connection error!');
    }
}

=head2 _disconnect

Disconnect from the database

=cut

sub _disconnect {
    my $self = shift;

    $self->{_dbh}->disconnect;
    $self->get_connection_observable->set( 0 );
    $self->_status_msg('connectno16','cn');
    $self->_print('Disconnected.');
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
    my ( $self, $line, $sb_id ) = @_;

    $sb_id = 0 if not defined $sb_id;

    print "$line\n";
    #$self->get_stdout_observable->set( "$line:$sb_id" );
}

=head2 get_status_observable

Get status observable

=cut

sub get_status_observable {
    my $self = shift;

    return $self->{_status};
}

=head2 _status_msg

Put a message on the status bar

=cut

sub _status_msg {
    my ( $self, $line, $sb_id ) = @_;

    $sb_id = 'll' if ! $sb_id;

    $self->get_status_observable->set( "$line:$sb_id" );
}

=head2 set_idlemode

Set idle mode

=cut

sub set_idlemode {
    my $self = shift;

    if ( $self->is_editmode ) {
        $self->get_editmode_observable->set(0);
    }
    if ( $self->is_editmode ) {
        $self->_print('edit', 1);
        $self->_status_msg('idle','lr');
    }
    else {
        $self->_status_msg('idle', 'lr');
    }
}

=head2 is_editmode

Return true if is edit mode

=cut

sub is_editmode {
    my $self = shift;

    return $self->get_editmode_observable->get;
}

=head2 get_editmode_observable

Return edit mode observable status

=cut

sub get_editmode_observable {
    my $self = shift;

    return $self->{_editmode};
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
