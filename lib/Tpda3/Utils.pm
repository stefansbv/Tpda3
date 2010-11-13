package Tpda3::Utils;

use strict;
use warnings;

=head1 NAME

Tpda3::Utils - The great new Tpda3::Utils!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Various utility functions used by all other modules.

    use Tpda3::Utils;

    my $foo = Tpda3::Utils->function_name();

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 METHODS

=head2 trim

Trim strings or arrays.

=cut

sub trim {
    my ($self, @text) = @_;

    for (@text) {
        s/^\s+//;
        s/\s+$//;
        s/\n$//mg; # m=multiline
    }

    return wantarray ? @text : "@text";
}

=head2 dateentry_parse_date

Parse date for Tk::DateEntry.

=cut

sub dateentry_parse_date {

    my ($self, $format, $date) = @_;

    my ($y, $m, $d);

    # Default date style format
    $format = 'iso' unless $format;

  SWITCH: for ($format) {
        /^$/ && warn "Error in 'dateentry_parse_date'\n";
        /german/i && do {
            ($d, $m, $y ) = ( $date =~ m{([0-9]{2})\.([0-9]{2})\.([0-9]{4})} );
            last SWITCH;
        };
        /iso/i && do {
            ($y, $m, $d ) = ( $date =~ m{([0-9]{4})\-([0-9]{2})\-([0-9]{2})} );
            last SWITCH;
        };
        /usa/i && do {
            ($m, $d, $y ) = ( $date =~ m{([0-9]{4})\/([0-9]{2})\/([0-9]{4})} );
            last SWITCH;
        };
        # DEFAULT
        warn "Wrong date format: $format\n";
    }

    return ($y, $m, $d);
}

=head2 dateentry_format_date

Format date for Tk::DateEntry.

=cut

sub dateentry_format_date {

    my ( $self, $format, $y, $m, $d ) = @_;

    my $date;

    # Default date style format
    $format = 'iso' unless $format;

  SWITCH: for ($format) {
        /^$/ && warn "Error in 'dateentry_format_date'\n";
        /german/i && do {
            $date = sprintf( "%02d.%02d.%4d", $d, $m, $y );
            last SWITCH;
        };
        /iso/i && do {
            $date = sprintf( "%4d-%02d-%02d", $y, $m, $d );
            last SWITCH;
        };
        /usa/i && do {
            $date = sprintf( "%02d/%02d/%4d", $m, $d, $y );
            last SWITCH;
        };
        # DEFAULT
        warn "Wrong date format: $format\n";
    }

    return $date;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Utils

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

1; # End of Tpda3::Utils
