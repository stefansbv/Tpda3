package Tpda3::Tk::Validation;

use strict;
use warnings;

=head1 NAME

Tpda3::Tk::Validation - Validation functions for data in Entry widgets
and Tablematrix cells.

=head1 VERSION

Version 0.84

=cut

our $VERSION = 0.84;

=head1 SYNOPSIS

    require Tpda3::Tk::Validation;

    my $validation
        = Tpda3::Tk::Validation->new( $self->{scrcfg}, $self->{view} );

    # In 'run_screen' method of a screen module:

    my $efieldname = $frame->Entry(
        -validate => 'key',
        -vcmd     => sub {
            $validation->validate_entry( 'fieldname', @_ );
        },
    );

    # For TableMatrix widgets:

    my $xtable = $frm_t->Scrolled(
        'TableMatrix',
        ...
        -validate => 1,
        -vcmd     => sub { $validation->validate_table_cell('tm1',@_) },
    );

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my ( $class, $scrcfg, $view ) = @_;

    my $self = {};

    $self->{procs} = {
        alpha        => \&alpha,
        alphanum     => \&alphanum,
        alphanumplus => \&alphanumplus,
        integer      => \&integer,
        numeric      => \&numeric,
        anychar      => \&anychar,
        email        => \&email,
        data         => \&data,
    };

    bless $self, $class;

    $self->{_scf} = $scrcfg;
    $self->{view} = $view;

    return $self;
}

=head2 init_cfgdata

Prepare configuration data for the I<column_name_from_idx> sub.  Data
is a hashref with column names as keys and column index as values.

=cut

sub init_cfgdata {
    my ( $self, $tm_ds ) = @_;

    my $table_cfg = $self->{_scf}->deptable($tm_ds, 'columns');
    my $cols      = Tpda3::Utils->sort_hash_by_id($table_cfg);
    my %cols      = map { $_ => $cols->[$_] } 0 .. $#{$cols};

    $self->{$tm_ds} = \%cols;

    return;
}

=head2 column_name_from_idx

Return column name for a table configuration when knowing its index
from the TableMatrix widget.

=cut

sub column_name_from_idx {
    my ( $self, $tm_ds, $col_idx ) = @_;

    return $self->{$tm_ds}{$col_idx};
}

=head2 maintable_attribs

Return column attributes for I<type>, I<valid_width> and I<place>,
from the screen configuration, for the main table.

=cut

sub maintable_attribs {
    my ( $self, $column ) = @_;

    my $table_cfg = $self->{_scf}->maintable('columns', $column);

    return @{$table_cfg}{qw(datatype valid_width numscale)};    # hash slice
}

=head2 deptable_attribs

Return column attributes for I<type>, I<valid_width> and I<place>,
from the screen configuration, for the dependent table(s).

=cut

sub deptable_attribs {
    my ( $self, $tm_ds, $column ) = @_;

    my $table_cfg = $self->{_scf}->deptable($tm_ds, 'columns', $column);

    return @{$table_cfg}{qw(datatype valid_width numscale)};    # hash slice
}

=head2 validate_entry

Validation for Tk::Entry widgets.

TODO: Change I<proc> to I<anychar> when in find mode, to allow
searching for 'NULL' string to be entered. This would be than be
interpreted as a 'column IS NULL' SQL WHERE clause.

=cut

sub validate_entry {
    my ( $self, $column, $p1 ) = @_;

    my ( $type, $valid_width, $numscale ) = $self->maintable_attribs($column);

    return $self->validate( $type, $p1, $valid_width, $numscale, $column );
}

=head2 validate_table_cell

Entry validation for tables.

Get I<type>, I<valid_width> and I<numscale> from the table's
configuration.

=cut

sub validate_table_cell {
    my ( $self, $tm_ds, $row, $col, $old, $new, $cidx ) = @_;

    my $column = $self->column_name_from_idx( $tm_ds, $col );

    my ( $type, $valid_width, $numscale )
        = $self->deptable_attribs( $tm_ds, $column );

    return $self->validate( $type, $new, $valid_width, $numscale, $column );
}

=head2 validate

Validate sub calls the appropriate function for data validation.

=cut

sub validate {
    my ( $self, $proc, $p1, $maxlen, $numscale, $column ) = @_;

    if ( !$proc ) {
        print "EE: Config error for '$column', no proc for validation!\n";
        return;
    }

    my $retval;
    if ( exists $self->{procs}{$proc} ) {
        $retval = $self->{procs}{$proc}->( $self, $p1, $maxlen, $numscale );
    }
    else {
        print "WW: Validation for '$proc' not yet implemented!";
        $retval = 1;
    }

    return $retval;
}

=head2 alpha

Function to validate strings containing only alphabetical characters.

=cut

sub alpha {
    my ( $self, $myvar, $maxlen ) = @_;

    my $pattern = qr/^\p{IsAlpha}{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear messages
        return 1;
    }
    else {
        $self->{view}->set_status( "alpha:$maxlen", 'ms' );
        return 0;
    }
}

=head2 alphanum

Function to validate strings containing only alphabetical and digit
characters.

=cut

sub alphanum {
    my ( $self, $myvar, $maxlen ) = @_;

    my $pattern = qr/^[\p{IsAlnum} +-]{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear messages
        return 1;
    }
    else {
        $self->{view}->set_status( "alphanum:$maxlen", 'ms' );
        return 0;
    }
}

=head2 alphanumplus

Function to validate strings containing only alphabetical, digit and
some commonly used symbol characters.

=cut

sub alphanumplus {
    my ( $self, $myvar, $maxlen ) = @_;

    my $pattern = qr/^[\p{IsAlnum}\p{IsP} %&@,.+-]{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear messages
        return 1;
    }
    else {
        $self->{view}->set_status( "alphanum+:$maxlen", 'ms' );
        return 0;
    }
}

=head2 integer

Function to validate strings containing only digit characters as
integers.

=cut

sub integer {
    my ( $self, $myvar, $maxlen ) = @_;

    my $pattern = qr/^[+-]?\p{IsDigit}{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear messages
        return 1;
    }
    else {
        $self->{view}->set_status( "integer:$maxlen", 'ms' );
        return 0;
    }
}

=head2 numeric

Function to validate strings containing only digit and dot characters
for decimal numbers.

TODO: Allow comma as decimal separator?

=cut

sub numeric {
    my ( $self, $myvar, $maxlen, $numscale ) = @_;

    $numscale = 0 unless ( defined $numscale );

    my $pattern = sprintf "\^\-?[0-9]{0,%d}(\\.[0-9]{0,%d})?\$",
        $maxlen - $numscale - 1, $numscale;

# TODO:
# my $pattern =
#     qr/^\-?\p{IsDigit}{0,$maxlen -$numscale -1}(\.\p{IsDigit}{0,$numscale})?$/x;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear messages
        return 1;
    }
    else {
        $self->{view}->set_status( "numeric:$maxlen", 'ms' );
        return 0;
    }
}

=head2 anychar

Function to validate strings containing only printable character.

=cut

sub anychar {
    my ( $self, $myvar, $maxlen ) = @_;

    my $pattern = qr/^\p{IsPrint}{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear messages
        return 1;
    }
    else {
        $self->{view}->set_status( "anychar:$maxlen", 'ms' );
        return 0;
    }
}

=head2 email

Function to validate characters allowed in e-mail addresses.

Better use the L<Email::Valid> module!

=cut

sub email {
    my ( $self, $myvar, $maxlen ) = @_;

    my $pattern = qr/^[\p{IsAlnum}\p{IsP} %&@,.+-]{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear messages
        return 1;
    }
    else {
        $self->{view}->set_status( "email:$maxlen", 'ms' );
        return 0;
    }
}

=head2 date

Function to validate date strings, (only in I<dd.mm.yyyy> format).

=cut

sub date {
    my ( $self, $myvar, $maxlen ) = @_;

    my $pattern = sprintf "\^[0-9]{2}\.[0-9]{2}\.[0-9]{4}\$", $maxlen;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear messages
        return 1;
    }
    else {
        $self->{view}->set_status( "date:$maxlen", 'ms' );
        return 0;
    }
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Tk::Validation

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Suciu.

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

1;    # End of Tpda3::Tk::Validation
