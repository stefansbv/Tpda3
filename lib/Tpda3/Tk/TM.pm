package Tpda3::Tk::TM;

# ABSTRACT: Create a table matrix widget

use 5.010;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(looks_like_number);
use Date::Calc;
use Tk;
use base qw< Tk::Derived Tk::TableMatrix >;
use Tk::widgets qw< Checkbutton Radiobutton DateEntry JComboBox >;

use Tpda3::Utils;

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
    $self->{fields} = Tpda3::Utils->sort_hash_by_id( $self->{columns} );
    $self->{bg}     = $frame->cget('-background');

    # Embeded widgets init
    $self->{embeded_meta} = { fields => $self->find_embeded_widgets };
    foreach my $emb ( @{ $self->{embeded_meta}{fields} } ) {
        if ( exists $args->{$emb} ) {
            $self->{embeded_meta}{$emb} = { choices => $args->{$emb} };
        }
        else {
            warn "No init args for '$emb'\n";
        }
    }
    
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
        my $col      = $self->cell_config_for($field, 'id');
        my $datatype = $self->cell_config_for($field, 'datatype');
        my $numscale = $self->cell_config_for($field, 'numscale');

        $self->tagCol( $self->cell_config_for($field, 'tag'), $col );
        $self->set( "0,$col", $self->cell_config_for($field, 'label') );

        # If colstretch = 'n' in screen config file, don't set width,
        # because of the -colstretchmode => 'unset' setting, col 'n'
        # will be of variable width
        next if $self->{colstretch} and $col == $self->{colstretch};

        my $width = $self->cell_config_for($field, 'displ_width');
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
        $self->tagRaise( 'expnd', 'title' );        # change the tag priority
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
    my ( $self, $records ) = @_;
    my $row = 1;
    $self->clear_all;
    foreach my $record ( @{$records} ) {
        $self->add_row;
        $self->write_row($row, $record);
        $row++;
    }
    $self->update;
    return $row;
}

sub read_row {
    my ( $self, $row ) = @_;
    my $row_data = {};
    foreach my $field ( @{ $self->{fields} } ) {
        my $cell_data = $self->cell_read( $row, $field );
        foreach my $key ( keys %{$cell_data} ) {
            $row_data->{$key} = $cell_data->{$key};
        }
    }
    return $row_data;
}

sub write_row {
    my ( $self, $row, $record ) = @_;
    return unless ref $record;    # no results
    my $nr_col = 0;
    foreach my $field ( keys %{$record} ) {
        my $value    = $record->{$field};
        my $col      = $self->cell_config_for($field, 'id');
        my $datatype = $self->cell_config_for($field, 'datatype');
        my $numscale = $self->cell_config_for($field, 'numscale');
        if ( $datatype =~ /digit/ ) {
            $value = 0 unless $value;
            if ( defined $numscale ) {
                $value = sprintf( "%.${numscale}f", $value );
            }
            else {
                $value = sprintf( "%.0f", $value );
            }
        }
        $self->cell_write( $row, $col, $value );
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
    my $cols_ref   = $self->{fields};

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

sub get_field_for {
    my ( $self, $col ) = @_;
    croak "get_field_for: the $col parameter must be numeric"
        unless looks_like_number($col);
    return $self->{fields}[$col];
}

sub cell_config_for {
    my ( $self, $col, $attrib ) = @_;
    if ( $self->is_col_name($col) ) {
        return $self->{columns}{$col}{$attrib};
    }
    else {
        my $field = $self->get_field_for($col);
        return $self->{columns}{$field}{$attrib};
    }
}

sub is_col_name {
    my ($self, $col) = @_;
    return not looks_like_number($col);
}

sub cell_read {
    my ( $self, $row, $col ) = @_;
    my $w_type = $self->cell_config_for( $col, 'embed' ) // '';
    # print "cell_read: $row, $col is $w_type\n";
    my $field;
    if ( $self->is_col_name($col) ) {
        $field = $col;
        $col   = $self->cell_config_for($field, 'id');
    }
    else {
        $field = $self->get_field_for($col);
    }
    # say "$field has emebded widget = ",
    # $self->has_embeded_widget($field);
    my $cell_value = $self->get("$row,$col");
    return { $field => $cell_value };
}

sub cell_write {
    my ( $self, $r, $c, $value ) = @_;
    my $w_type = $self->cell_config_for( $c, 'embed' ) // '';
    my $field;
    if ( $self->is_col_name($c) ) {
        $field = $c;
        $c     = $self->cell_config_for($field, 'id');
    }
    else {
        $field = $self->{fields}[$c];
    }
    $self->set("$r,$c", $value);
    my $w;                      # update the embeded widget
    eval { $w = $self->windowCget( "$r,$c", '-window' ) };
    unless ($@) {
        if ( $w =~ /Tk::JComboBox/ ) {
            my $var = $w->cget('-textvariable');
            $$var   = $value;
        }
        elsif ( $w =~ /Tk::DateEntry/ ) {
            my $var = $w->cget('-textvariable');
            $$var   = $value;
        }
    }
    return;
}

sub add_row {
    my $self = shift;
    my $updstyle = 'delete+add'; # the only update style? XXX

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
        $self->embeded_sel_buttons( $new_r, $sc );    # add button
        $self->set_selected($new_r);
    }

    $self->add_embeded_widgets($new_r);    # add embeded windows

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
    return if $@;
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
        $self->embeded_sel_buttons( $r, $c );
    }
    return;
}

sub find_embeded_widgets {
    my $self = shift;
    my @cols;
    foreach my $field ( @{ $self->{fields} } ) {
        my $w_type = $self->cell_config_for( $field, 'embed' ) // '';
        push @cols, $field if $w_type;
    }
    return \@cols;
}

sub has_embeded_widget {
    my ($self, $field) = @_;
    return exists $self->{embeded_meta}{$field};
}

sub add_embeded_widgets {
    my ( $self, $row ) = @_;
    my $fields_cfg = $self->{columns};
    foreach my $field ( @{ $self->{fields} } ) {
        my $has_embeded = exists $fields_cfg->{$field}{embed};
        next unless $has_embeded;
        my $w_type = $self->cell_config_for( $field, 'embed' ) // '';
        my $col    = $self->cell_config_for( $field, 'id' );
        # say "make $w_type at $row:$col";
        if ( $w_type eq 'dateentry' ) {
            $self->windowConfigure(
                "$row,$col",
                -sticky => 'ne',
                -window => $self->build_dateentry( $row, $col ),
            );
        }
        elsif ( $w_type eq 'jcombobox' ) {
            my $choices =  $self->{embeded_meta}{$field}{choices};
            $self->windowConfigure(
                "$row,$col",
                -sticky  => 'ne',
                -window  => $self->build_jcombobox( $row, $col, $choices ),
            );
        }
        $self->update;
    }
    return;
}

sub embeded_sel_buttons {
    my ( $self, $row, $col ) = @_;
    my $selestyle = defined $self->{selectorstyle}
        ? $self->{selectorstyle}
        : q{};
    my $selecolor = defined $self->{selectorcolor}
        ? $self->{selectorcolor}
        : q{lightblue};
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

sub build_dateentry {
    my ( $self, $row, $col ) = @_;
    my $date_format = 'dmy';
    my $width = $self->cell_config_for( $col, 'displ_width' );
    my $var;
    my $button = $self->{frame}->DateEntry(
        -textvariable => \$var,
        #-daynames     => [ qw(D L Ma Mi J V S) ],
        #-arrowimage => 'calmonth16',
        -weekstart       => 1,
        -todaybackground => 'lightgreen',
        -parsecmd        => sub {
            Tpda3::Utils->dateentry_parse_date( 'iso', @_ );
        },
        -formatcmd => sub {
            Tpda3::Utils->dateentry_format_date( $date_format, @_ );
        },
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
        -width              => $width,
        -relief             => 'raised',
    );
    return $button;
}

sub build_jcombobox {
    my ( $self, $row, $col, $choices ) = @_;
    my $var;
    my $width = $self->cell_config_for( $col, 'displ_width' );
    my $button = $self->{frame}->JComboBox(
        -textvariable       => \$var,
        -choices            => $choices,
        -browsecmd          => sub { $self->jcombo_browse( $row, $col, @_ ) },
        -state              => 'normal',
        -entrywidth         => $width,
        -disabledforeground => 'black'
    );
    return $button;
}

sub jcombo_browse {
    my ( $self, $row, $col, $jcb, $sel_index, $sel_value, $sel_name ) = @_;
    $self->cell_write( $row, $col, $sel_name );
    return;
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
    my ( $self, $r, $c ) = @_;
    croak "is_checked: missing parameters \$r or/and \$c"
        unless defined $r and defined $c;
    my $is_checked = 0;
    my $bw;
    eval { $bw = $self->windowCget( "$r,$c", -window ); };
    unless ($@) {
        if ( $bw =~ /Checkbutton/ ) {
            my $ckb_var = $bw->cget('-variable');
            $is_checked = $$ckb_var ? $$ckb_var : 0;
        }
        # Radiobutton uses the global var $self->{tm_sel}
    }
    return $is_checked;
}

sub count_is_checked {
    my ( $self, $c ) = @_;
    croak "count_is_checked: missing parameter \$c" unless defined $c;
    my $rows_no  = $self->cget('-rows');
    my $rows_idx = $rows_no - 1;
    my $count    = 0;
    for my $r ( 1 .. $rows_idx ) {
        $count++ if $self->is_checked( $r, $c );
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
        -cols           => 4,
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

=head2 embeded_sel_buttons

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

Parameters: row, col.

Return true if a embedded CheckButton is checked.  Does not apply for
RadioButtons!

=head2 count_is_checked

Return how many buttons are checked.

=cut
