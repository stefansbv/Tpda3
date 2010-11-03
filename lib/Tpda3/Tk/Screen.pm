package Tpda3::Tk::Screen;

use strict;
use warnings;

=head1 NAME

Tpda3::Tk::Screen - Tpda Screen base class.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my $type = shift;

    return bless {}, $type;
}

=head2 run_screen

The screen layout

=cut

sub run_screen {

    my ( $self, $inreg_p ) = @_;

    print 'run_screen not implemented in ', __PACKAGE__, "\n";

    return;
}

=head2 get_controls

Get a data structure containing references to the widgets.

=cut

sub get_controls {
    my $self = shift;

    print "'get_controls' not implemented.\n"
        unless exists $self->{controls}
            and scalar %{ $self->{controls} };

    return $self->{controls};
}

=head2 get_bgcolor

Return the background color of the main window.

Must be setup like this in run_screen method of every screen

 my $gui     = $inreg_p->toplevel;
 $self->{bg} = $gui->cget('-background');

=cut

sub get_bgcolor {
    my $self = shift;

    return $self->{bg};
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

1; # End of Tpda3::Tk::Screen
