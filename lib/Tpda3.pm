package Tpda3;

use strict;
use warnings;

use 5.008005;

use Log::Log4perl qw(get_logger);

use Tpda3::Tk::Controller;

=head1 NAME

Tpda3 - The third incarnation of Tpda!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Tpda3;

    my $foo = Tpda3->new();
    ...

=head1 METHODS


=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $args ) = @_;

    my $self = {};

    bless $self, $class;

    $self->_init($args);

    return $self;
}

=head2 _init

Initialize the configurations module and create the PerlTk application
instance.

=cut

sub _init {
    my ( $self, $args ) = @_;

    Tpda3::Config->instance($args);

    $self->{gui} = Tpda3::Tk::Controller->new();

    $self->{gui}->start();

    return;
}

=head2 run

Execute the application

=cut

sub run {
    my $self = shift;

    $self->{gui}->MainLoop;

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users.sourceforge.net> >>

=head1 BUGS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3

You can also look for information at:

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1;    # End of Tpda3
