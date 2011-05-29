package Tpda3::Tk::Validation;

use strict;
use warnings;

=head1 NAME

Tpda3::Tk::Validation - The great new Tpda3::Tk::Validation!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Tpda3::Tk::Validation;

    my $validation = Tpda3::Tk::Validation->new($scr_cfg_ref);

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
        -validate       => 1,
        -vcmd           => sub { $validation->validate_table_cell(@_) },
    );

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my ($class, $scrcfg) = @_;

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

    $self->{_cfg} = $scrcfg;

    # Prepare screen configuration data for tables
    $self->_init_cfgdata('deptable');

    return $self;
}

=head2 _init_cfg_data

Prepare configuration data for the I<column_name_from_idx> sub.  Data
is a hashref with column names as keys and column index as values.

=cut

sub _init_cfgdata {
    my ($self, $table) = @_;

    my $table_cfg = $self->{_cfg}{$table}{columns};
    my $cols      = Tpda3::Utils->sort_hash_by_id($table_cfg);
    my %cols      = map { $_ => $cols->[$_] } 0 .. $#{$cols};

    $self->{$table} = \%cols;

    return;
}

=head2 column_name_from_idx

Return column name for a table configuration when knowing its index
from the TableMatrix widget.

=cut

sub column_name_from_idx {
    my ($self, $table, $col_idx) = @_;

    return $self->{$table}{$col_idx};
}

=head2 column_attribs

Return column attributes for I<type>, I<width> and I<place>, from the
screen configuration, for the main table.

=cut

sub column_attribs {
    my ($self, $table, $column) = @_;

    my $table_cfg = $self->{_cfg}{$table}{columns}{$column};

    return @{$table_cfg}{ qw(type width places) }; # hash slice
}

=head2 validate_entry

Validation for Tk::Entry widgets.

TODO: Change I<proc> to I<anychar> when in find mode, to allow
searching for 'NULL' string to be entered. This would be than be
interpreted as a 'column IS NULL' SQL WHERE clause.

=cut

sub validate_entry {
    my ( $self, $column, $p1 ) = @_;

    my ($type, $width, $places) = $self->column_attribs('maintable', $column);

    return $self->validate( $type, $p1, $width, $places );
}

=head2 validate_table

Entry validation for tables.

Get I<type>, I<width> and I<places> from the table's configuration.

=cut

sub validate_table_cell {
    my ($self, $row, $col, $old, $new, $cidx) = @_;

    my $column = $self->column_name_from_idx( 'deptable', $col );

    my ($type, $width, $places) = $self->column_attribs('deptable', $column);

    return $self->validate( $type, $new, $width, $places );
}

=head2 validate

Validate.

=cut

sub validate {
    my ( $self, $proc, $p1, $maxlen, $places ) = @_;

    my $retval;
    if ( exists $self->{procs}{$proc} ) {
        $retval = $self->{procs}{$proc}->( $self, $p1, $maxlen, $places );
    }
    else {
        print "WW: Validation for '$proc' not yet implemented!";
        $retval = 1;
    }

    return $retval;
}

sub alpha {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = qr/^\p{IsAlpha}{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"alpha:$maxlen", "red");
        return 0;
    }
}

sub alphanum {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = qr/^[\p{IsAlnum} +-]{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"alphanum:$maxlen", "red");
        return 0;
    }
}

sub alphanumplus {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = qr/^[\p{IsAlnum}\p{IsP} %&@,.+-]{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"alphanum+:$maxlen", "red");
        return 0;
    }
}

sub integer {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = qr/^\p{IsDigit}{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"digit:$maxlen", "red");
        return 0;
    }
}

sub numeric {
    my ($self, $myvar, $maxlen, $places) = @_;

    $places = 0 unless ( defined $places );

    my $pattern = sprintf "\^\-?[0-9]{0,%d}(\\.[0-9]{0,%d})?\$",
        $maxlen - $places - 1, $places;

    # my $pattern =
    #   qr/^\-?\p{IsDigit}{0,$maxlen -$places -1}(\.\p{IsDigit}{0,$places})?$/x;


    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"digit:$maxlen:$places", "red");
        return 0;
    }
}

sub anychar {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = qr/^\p{IsPrint}{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
#        $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
#        $self->{tpda}{gui}->refresh_sb('ll',"anychar:$maxlen", "red");
        return 0;
    }
}

sub email {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = qr/^[\p{IsAlnum}\p{IsP} %&@,.+-]{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"alphanum+:$maxlen", "red");
        return 0;
    }
}

sub data {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = sprintf "\^[0-9]{2}\.[0-9]{2}\.[0-9]{4}\$", $maxlen;

    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"date:dmy|mdy", "red");
        return 0;
    }
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Tk::Validation

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

1; # End of Tpda3::Tk::Validation
