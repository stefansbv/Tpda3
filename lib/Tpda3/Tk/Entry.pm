package Tpda3::Tk::Entry;

use strict;
use warnings;

use Tk;
use base qw(Tk::Entry);

Construct Tk::Widget 'MEntry';

=head1 NAME

Tpda3::Tk::Entry - Subclass of Tk::Entry.

=head1 VERSION

Version 0.82

=cut

our $VERSION = 0.82;

=head1 SYNOPSIS

Create new binding for the L<< <KeyRelease> >> event type.

    use Tpda3::Tk::Entry;

    my $entry = Entry->new();

=head1 METHODS

=head2 ClassInit

=cut

sub ClassInit {
    my ( $class, $mw ) = @_;

    $class->SUPER::ClassInit($mw);

    $mw->bind( $class, '<KeyRelease>', sub { $mw->set_modified_record(); } );

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Tk::Entry

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Suciu.

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

1;    # End of Tpda3::Tk::Entry
