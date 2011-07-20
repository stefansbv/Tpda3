package Tpda3::Tk::TM;

use strict;
use warnings;

use Tk;
use base qw{Tk::TableMatrix};

=head1 NAME

Tpda3::Tk::TM - Create a table matrix widget.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Tk::TM;

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $self, $frame, $metadata ) = @_;

    my $xtvar1 = {};    # must init as hash reference!

    #- Create the scrollbars

    my $v_sb = $frame->Scrollbar();
    # my $h_sb = $frame->Scrollbar();

    $self = $self->SUPER::new(
        $frame,
        -rows           => 5,
        -cols           => 5,
        -width          => -1,
        -height         => -1,
        -ipadx          => 3,
        -titlerows      => 1,
        -validate       => 1,
        -variable       => $xtvar1,
        -selectmode     => 'single',
        -colstretchmode => 'unset',
        -resizeborders  => 'none',
        -colstretchmode => 'unset',
        -bg             => 'white',
        -yscrollcommand => [ 'set' => $v_sb ]
    );

    #-- Vertical scrollbar

    $v_sb->configure(
        -width   => 10,
        -orient  => 'v',
        -command => [ 'yview' => $self ],
    );

    $v_sb->pack( -side => 'right', -fill => 'y' );

    #-- Horizontal scrollbar

    #  $h_sb->configure(
    #     -width   => 10,
    #     -orient  => 'h',
    #     -command => [ 'xview' => $self ],
    # );
    # $h_sb->pack( -side => 'bottom', -fill => 'x' );

    $self->pack( -side => 'left', -fill => 'both' );

    $self->_init($metadata);

    return $self;
}

=head2 _init

Write header on row 0 of TableMatrix

=cut

sub _init {
    my ($self, $metadata, $strech, $selecol) = @_;

    # Set TableMatrix tags
    my $cols = scalar keys %{$metadata};

    $self->set_tablematrix_tags($cols, $metadata, 4, 0 );

    return;
}

=head2 set_tablematrix_tags

Set tags for the table matrix.

=cut

sub set_tablematrix_tags {
    my ($self, $cols, $tm_fields, $strech, $selecol) = @_;

    # TM is SpreadsheetHideRows type increase cols number with 1
    $cols += 1 if $self =~ m/SpreadsheetHideRows/;

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

    # if ($cols) {
    #     $self->configure( -cols => $cols );
    #     $self->configure( -rows => 1 ); # Keep table dim in grid
    # }
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
    $self->tagConfigure('ro_left'     , -anchor => 'w', -bg => 'lightgrey');
    $self->tagConfigure('ro_center'   , -anchor => 'n', -bg => 'lightgrey');
    $self->tagConfigure('ro_right'    , -anchor => 'e', -bg => 'lightgrey');
    $self->tagConfigure('enter_left'  , -anchor => 'w', -bg => 'white');
    $self->tagConfigure('enter_center', -anchor => 'n', -bg => 'white');
    $self->tagConfigure(
        'enter_center_blue',
        -anchor => 'n',
        -bg     => 'lightblue',
    );
    $self->tagConfigure( 'enter_right', -anchor => 'e', -bg => 'white' );
    $self->tagConfigure( 'find_row', -bg => 'lightgreen' );

    # TableMatrix header, Set Name, Align, Width
    foreach my $field ( keys %{$tm_fields} ) {
        my $col = $tm_fields->{$field}{id};
        $self->tagCol( $tm_fields->{$field}{tag}, $col );
        $self->set( "0,$col", $tm_fields->{$field}{label} );

        # If colstretch = 'n' in screen config file, don't set width,
        # because of the -colstretchmode => 'unset' setting, col 'n'
        # will be of variable width
        next if $strech and $col == $strech;

        my $width = $tm_fields->{$field}{width};
        if ( $width and ( $width > 0 ) ) {
            $self->colWidth( $col, $width );
        }
    }

    # Add selector column
    if ($selecol) {
        $self->insertCols( $selecol, 1 );
        $self->tagCol( 'ro_center', $selecol );
        $self->colWidth( $selecol, 3 );
        $self->set( "0,$selecol", 'Sel' );
    }

    $self->tagRow( 'title', 0 );
    if ( $self->tagExists('expnd') ) {
        # Change the tag priority
        $self->tagRaise( 'expnd', 'title' );
    }

    return;
}

=head2 data_read

Read data from widget.

=cut

sub data_read {
    my $self  = shift;

    my $xtvar = $self->cget( -variable );

    my $rows_no  = $self->cget( -rows );
    my $cols_no  = $self->cget( -cols );
    my $rows_idx = $rows_no - 1;
    my $cols_idx = $cols_no - 1;

    # my $fields_cfg = $self->scrcfg('rec')->dep_table_columns($tm_ds);
    # my $cols_ref   = Tpda3::Utils->sort_hash_by_id($fields_cfg);

    # # Get selectorcol index, if any
    my $sc; # = $self->scrcfg('rec')->dep_table_has_selectorcol($tm_ds);

    # # Read table data and create an AoH
    my @tabledata;

    # # The first row is the header
    # for my $row ( 1 .. $rows_idx ) {

    #     my $rowdata = {};
    #     for my $col ( 0 .. $cols_idx ) {

    #         next if $sc and ($col == $sc); # skip selectorcol

    #         my $cell_value = $self->get("$row,$col");
    #         my $col_name = $cols_ref->[$col];

    #         my $fld_cfg = $fields_cfg->{$col_name};
    #         my ($rw ) = @$fld_cfg{'rw'};     # hash slice

    #         next if $rw eq 'ro'; # skip ro cols

    #         # print "$row: $col_name => $cell_value\n";
    #         $rowdata->{$col_name} = $cell_value;
    #     }

    #     push @tabledata, $rowdata;
    # }

    return (\@tabledata, $sc);
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # end of Tpda3::Tk::TM
