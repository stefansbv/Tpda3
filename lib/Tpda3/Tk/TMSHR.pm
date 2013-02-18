package Tpda3::Tk::TMSHR;

use strict;
use warnings;
use utf8;
use Carp;

use Tpda3::Utils;

use Tk;
use base qw{Tk::Derived Tk::TableMatrix::SpreadsheetHideRows};

Tk::Widget->Construct('TMSHR');

=head1 NAME

Tpda3::Tk::TMSHR - Create a table matrix SpreadsheetHideRows widget.

=head1 VERSION

Version 0.64

=cut

our $VERSION = 0.64;

=head1 SYNOPSIS

    use Tpda3::Tk::TMSHR;

    my ($xtvar, $expand_data) = ( {}, {} );
    my $xtable = $frame->Scrolled(
        'TMSHR',
        -rows           => 6,
        -cols           => 1,
        -width          => -1,
        -height         => -1,
        -ipadx          => 3,
        -titlerows      => 1,
        -variable       => $xtvar,
        -selectmode     => 'single',
        -colstretchmode => 'unset',
        -resizeborders  => 'none',
        -bg             => 'white',
        -scrollbars     => 'osw',
        -expandData     => $expand_data,
    );
    $xtable->pack( -expand => 1, -fill => 'both' );

    $xtable->make_header($header);
    $xtable->fill_main($record_aoh, 'rowcountcolname');
    $xtable->fill_details($expanddata);

=head1 METHODS

=head2 ClassInit

Constructor method.

=cut

sub ClassInit {
    my ( $class, $mw ) = @_;

    $class->SUPER::ClassInit($mw);

    return;
}

=head2 Populate

Constructor method.

=cut

sub Populate {
    my ( $self, $args ) = @_;

    $self->SUPER::Populate($args);

    return $self;
}

=head2 make_header

Write header on row 0 of TableMatrix.

=cut

sub make_header {
    my ( $self, $args ) = @_;

    $self->{columns}    = $args->{columns};
    $self->{colstretch} = $args->{colstretch};

    $self->set_tags();

    return;
}

=head2 set_tags

Set tags for the table matrix.

=cut

sub set_tags {
    my $self = shift;

    my $cols = scalar keys %{ $self->{columns} };
    $cols++;                    # increase cols number with 1

    # Tags for the detail data:
    $self->tagConfigure(
        'detail',
        -bg     => 'darkseagreen2',
        -relief => 'sunken',
    );
    $self->tagConfigure(
        'detail2',
        -bg     => 'burlywood2',
        -relief => 'sunken',
    );
    $self->tagConfigure(
        'detail3',
        -bg     => 'lightyellow',
        -relief => 'sunken',
    );

    $self->tagConfigure(
        'expnd',
        -bg     => 'grey85',
        -relief => 'raised',
    );
    $self->tagCol( 'expnd', 0 );

    # Make enter do the same thing as return:
    $self->bind( '<KP_Enter>', $self->bind('<Return>') );

    if ($cols) {
        $self->configure( -cols => $cols );

        # $self->configure( -rows => 1 ); # Keep table dim in grid
    }
    $self->tagConfigure(
        'active',
        -bg     => 'lightyellow',
        -relief => 'sunken',
    );
    $self->tagConfigure(
        'title',
        -bg     => 'tan',
        -fg     => 'black',
        -relief => 'raised',
        -anchor => 'n',
    );
    $self->tagConfigure( 'find_left', -anchor => 'w', -bg => 'lightgreen' );
    $self->tagConfigure(
        'find_center',
        -anchor => 'n',
        -bg     => 'lightgreen',
    );
    $self->tagConfigure(
        'find_right',
        -anchor => 'e',
        -bg     => 'lightgreen',
    );
    $self->tagConfigure( 'ro_left',      -anchor => 'w', -bg => 'lightgrey' );
    $self->tagConfigure( 'ro_center',    -anchor => 'n', -bg => 'lightgrey' );
    $self->tagConfigure( 'ro_right',     -anchor => 'e', -bg => 'lightgrey' );
    $self->tagConfigure( 'enter_left',   -anchor => 'w', -bg => 'white' );
    $self->tagConfigure( 'enter_center', -anchor => 'n', -bg => 'white' );
    $self->tagConfigure(
        'enter_center_blue',
        -anchor => 'n',
        -bg     => 'lightblue',
    );
    $self->tagConfigure( 'enter_right', -anchor => 'e', -bg => 'white' );
    $self->tagConfigure( 'find_row', -bg => 'lightgreen' );

    # TableMatrix header, Set Name, Align, Width, and skip
    foreach my $field ( keys %{ $self->{columns} } ) {
        my $col = $self->{columns}{$field}{id};
        $self->tagCol( $self->{columns}{$field}{tag}, $col );
        $self->set( "0,$col", $self->{columns}{$field}{label} );

        # If colstretch = 'n' in screen config file, don't set width,
        # because of the -colstretchmode => 'unset' setting, col 'n'
        # will be of variable width
        next if $self->{colstretch} and $col == $self->{colstretch};

        my $width = $self->{columns}{$field}{displ_width};
        if ( $width and ( $width > 0 ) ) {
            $self->colWidth( $col, $width );
        }
    }

    $self->tagRow( 'title', 0 );
    if ( $self->tagExists('expnd') ) {

        # Change the tag priority
        $self->tagRaise( 'expnd', 'title' );
    }

    return;
}

=head2 clear_all

Clear all data from the Tk::TableMatrix widget, but preserve the header.

=cut

sub clear_all {
    my $self = shift;

    my $rows_no  = $self->cget( -rows );
    my $rows_idx = $rows_no - 1;
    my $r;

    $self->configure( -expandData => {} );   # clear detail data

    for my $row ( 1 .. $rows_idx ) {
        $self->deleteRows( $row, 1 );
    }

    return;
}

=head2 fill_main

Fill TableMatrix widget with data from the main table.

=cut

sub fill_main {
    my ( $self, $record_ref, $countcol ) = @_;

    my $xtvar = $self->cget( -variable );

    my $rows = 0;

    #- Scan DS and write to table

    foreach my $record ( @{$record_ref} ) {
        my $row = $record->{$countcol};
        foreach my $field ( keys %{ $record } ) {
            my $col = $self->{columns}{$field}{id};
            $xtvar->{"$row,$col"} = $record->{$field};
        }

        $rows = $row;
    }

    $self->configure( -rows => $rows + 1 );      # refreshing the table...

    return;
}

=head2 fill_details

Fill TableMatrix widget expand data from the dependent table(s).

=cut

sub fill_details {
    my ( $self, $record_ref ) = @_;

    $self->configure( -expandData => $record_ref );

    return;
}

=head2 get_main_data

Read main data from the widget.

=cut

sub get_main_data {
    my $self = shift;

    my $xtvar = $self->cget( -variable );

    my $rows_no  = $self->cget( -rows );
    my $cols_no  = $self->cget( -cols );
    my $rows_idx = $rows_no - 1;
    my $cols_idx = $cols_no - 1;

    my $fields_cfg = $self->{columns};
    my $cols_ref   = Tpda3::Utils->sort_hash_by_id($fields_cfg);

    # # Read table data and create an AoH
    my @tabledata;

    # The first row is the header
    for my $row ( 1 .. $rows_idx ) {

        my $rowdata = {};
        for my $col ( 0 .. $cols_idx ) {
            my $cell_value = $self->get("$row,$col");
            my $col_name   = $cols_ref->[$col-1];

            next unless $col_name;

            $rowdata->{$col_name} = $cell_value;
        }

        push @tabledata, $rowdata;
    }

    return (\@tabledata);
}

=head2 get_expdata

Get I<expandData> variable value;

=cut

sub get_expdata {
    my $self = shift;

    return $self->cget( -expandData );
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # end of Tpda3::Tk::TMSHR
