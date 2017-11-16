package Tpda3::Tk::TM;

# ABSTRACT: Create a table matrix widget

use strict;
use warnings;
use Carp;
use Tpda3::Utils;

use Tk;
use base qw< Tk::Derived Tk::TableMatrix >;
use Tk::widgets qw< Checkbutton >;

Tk::Widget->Construct('TM');

sub ClassInit {
    my ( $class, $mw ) = @_;

    $class->SUPER::ClassInit($mw);

    # Swap some bindings
    $mw->bind($class ,'<Control-Left>',['MoveCell',0,-1]);
    $mw->bind($class ,'<Left>',
                  sub {
                      my $w = shift;
                      my $Ev = $w->XEvent;
                      my $posn = $w->icursor;
                      $w->icursor($posn - 1);
                  }
              );
    $mw->bind($class ,'<Control-Right>',['MoveCell',0,1]);
    $mw->bind($class ,'<Right>',
                  sub {
                      my $w = shift;
                      my $Ev = $w->XEvent;
                      my $posn = $w->icursor;
                      $w->icursor($posn + 1);
                  }
              );

    return;
}

sub Populate {
    my ( $self, $args ) = @_;

    $self->SUPER::Populate($args);

    return $self;
}

sub init {
    my ( $self, $frame, $args ) = @_;

    # Screen configs
    foreach my $key (keys %{$args}) {
        $self->{$key} = $args->{$key};
    }

    # Other
    $self->{frame}  = $frame;
    $self->{tm_sel} = undef;    # selected row

    $self->set_tags();

    return;
}

sub get_row_count {
    my $self = shift;

    my $rows_no  = $self->cget('-rows');
    my $rows_count = $rows_no - 1;

    return $rows_count;
}

sub set_tags {
    my $self = shift;

    my $cols = scalar keys %{ $self->{columns} };

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

    # Make enter do the same thing as return
    $self->bind( '<KP_Enter>', $self->bind('<Return>') );

    $self->configure( -cols => $cols ) if $cols;

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
    $self->tagConfigure(
        'ro_left',
        -state  => 'disabled',
        -anchor => 'w',
        -bg     => 'lightgrey',
    );
    $self->tagConfigure(
        'ro_center',
        -state  => 'disabled',
        -anchor => 'n',
        -bg     => 'lightgrey',
    );
    $self->tagConfigure(
        'ro_right',
        -state  => 'disabled',
        -anchor => 'e',
        -bg     => 'lightgrey',
    );
    $self->tagConfigure( 'enter_left',   -anchor => 'w', -bg => 'white' );
    $self->tagConfigure( 'enter_center', -anchor => 'n', -bg => 'white' );
    $self->tagConfigure(
        'enter_center_blue',
        -anchor => 'n',
        -bg     => 'lightblue',
    );
    $self->tagConfigure( 'enter_right', -anchor => 'e', -bg => 'white' );

    # $self->tagConfigure( 'find_row', -bg => 'lightgreen' );

    # TableMatrix header, Set Name, Align, Width
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

    my $rows_no  = $self->cget('-rows');
    my $rows_idx = $rows_no - 1;
    my $r;

    for my $row ( 1 .. $rows_idx ) {
        $self->deleteRows( $row, 1 );
    }

    return;
}

sub fill {
    my ( $self, $record_ref ) = @_;

    my $xtvar = $self->cget('-variable');

    my $row = 1;

    #- Scan and write to table

    foreach my $record ( @{$record_ref} ) {
        foreach my $field ( keys %{ $self->{columns} } ) {
            my $fld_cfg = $self->{columns}{$field};

            croak "$field field's config is EMPTY\n" unless %{$fld_cfg};

            my $value = $record->{$field};
            $value = q{} unless defined $value;    # empty
            $value =~ s/[\n\t]//g;                 # delete control chars

            my ( $col, $datatype, $width, $numscale )
                = @$fld_cfg{ 'id', 'datatype', 'displ_width',
                'numscale' };                        # hash slice

            if ( $datatype eq 'numeric' ) {
                $value = 0 unless $value;
                if ( defined $numscale ) {

                    # Daca SCALE >= 0, Formatez numarul
                    $value = sprintf( "%.${numscale}f", $value );
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
    $self->configure( -rows => $row );

    return;
}

sub write_row {
    my ( $self, $row, $col, $record_ref ) = @_;

    return unless ref $record_ref;    # No results

    my $xtvar = $self->cget('-variable');

    my $nr_col = 0;
    foreach my $field ( keys %{$record_ref} ) {

        my $fld_cfg = $self->{columns}{$field};
        my $value   = $record_ref->{$field};

        my ( $col, $datatype, $width, $numscale )
            = @$fld_cfg{ 'id', 'datatype', 'displ_width',
            'numscale' };    # hash slice

        if ( $datatype =~ /digit/ ) {
            $value = 0 unless $value;
            if ( defined $numscale ) {

                # Daca SCALE >= 0, Formatez numarul
                $value = sprintf( "%.${numscale}f", $value );
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

sub data_read {
    my ($self, $with_sel_name, $all_cols) = @_;

    my $xtvar = $self->cget('-variable');

    my $rows_no  = $self->cget('-rows');
    my $cols_no  = $self->cget('-cols');
    my $rows_idx = $rows_no - 1;
    my $cols_idx = $cols_no - 1;

    my $fields_cfg = $self->{columns};
    my $cols_ref   = Tpda3::Utils->sort_hash_by_id($fields_cfg);

    # Get selectorcol index, if any
    my $sc = $self->{selectorcol};

    # Read table data and create an AoH
    my @tabledata;

    # The first row is the header
    for my $row ( 1 .. $rows_idx ) {

        my $rowdata = {};
        for my $col ( 0 .. $cols_idx ) {

            if ( $sc and ( $col == $sc ) ) {    # selectorcol
                $rowdata->{$with_sel_name}
                    = $self->is_checked( $row, $sc ) ? 1 : 0
                    if $with_sel_name;
                next;
            }

            my $cell_value = $self->get("$row,$col");
            my $col_name   = $cols_ref->[$col];

            my $fld_cfg = $fields_cfg->{$col_name};
            my ($readwrite) = @$fld_cfg{'readwrite'};    # hash slice

            unless ($all_cols) {
                next if $readwrite eq 'ro';    # skip ro cols
            }

            $rowdata->{$col_name} = $cell_value;
        }

        push @tabledata, $rowdata;
    }

    return ( \@tabledata, $sc );
}

sub cell_read {
    my ( $self, $row, $col ) = @_;

    my $is_col_name = 0;
    $is_col_name = 1 if $col !~ m{\d+};

    my $fields_cfg = $self->{columns};

    my $col_name;
    if ($is_col_name) {
        $col_name = $col;
        $col      = $fields_cfg->{$col_name}{id};
    }
    else {
        my $cols_ref = Tpda3::Utils->sort_hash_by_id($fields_cfg);
        $col_name = $cols_ref->[$col];
    }

    my $cell_value = $self->get("$row,$col");

    return { $col_name => $cell_value };
}

sub cell_write {
    my ( $self, $row, $col, $value ) = @_;

    my $is_col_name = 0;
    $is_col_name = 1 if $col !~ m{\d+};

    my $fields_cfg = $self->{columns};

    my $col_name;
    if ($is_col_name) {
        $col_name = $col;
        if (exists $fields_cfg->{$col_name}{id}) {
            $col = $fields_cfg->{$col_name}{id};
        }
        else {
            croak "Can't establish column index for '$col'";
        }
    }
    else {
        my $cols_ref = Tpda3::Utils->sort_hash_by_id($fields_cfg);
        $col_name = $cols_ref->[$col];
    }

    $self->set("$row,$col", $value);

    return;
}

sub add_row {
    my $self = shift;

    my $updstyle = 'delete+add';

    $self->configure( state => 'normal' );    # normal state
    my $old_r = $self->index( 'end', 'row' ); # get old row index
    $self->insertRows('end');
    my $new_r = $self->index( 'end', 'row' );    # get new row index

    if ( ( $updstyle eq 'delete+add' ) or ( $old_r == 0 ) ) {
        $self->set( "$new_r,0", $new_r );        # set new index
        $self->renum_row($self);
    }
    else {

        # No renumbering ...
        my $max_r = ( sort { $b <=> $a } $self->get( "1,0", "$old_r,0" ) )[0]
            ;                                    # max row
        if ( $max_r >= $new_r ) {
            $self->set( "$new_r,0", $max_r + 1 );
        }
        else {
            $self->set( "$new_r,0", $new_r );
        }
    }

    my $sc = $self->{selectorcol};
    if ($sc) {
        $self->embeded_buttons( $new_r, $sc );    # add button
        $self->set_selected($new_r);
    }

    # Focus to newly inserted row, column 1
    $self->focus;
    $self->activate("$new_r,1");
    $self->see("$new_r,1");

    return $new_r;
}

sub remove_row {
    my ( $self, $row ) = @_;

    my $updstyle = 'delete+add';

    $self->configure( state => 'normal' );

    if ( $row >= 1 ) {
        $self->deleteRows( $row, 1 );
    }
    else {
        # print "Select a row!\n";
        return;
    }

    my $sc = $self->{selectorcol};
    if ($sc) {
        $self->set_selected( $row - 1 );
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
    eval { $r = $self->index( 'active', 'row' ); };
    if ($@) {
        print "Select a row!\n";
        return;
    }

    return $r;
}

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

sub tmatrix_make_selector {
    my ( $self, $c ) = @_;

    my $rows_no  = $self->cget('-rows');
    my $rows_idx = $rows_no - 1;

    foreach my $r ( 1 .. $rows_idx ) {
        $self->embeded_buttons( $r, $c );
    }

    return;
}

sub embeded_buttons {
    my ( $self, $row, $col ) = @_;

    my $selestyle = defined $self->{selectorstyle}
        ? $self->{selectorstyle}
        : q{}
        ;
    my $selecolor = defined $self->{selectorcolor}
        ? $self->{selectorcolor}
        : q{lightblue}
        ;

    if ( $selestyle eq 'checkbox' ) {
        $self->windowConfigure(
            "$row,$col",
            -sticky => 's',
            -window => $self->build_ckbutton( $row, $col ),
        );
    }
    else {
        $self->windowConfigure(
            "$row,$col",
            -sticky => 's',
            -window => $self->build_rbbutton( $row, $col, $selecolor ),
        );
    }

    return;
}

sub build_rbbutton {
    my ( $self, $row, $col, $selecolor ) = @_;

    my $button = $self->{frame}->Radiobutton(
        -width       => 3,
        -variable    => \$self->{tm_sel},
        -value       => $row,
        -indicatoron => 0,
        -selectcolor => $selecolor,
        -state       => 'normal',
        -command     => sub { $self->validate("$row,$col") }
    );

    # Default selected row == 1
    $self->set_selected($row) if $row == 1;

    return $button;
}

sub get_selected {
    my $self = shift;
    return $self->{tm_sel};
}

sub set_selected {
    my ( $self, $selected_row ) = @_;

    if ($selected_row) {
        $self->{tm_sel} = $selected_row;
    }
    else {
        $self->{tm_sel} = undef;
    }

    return;
}

sub get_selector {
    my $self = shift;
    return $self->{selectorcol};
}

sub build_ckbutton {
    my ( $self, $row, $col ) = @_;

    my $button = $self->{frame}->Checkbutton(
        -image       => 'actcross16',
        -selectimage => 'actcheck16',
        -indicatoron => 0,
        -selectcolor => 'lightblue',
        -state       => 'normal',
        -command     => sub { $self->validate("$row,$col") }
    );

    return $button;
}

sub toggle_ckbutton {
    my ( $self, $r, $c, $state ) = @_;

    my $ckb;
    eval { $ckb = $self->windowCget( "$r,$c", -window ); };
    unless ($@) {
        if ( $ckb =~ /Checkbutton/ ) {
            if ( defined $state ) {
                $state ? $ckb->select : $ckb->deselect;
            }
            else {
                $self->is_checked( $r, $c ) ? $ckb->deselect : $ckb->select;
            }
        }
    }

    return;
}

sub is_checked {
    my ($self, $r, $c) = @_;

    croak unless $r and $c;

    my $ckb;
    my $is_checked = 0;
    eval { $ckb = $self->windowCget( "$r,$c", -window ); };
    unless ($@) {
        if ( $ckb =~ /Checkbutton/ ) {
            my $ckb_var = $ckb->cget('-variable');
            $is_checked = $$ckb_var ? $$ckb_var : 0;
        }
    }

    return $is_checked;
}

sub count_is_checked {
    my ($self, $c) = @_;

    my $rows_no  = $self->cget('-rows');
    my $rows_idx = $rows_no - 1;

    my $count = 0;
    for my $r ( 1 .. $rows_idx ) {
        $count++ if $self->is_checked($r, $c);
    }

    return $count;
}

1;

=head1 SYNOPSIS

    use Tpda3::Tk::TM;

    my $xtvar = {};
    my $xtable = $frame->Scrolled(
        'TM',
        -rows           => 6,
        -cols           => 1,
        -width          => -1,
        -height         => -1,
        -ipadx          => 3,
        -titlerows      => 1,
        -validate       => 1,
        -variable       => $xtvar,
        -selectmode     => 'single',
        -colstretchmode => 'unset',
        -resizeborders  => 'none',
        -bg             => 'white',
        -scrollbars     => 'osw',
    );
    $xtable->pack( -expand => 1, -fill => 'both' );

    $xtable->init($frame, $header);

=head2 ClassInit

Class initializations.

Changes the bindings for cursor movements in the cell and between
cells.

=head2 Populate

Constructor method, calls SUPER Populate.

=head2 init

Write header on row 0 of TableMatrix.

=head2 get_row_count

Return number of rows in TM, without the header row.

=head2 set_tags

Define and set tags for the Table Matrix.

=head2 clear_all

Clear all data from the Tk::TableMatrix widget, but preserve the header.

=head2 fill

Fill TableMatrix widget with data.

=head2 write_row

Write a row to a TableMatrix widget.

TableMatrix designator is optional and default to 'tm1'.

=head2 data_read

Read data from widget.

=head2 cell_read

Read a cell from a TableMatrix widget and return it as a hash
reference.

TableMatrix designator is optional and default to 'tm1'.

The I<col> parameter can be a number - column index or a column name.

=head2 cell_write

Write to a cell from a TableMatrix widget.

TableMatrix designator is optional and default to 'tm1'.

The I<col> parameter can be a number - column index or a column name.

=head2 add_row

Table matrix methods.  Add TableMatrix row.

=head2 remove_row

Delete TableMatrix row.

=head2 get_active_row

Return the active row.

=head2 renum_row

Renumber TableMatrix rows.

=head2 tmatrix_make_selector

Make TableMatrix selector.

=head2 embeded_buttons

Embeded windows.  Config option L<selectorstyle> can be L<radio> the
default, or L<checkbox>.

=head2 build_rbbutton

Build Radiobutton.

=head2 get_selected

Return selected table row, used for tables with embeded radion buttons
as selectors.

=head2 set_selected

Set row as selected. The value has to be true, for false values set to
undef. As a consequence it won't set as selected row 0.

=head2 get_selector

Return selector column.

=head2 build_ckbutton

Build Checkbutton.

=head2 toggle_ckbutton

Toggle Checkbutton or set state to L<state> if defined state.

=head2 is_checked

Return true if embedded checkbutton is checked.

=head2 count_is_checked

Return how many buttons are checked.

=cut
