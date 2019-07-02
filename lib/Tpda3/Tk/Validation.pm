package Tpda3::Tk::Validation;

# ABSTRACT: Validation functions for data in Entry widgets and TM cells

use strict;
use warnings;

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

sub scrcfg {
    my $self = shift;
    return $self->{_scf};
}

sub init_cfgdata {
    my ( $self, $tm_ds ) = @_;
    my $table_cfg = $self->scrcfg->deptable($tm_ds, 'columns');
    my $cols      = Tpda3::Utils->sort_hash_by_id($table_cfg);
    my %cols      = map { $_ => $cols->[$_] } 0 .. $#{$cols};
    $self->{$tm_ds} = \%cols;
    return;
}

sub tm_selector_col {
    my ($self, $tm_ds) = @_;
    return $self->scrcfg->deptable_selectorcol($tm_ds);
}

sub column_name_from_idx {
    my ( $self, $tm_ds, $col_idx ) = @_;
    return $self->{$tm_ds}{$col_idx};
}

sub maintable_attribs {
    my ( $self, $column ) = @_;
    my $table_cfg = $self->scrcfg->maintable('columns', $column);
    return @{$table_cfg}{qw(datatype valid_width numscale)};    # hash slice
}

sub deptable_attribs {
    my ( $self, $tm_ds, $column ) = @_;
    my $table_cfg = $self->scrcfg->deptable($tm_ds, 'columns', $column);
    return @{$table_cfg}{qw(datatype valid_width numscale)};    # hash slice
}

sub validate_entry {
    my ( $self, $column, $p1 ) = @_;
    my ( $type, $valid_width, $numscale ) = $self->maintable_attribs($column);
    return $self->validate( $type, $p1, $valid_width, $numscale, $column );
}

sub validate_table_cell {
    my ( $self, $tm_ds, $row, $col, $old, $new, $cidx ) = @_;
    my $sc = $self->tm_selector_col($tm_ds);
    return if defined $sc and $sc == $col;     # skip SC
    my $column = $self->column_name_from_idx( $tm_ds, $col );
    my ( $type, $valid_width, $numscale )
        = $self->deptable_attribs( $tm_ds, $column );
    return $self->validate( $type, $new, $valid_width, $numscale, $column );
}

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

sub alpha {
    my ( $self, $myvar, $maxlen ) = @_;
    my $pattern = qr/^\p{IsAlpha}{0,$maxlen}$/;
    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear message
        return 1;
    }
    else {
        $self->{view}->set_status( "alpha:$maxlen", 'ms' );
        return 0;
    }
}

sub alphanum {
    my ( $self, $myvar, $maxlen ) = @_;

    my $pattern = qr/^[\p{IsAlnum} +-]{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear message
        return 1;
    }
    else {
        $self->{view}->set_status( "alphanum:$maxlen", 'ms' );
        return 0;
    }
}

sub alphanumplus {
    my ( $self, $myvar, $maxlen ) = @_;

    my $pattern = qr/^[\p{IsAlnum}\p{IsP} %&@,.+-]{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear message
        return 1;
    }
    else {
        $self->{view}->set_status( "alphanum+:$maxlen", 'ms' );
        return 0;
    }
}

sub integer {
    my ( $self, $myvar, $maxlen ) = @_;

    my $pattern = qr/^[+-]?\p{IsDigit}{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear message
        return 1;
    }
    else {
        $self->{view}->set_status( "integer:$maxlen", 'ms' );
        return 0;
    }
}

sub numeric {
    my ( $self, $myvar, $maxlen, $numscale ) = @_;

    $numscale = 0 unless ( defined $numscale );

    my $pattern = sprintf "\^\-?[0-9]{0,%d}(\\.[0-9]{0,%d})?\$",
        $maxlen - $numscale - 1, $numscale;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear message
        return 1;
    }
    else {
        $self->{view}->set_status( "numeric:$maxlen", 'ms' );
        return 0;
    }
}

sub anychar {
    my ( $self, $myvar, $maxlen ) = @_;

    my $pattern = qr/^\p{IsPrint}{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear message
        return 1;
    }
    else {
        $self->{view}->set_status( "anychar:$maxlen", 'ms' );
        return 0;
    }
}

sub email {
    my ( $self, $myvar, $maxlen ) = @_;

    my $pattern = qr/^[\p{IsAlnum}\p{IsP} %&@,.+-]{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear message
        return 1;
    }
    else {
        $self->{view}->set_status( "email:$maxlen", 'ms' );
        return 0;
    }
}

sub date {
    my ( $self, $myvar, $maxlen ) = @_;
    if ( length $myvar > $maxlen ) {
        $self->{view}->set_status( "date:invalid", 'ms' );
        return 0;
    }
    my $pattern = qr/^[0-9]{2}\.[0-9]{2}\.[0-9]{4}$/;
    if ( $myvar =~ m/$pattern/ ) {
        $self->{view}->set_status( '', 'ms' );    # clear message
        return 1;
    }
    else {
        $self->{view}->set_status( 'date:invalid', 'ms' );
        return 0;
    }
}

1;

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

=head2 new

Constructor method.

=head2 init_cfgdata

Prepare configuration data for the I<column_name_from_idx> sub.  Data
is a hashref with column names as keys and column index as values.

=head2 column_name_from_idx

Return column name for a table configuration when knowing its index
from the TableMatrix widget.

=head2 maintable_attribs

Return column attributes for I<type>, I<valid_width> and I<place>,
from the screen configuration, for the main table.

=head2 deptable_attribs

Return column attributes for I<type>, I<valid_width> and I<place>,
from the screen configuration, for the dependent table(s).

=head2 validate_entry

Validation for Tk::Entry widgets.

TODO: Change I<proc> to I<anychar> when in find mode, to allow
searching for 'NULL' string to be entered. This would be than be
interpreted as a 'column IS NULL' SQL WHERE clause.

=head2 validate_table_cell

Entry validation for tables.

Get I<type>, I<valid_width> and I<numscale> from the table's
configuration.

=head2 validate

Validate sub calls the appropriate function for data validation.

=head2 alpha

Function to validate strings containing only alphabetical characters.

=head2 alphanum

Function to validate strings containing only alphabetical and digit
characters.

=head2 alphanumplus

Function to validate strings containing only alphabetical, digit and
some commonly used symbol characters.

=head2 integer

Function to validate strings containing only digit characters as
integers.

=head2 numeric

Function to validate strings containing only digit and dot characters
for decimal numbers.

=head2 anychar

Function to validate strings containing only printable character.

=head2 email

Function to validate characters allowed in e-mail addresses.

Better use the L<Email::Valid> module!

=head2 date

Function to validate date strings, (only in I<dd.mm.yyyy> format).

=cut
