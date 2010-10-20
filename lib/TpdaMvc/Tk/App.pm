package TpdaMvc::Tk::App;

use strict;
use warnings;

use TpdaMvc::Tk::Controller;

=head1 NAME

TpdaMvc::Tk::App - Tk Perl application class

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use TpdaMvc::Tk::App;
    use TpdaMvc::Tk::Controller;

    $gui = TpdaMvc::Tk::App->create();

    $gui->MainLoop;


=head1 METHODS

=head2 create

Constructor method.

=cut

sub create {
    my $self = shift;

    my $controller = TpdaMvc::Tk::Controller->new();

    $controller->start();

    return $self;
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

1; # End of TpdaMvc::Tk::App
