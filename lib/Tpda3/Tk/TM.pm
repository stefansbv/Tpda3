package Tpda3::Tk::TM;

use strict;
use warnings;
use Carp;

use Tk;
use base qw{Tk::TableMatrix};

use Tpda3::Utils;

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
    my ( $class, $frame, $args ) = @_;

    my $xtvar1 = {};    # must init as hash reference!

    #- Frame for TM
    my $tmxf = $frame->Frame->pack(
        -expand => 1,
        -fill   => 'both'
    );

    #- Create the scrollbars

    my $v_sb = $tmxf->Scrollbar();
    # my $h_sb = $tmxf->Scrollbar();

    my $self = $class->SUPER::new(
        $tmxf,
        -rows           => 6,
        -cols           => 1,
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
        # -width   => 10,
        -orient  => 'v',
        -command => [ 'yview' => $self ],
    );

    $v_sb->pack( -side => 'left', -fill => 'y' );

    #-- Horizontal scrollbar

    #  $h_sb->configure(
    #     -width   => 10,
    #     -orient  => 'h',
    #     -command => [ 'xview' => $self ],
    # );
    # $h_sb->pack( -side => 'bottom', -fill => 'x' );

    $self->pack( -side => 'left', -fill => 'both', -expand => 1 );

    $self->_init($frame, $args);

    return $self;
}

=head2 _init

Write header on row 0 of TableMatrix

=cut

sub _init {
    my ($self, $frame, $args) = @_;

    $self->{columns}     = $args->{columns};
    $self->{selectorcol} = $args->{selectorcol};
    $self->{colstretch}  = $args->{colstretch};

    $self->{frame}  = $frame;
    $self->{tm_sel} = undef;               # selected row

    $self->set_tags();

    return;
}

=head2 set_tablematrix_tags

Set tags for the table matrix.

=cut

sub set_tags {
    my $self = shift;

    my $cols = scalar keys %{ $self->{columns} };

    # TM is SpreadsheetHideRows type increase cols number with 1
    # $cols += 1 if $self =~ m/SpreadsheetHideRows/;

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
    foreach my $field ( keys %{$self->{columns}} ) {
        my $col = $self->{columns}->{$field}{id};
        $self->tagCol( $self->{columns}->{$field}{tag}, $col );
        $self->set( "0,$col", $self->{columns}->{$field}{label} );

        # If colstretch = 'n' in screen config file, don't set width,
        # because of the -colstretchmode => 'unset' setting, col 'n'
        # will be of variable width
        next if $self->{colstretch} and $col == $self->{colstretch};

        my $width = $self->{columns}->{$field}{width};
        if ( $width and ( $width > 0 ) ) {
            $self->colWidth( $col, $width );
        }
    }

    # Add selector column
    if ( $self->{selectorcol} ) {
        my $selecol = $self->{selectorcol};
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

sub clear_all {
    my $self = shift;

    my $rows_no  = $self->cget( -rows );
    my $rows_idx = $rows_no - 1;
    my $r;

    for my $row ( 1 .. $rows_idx ) {
            $self->deleteRows( $row, 1 );
    }

    return;
}

=head2 fill

Fill TableMatrix widget with data.

=cut

sub fill {
    my ($self, $record_ref) = @_;

    my $xtvar = $self->cget( -variable );

    my $row = 1;

    #- Scan and write to table

    foreach my $record ( @{$record_ref} ) {
        foreach my $field ( keys %{ $self->{columns} } ) {
            my $fld_cfg = $self->{columns}{$field};

            croak "$field field's config is EMPTY\n" unless %{$fld_cfg};

            my $value = $record->{$field};
            $value = q{} unless defined $value;    # empty
            $value =~ s/[\n\t]//g;                 # delete control chars

            my ( $col, $validtype, $width, $places ) =
              @$fld_cfg{'id','validation','width','places'}; # hash slice

            if ( $validtype eq 'numeric' ) {
                $value = 0 unless $value;
                if ( defined $places ) {

                    # Daca SCALE >= 0, Formatez numarul
                    $value = sprintf( "%.${places}f", $value );
                }
                else {
                    $value = sprintf( "%.0f", $value );
                }
            }

            $xtvar->{"$row,$col"} = $value;
        }

        $row++;
    }

    # Refreshing the table...
    $self->configure( -rows => $row);

    return;
}


=head2 write_row

Write a row to a TableMatrix widget.

TableMatrix designator is optional and default to 'tm1'.

=cut

sub write_row {
    my ($self, $row, $col, $record_ref) = @_;

    return unless ref $record_ref;     # No results

    my $xtvar = $self->cget( -variable );

    my $nr_col = 0;
    foreach my $field ( keys %{$record_ref} ) {

        my $fld_cfg = $self->{columns}{$field};
        my $value   = $record_ref->{$field};

        my ( $col, $validtype, $width, $places ) =
            @$fld_cfg{'id','validation','width','places'}; # hash slice

        if ( $validtype =~ /digit/ ) {
            $value = 0 unless $value;
            if ( defined $places ) {

                # Daca SCALE >= 0, Formatez numarul
                $value = sprintf( "%.${places}f", $value );
            }
            else {
                $value = sprintf( "%.0f", $value );
            }
        }

        $xtvar->{"$row,$col"} = $value;
        $nr_col++;
    }

    return $nr_col;
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

    my $fields_cfg = $self->{columns};
    my $cols_ref = Tpda3::Utils->sort_hash_by_id($fields_cfg);

    # Get selectorcol index, if any
    my $sc = $self->{selectorcol};

    # # Read table data and create an AoH
    my @tabledata;

    # The first row is the header
    for my $row ( 1 .. $rows_idx ) {

        my $rowdata = {};
        for my $col ( 0 .. $cols_idx ) {

            next if $sc and ($col == $sc); # skip selectorcol

            my $cell_value = $self->get("$row,$col");
            my $col_name = $cols_ref->[$col];

            my $fld_cfg = $fields_cfg->{$col_name};
            my ($rw) = @$fld_cfg{'rw'};    # hash slice

            next if $rw eq 'ro';    # skip ro cols

            $rowdata->{$col_name} = $cell_value;
        }

        push @tabledata, $rowdata;
    }

    return (\@tabledata, $sc);
}

=head2 cell_read

Read a cell from a TableMatrix widget and return it as a hash
reference.

TableMatrix designator is optional and default to 'tm1'.

The I<col> parameter can be a number - column index or a column name.

=cut

sub cell_read {
    my ($self, $row, $col) = @_;

    my $is_col_name = 0;
    $is_col_name    = 1 if $col !~ m{\d+};

    my $fields_cfg = $self->{columns};

    my $col_name;
    if ($is_col_name) {
        $col_name = $col;
        $col = $fields_cfg->{$col_name}{id};
    }
    else {
        my $cols_ref = Tpda3::Utils->sort_hash_by_id($fields_cfg);
        $col_name = $cols_ref->[$col];
    }

    my $cell_value = $self->get("$row,$col");

    return {$col_name => $cell_value};
}

=head2 add_row

Table matrix methods.  Add TableMatrix row.

=cut

sub add_row {
    my ($self) = @_; # , $controller

    my $updstyle = 'delete+add';

    $self->configure( state => 'normal' );    # normal state
    my $old_r = $self->index( 'end', 'row' ); # get old row index
    $self->insertRows('end');
    my $new_r = $self->index( 'end', 'row' ); # get new row index

    if (($updstyle eq 'delete+add') or ($old_r == 0)) {
        $self->set( "$new_r,0", $new_r );     # set new index
        $self->renum_row($self);
    }
    else {
        # No renumbering ...
        my $max_r = (sort {$b <=> $a} $self->get("1,0","$old_r,0"))[0]; # max row
        if ($max_r >= $new_r) {
            $self->set( "$new_r,0", $max_r + 1);
        }
        else {
            $self->set( "$new_r,0", $new_r);
        }
    }

    my $sc = $self->{selectorcol};
    if ($sc) {
        $self->embeded_buttons( $new_r, $sc ); # add button
        $self->set_selected($new_r);
    }

    # Focus to newly inserted row, column 1
    $self->focus;
    $self->activate("$new_r,1");
    $self->see("$new_r,1");

    return;
}

=head2 remove_row

Delete TableMatrix row.

=cut

sub remove_row {
    my ($self, $row) = @_; # , $controller

    my $updstyle = 'delete+add';

    $self->configure( state => 'normal' );

    if ( $row >= 1 ) {
        $self->deleteRows( $row, 1 );
    }
    else {
        print "Select a row!\n";
    }

    my $sc = $self->{selectorcol};
    if ($sc) {
        $self->set_selected($row - 1);
    }

    $self->renum_row($self)
      if $updstyle eq 'delete+add';    # renumber rows

    # Refresh table
    $self->activate('origin');
    $self->activate("$row,1");

    return;
}

sub get_active_row {
    my $self = shift;

    my $r;
    eval {
        $r = $self->index( 'active', 'row' );
    };
    if ($@) {
        print "Select a row!\n";
        return;
    }

    return $r;
}

=head2 renum_row

Renumber TableMatrix rows.

=cut

sub renum_row {
    my $self = shift;

    my $r = $self->index( 'end', 'row' );

    if ( $r >= 1 ) {
        foreach my $i ( 1 .. $r ) {
            $self->set( "$i,0", $i );
        }
    }

    return;
}

=head2 tmatrix_make_selector

Make TableMatrix selector.

=cut

sub tmatrix_make_selector {
    my ($self, $c) = @_;

    my $rows_no  = $self->cget( -rows );
    my $rows_idx = $rows_no - 1;

    foreach my $r ( 1 .. $rows_idx ) {
        $self->embeded_buttons( $r, $c );
    }

    return;
}

=head2 embeded_buttons

Embeded windows

=cut

sub embeded_buttons {
    my ($self, $row, $col) = @_;

    $self->windowConfigure(
        "$row,$col",
        -sticky => 's',
        -window => $self->build_rbbutton($row, $col),
    );

    return;
}

=head2 build_rbbutton

Build Radiobutton.

=cut

sub build_rbbutton {
    my ( $self, $row, $col ) = @_;

    my $button = $self->{frame}->Radiobutton(
        -width       => 3,
        -variable    => \$self->{tm_sel},
        -value       => $row,
        -indicatoron => 0,
        -selectcolor => 'lightblue',
        -state       => 'normal',
    );

    # Default selected row == 1
    $self->set_selected($row) if $row == 1;

    return $button;
}

=head2 get_selected

Get selected table row.

=cut

sub get_selected {
    my $self = shift;

    return $self->{tm_sel};
}

sub set_selected {
    my ($self, $selected_row) = @_;

    if ($selected_row) {
        $self->{tm_sel} = $selected_row;
    }
    else {
        $self->{tm_sel} = undef;
    }

    return;
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