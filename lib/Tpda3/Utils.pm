package Tpda3::Utils;

use strict;
use warnings;

=head1 NAME

Tpda3::Utils - Various utility functions

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

Various utility functions used by all other modules.

    use Tpda3::Utils;

    my $foo = Tpda3::Utils->function_name();

=head1 METHODS

=head2 transformations

Global hash reference !?

=cut

my $transformations = {
    datey   => \&year_month,
    dateym  => \&year_month,
    datemy  => \&year_month,
    dateiso => \&date_string,
    dateamb => \&date_string,
    nothing => \&do_error,
    error   => \&do_error,
};

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
        warn "Unknown date format: $format\n";
    }

    return $date;
}

=head2 sort_hash_by_id

Use ST to sort hash by value (Id), returns an array ref of the sorted
items.

=cut

sub sort_hash_by_id {
    my ($self, $attribs) = @_;

    #-- Sort by id
    #- Keep only key and id for sorting
    my %temp = map { $_ => $attribs->{$_}{id} } keys %{$attribs};

    #- Sort with  ST
    my @attribs = map { $_->[0] }
      sort { $a->[1] <=> $b->[1] }
      map { [ $_ => $temp{$_} ] }
      keys %temp;

    return \@attribs;
}

=head2 quote4like

Surround text with '%', by default, for SQL LIKE.  An optional second
parameter can be used for 'start with' or 'end with' sintax.

If option parameter is not 'C', 'S', or 'E', 'C' is assumed.

=cut

sub quote4like {
    my ( $self, $text, $option ) = @_;

    if ( $text =~ m{%}xm ) {
        return $text;
    }
    else {
        $option ||= q{C};    # default 'C'
        return qq{$text%} if $option eq 'S';    # (S)tart with
        return qq{%$text} if $option eq 'E';    # (E)nd with
        return qq{%$text%};                     # (C)ontains
    }
}

=head2 special_ops

SQL::Abstract special ops for EXTRACT (YEAR|MONTH FROM field) = word1.

Note: Not compatible with SQLite.

=cut

sub special_ops {
    my $self = shift;

    return [

        {
            regex   => qr/^extractyear$/i,
            handler => sub {
                my ( $self, $field, $op, $arg ) = @_;
                $arg = [$arg] if not ref $arg;
                my $label         = $self->_quote($field);
                my ($placeholder) = $self->_convert('?');
                my $sql = $self->_sqlcase('extract (year from')
                  . " $label) = $placeholder ";
                my @bind = $self->_bindtype( $field, @$arg );
                return ( $sql, @bind );
              }
        },
        {
            regex   => qr/^extractmonth$/i,
            handler => sub {
                my ( $self, $field, $op, $arg ) = @_;
                $arg = [$arg] if not ref $arg;
                my $label         = $self->_quote($field);
                my ($placeholder) = $self->_convert('?');
                my $sql           = $self->_sqlcase('extract (month from')
                  . " $label) = $placeholder ";
                my @bind = $self->_bindtype( $field, @$arg );
                return ( $sql, @bind );
              }
        },
    ];
}

=head2 process_date_string

Try to identify the input string as full date, year or month and year
and return a where clause.

=cut

sub process_date_string {
    my ($self, $search_input) = @_;

    my $dtype = $self->identify_date_string($search_input);
    my $where = $self->format_query($dtype);

    return $where;
}

=head2 identify_date_string

Identify format of the I<input> I<string> from a date type field and
return the matched pieces in a string as separate values where the
separator is the colon character.

=cut

sub identify_date_string {
    my ($self, $is) = @_;

    #                When date format is...                     Type is ...
    return $is eq q{}                                        ? 'nothing'
           : $is =~ m/^(\d{4})[\.\/-](\d{2})[\.\/-](\d{2})$/ ? "dateiso:$is"
           : $is =~ m/^(\d{2})[\.\/-](\d{2})[\.\/-](\d{4})$/ ? "dateamb:$is"
           : $is =~ m/^(\d{4})[\.\/-](\d{1,2})$/             ? "dateym:$1:$2"
           : $is =~ m/^(\d{1,2})[\.\/-](\d{4})$/             ? "datemy:$2:$1"
           : $is =~ m/^(\d{4})$/                             ? "datey:$1"
           :                                                    "dataerr:$is";
}

=head2 format_query

Execute the appropriate sub and return the where attributes Choices
are defined in the I<$transformations> hash.

=cut

sub format_query {
    my ( $self, $type ) = @_;

    my ( $directive, $year, $month ) = split /:/, $type, 3;

    my $where;
    if ( exists $transformations->{$directive} ) {
        $where = $transformations->{$directive}->( $year, $month );
    }
    else {
        warn "Unrecognized directive '$directive'";
    }

    return $where;
}

=head2 year_month

Case of string identified as year and/or month.

=cut

sub year_month {
    my ( $year, $month ) = @_;

    my $where = {};
    $where->{-extractyear}  = [$year]  if ($year);
    $where->{-extractmonth} = [$month] if ($month);

    return $where;
}

=head2 date_string

Case of string identified as full date string, regardless of the format.

=cut

sub date_string {
    my ($date) = @_;

    return $date;
}

=head2 do_error

Case of string not identified or empty.

=cut

sub do_error {
    my ($date) = @_;

    print "String not identified or empty!\n";

    return;
}

=head2 ins_underline_mark

Insert ampersand character for underline mark in menu.

=cut

sub ins_underline_mark {
    my ($self, $label, $position) = @_;

    substr($label, $position, 0) = '&';

    return $label;
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

Copyright 2010-2011 Stefan Suciu.

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
