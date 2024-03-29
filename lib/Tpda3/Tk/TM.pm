package Tpda3::Tk::TM;

# ABSTRACT: Create a table matrix widget

use 5.010;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(looks_like_number);
use List::MoreUtils qw(firstidx);
use Tk;
use base qw< Tk::Derived Tk::TableMatrix >;
use Tk::widgets qw< Checkbutton Radiobutton DateEntry JComboBox >;

use Tpda3::Utils;

Tk::Widget->Construct('TM');

=head3 tag_defaults

Set the default tag attributes.

=cut

sub tag_defaults {
    return {
        'detail' => {
            -bg     => 'darkseagreen2',
            -relief => 'sunken',
        },
        'detail2' => {
            -bg     => 'burlywood2',
            -relief => 'sunken',
        },
        'detail3' => {
            -bg     => 'lightyellow',
            -relief => 'sunken',
        },
        'expnd' => {
            -bg     => 'grey85',
            -relief => 'raised',
        },
        'find_mode' => {
            -state  => 'normal',
            -anchor => 'w',
            -bg     => 'lightgreen',
        },
        'find_none' => {
            -state  => 'disabled',
            -anchor => 'n',
            -bg     => 'lightgrey',
        },
        'find_left' => {
            -anchor => 'w',
            -bg     => 'lightgreen',
        },
        'find_right' => {
            -anchor => 'e',
            -bg     => 'lightgreen',
        },
        'find_center' => {
            -anchor => 'n',
            -bg     => 'lightgreen',
        },
        'ro_left' => {
            -state  => 'disabled',
            -anchor => 'w',
            -bg     => 'lightgrey',
        },
        'ro_center' => {
            -state  => 'disabled',
            -anchor => 'n',
            -bg     => 'lightgrey',
        },
        'ro_right' => {
            -state  => 'disabled',
            -anchor => 'e',
            -bg     => 'lightgrey',
        },
        'enter_left' => {
            -anchor => 'w',
            -bg     => 'white',
        },
        'enter_center' => {
            -anchor => 'n',
            -bg     => 'white',
        },
        'enter_center_blue' => {
            -anchor => 'n',
            -bg     => 'lightblue',
        },
        'enter_right' => {
            -anchor => 'e',
            -bg     => 'white',
        },
    };
}

=head2 ClassInit

Class initializations.

Changes the bindings for cursor movements in the cell and between
cells.

=cut

sub ClassInit {
    my ( $class, $mw ) = @_;

    $class->SUPER::ClassInit($mw);

    # Make a smaller font for buttons
    $mw->fontCreate(
        'button',
        -family => 'arial',
        -weight => 'bold',
        -size   => 7,
    );

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

    # From the dynarows demo script.
    # Bindings:
    # Make the active area move after we press return:
    # We Have to use class binding here so that we override
    #  the default return binding
    $mw->bind( $class, '<Return>',
               sub {
                   my $w = shift;
                   my $r = $w->index( 'active', 'row' );
                   my $c = $w->index( 'active', 'col' );

                   # Table refresh
                   $w->activate('origin');
                   $w->activate("$r,$c");
                   $w->reread();
                   my $ci = $w->cget('-cols') - 1;    # max col index
                   my $ac = $c;
                   my $sc = 1;                        # skip cols
                   $ac += $sc;                        # new active col
                   $w->activate("$r,$ac");
                   $w->see('active');
                   Tk->break;
               }
           );

    # Make enter do the same thing as return:
    $mw->bind('<KP_Enter>', $mw->bind('<Return>'));

    return;
}

=head2 Populate

Constructor method, calls SUPER Populate.

=cut

sub Populate {
    my ( $self, $args ) = @_;
    $self->SUPER::Populate($args);
    return $self;
}

=head2 init

Write header on row 0 of TableMatrix.

=cut

sub init {
    my ( $self, $frame, $args ) = @_;

    # Screen configs
    foreach my $key (keys %{$args}) {
        $self->{$key} = $args->{$key};
    }

    # Defaults
    $self->{updatestyle}   = 'delete+add' unless $self->{updatestyle};
    $self->{selectorcolor} = 'lightblue'  unless $self->{selectorcolor};

    # Other
    $self->{frame}  = $frame;
    $self->{tm_sel} = undef;    # selected row
    $self->{fields} = Tpda3::Utils->sort_hash_by_id( $self->{columns} );
    $self->{bg}     = $frame->cget('-background');

    # Embeded widgets init
    $self->{embeded_meta} = { fields => $self->find_embeded_widgets };
    foreach my $field ( @{ $self->{embeded_meta}{fields} } ) {
        my $w_type = $self->cell_config_for( $field, 'embed' ) // '';
        if ( exists $args->{$field} ) {
            $self->{embeded_meta}{$field} = { choices => $args->{$field} };
        }
        else {
            warn "No init args for jcombobox: '$field'\n" if $w_type eq 'jcombobox';
        }
    }
    $self->set_tags();
    return;
}

=head2 get_row_count

Return number of rows in TM, without the header row.

=cut

sub get_row_count {
    my $self = shift;
    my $rows_no  = $self->cget('-rows');
    my $rows_count = $rows_no - 1;
    return $rows_count;
}

=head2 set_tags

Define and set tags for the Table Matrix.

=cut

sub set_tags {
    my $self = shift;

    my $attribs = $self->tag_defaults;
    my $cols_no = scalar keys %{ $self->{columns} };

    # Create common tags
    $self->tagConfigure(
        'title',
        -bg     => 'tan',
        -fg     => 'black',
        -relief => 'raised',
        -anchor => 'n',
    );
    $self->tagConfigure(
        'active',
        -bg     => 'lightyellow',
        -relief => 'sunken',
    );

    my $tags = {};
    foreach my $field ( keys %{ $self->{columns} } ) {
        my $tag = $self->cell_config_for( $field, 'tag' );
        $tags->{$tag} = $attribs->{$tag} if $tag;
    }

    # Create find mode tags
    $self->tagConfigure( 'find_none', %{ $attribs->{find_none} } );
    $self->tagConfigure( 'find_mode', %{ $attribs->{find_mode} } );

    # Create column tags
    foreach my $tag ( keys %{$tags} ) {
        $self->tagConfigure( $tag, %{ $tags->{$tag} } );
    }

    $self->configure( -cols => $cols_no ) if $cols_no;

    # TableMatrix header, Set Name, Align, Width
    foreach my $field ( keys %{ $self->{columns} } ) {
        my $col      = $self->cell_config_for($field, 'id');
        my $datatype = $self->cell_config_for($field, 'datatype');
        my $numscale = $self->cell_config_for($field, 'numscale');
        my $findtype = $self->cell_config_for($field, 'findtype');

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
    if ( $self->{selectorcol} and $self->{selectorcol} =~ /^\d+$/) {
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

=head2 clear_all

Clear all data from the Tk::TableMatrix widget, but preserve the header.

=cut

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

=head2 fill

Fill TableMatrix widget with data.

=cut

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

=head2 data_read

Read data from the TM widget.

=cut

sub data_read {
    my ( $self, $with_sel_name, $all_cols ) = @_;
    my $rows_no  = $self->cget('-rows');
    my $rows_idx = $rows_no - 1;
    my $sc       = $self->{selectorcol};
    my @tabledata;
    for my $row ( 1 .. $rows_idx ) {
        my $rowdata = $self->read_row($row, $all_cols);
        if ($sc) {    # selectorcol
            $rowdata->{$with_sel_name}
                = $self->is_checked( $row, $sc ) ? 1 : 0
                if $with_sel_name;
        }
        push @tabledata, $rowdata;
    }
    return ( \@tabledata, $sc );
}

=head3 read_row

Read a row from the TM widget.

Parameters:

=over

=item row - the row number - required

=item all_cols - option to read all the columns

The default is to skip 'ro' cols.

=item not_null - option to return only columns with values (not empty)

=back

=cut

sub read_row {
    my ( $self, $row, $all_cols, $not_null ) = @_;
    my $row_data = {};
    foreach my $field ( @{ $self->{fields} } ) {
        my $rw = $self->cell_config_for( $field, 'readwrite' );
        if ( !$all_cols ) {
            next if $rw eq 'ro';    # skip ro cols
        }
        my $cell_data = $self->cell_read( $row, $field );
        foreach my $key ( keys %{$cell_data} ) {
            if ($not_null) {
                $row_data->{$key} = $cell_data->{$key}
                  if defined $cell_data->{$key};
            }
            else {
                $row_data->{$key} = $cell_data->{$key};
            }
        }
    }
    return $row_data;
}

=head2 write_row

Write a row to a TableMatrix widget.

TableMatrix designator is optional and default to 'tm1'.

=cut

sub write_row {
    my ( $self, $row, $record ) = @_;
    return unless ref $record;    # no results
    my $nr_col = 0;
    foreach my $field ( @{ $self->{fields} } ) {
        if ( !exists $record->{$field} ) {
            # warn "write_row: the field $field is not in the record\n";
            next;
        }
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

=head3 get_field_for

Return the field name for the coresponding col.

=cut

sub get_field_for {
    my ( $self, $col ) = @_;
    croak "get_field_for: the \$col parameter must be numeric"
        unless looks_like_number($col);
    return $self->{fields}[$col];
}

=head3 get_col_for

Get the col index for a field.

=cut

sub get_col_for {
    my ( $self, $field ) = @_;
    croak "get_col_for: the \$field parameter is required"
      unless $field;
    return firstidx { $_ eq $field } @{ $self->{fields} };
}

=head3 cell_config_for

=cut

sub cell_config_for {
    my ( $self, $col, $attrib ) = @_;
    croak "cell_config_for: the \$col parameter is required"
        unless defined $col;
    croak "cell_config_for: the \$attrib parameter is required"
        unless defined $attrib;
    if ( $self->is_col_name($col) ) {
        return $self->{columns}{$col}{$attrib};
    }
    else {
        my $field = $self->get_field_for($col);
        return $self->{columns}{$field}{$attrib};
    }
}

=head3 is_col_name

Return true if the parameter is not a number.

=cut

sub is_col_name {
    my ($self, $col) = @_;
    return not looks_like_number($col);
}

=head2 cell_read

Read a cell from a TableMatrix widget and return it as a hash
reference.

TableMatrix designator is optional and default to 'tm1'.

The I<col> parameter can be a number - column index or a column name.

=cut

sub cell_read {
    my ( $self, $row, $col ) = @_;
    die " cell_read: the \$row parameter is required\n"
        unless defined $row;
    die " cell_read: the \$col parameter is required\n"
        unless defined $col;
    my $w_type = $self->cell_config_for( $col, 'embed' ) // '';
    my $field;
    if ( $self->is_col_name($col) ) {
        $field = $col;
        $col = $self->cell_config_for( $field, 'id' );
        die " cell_read: can't get \$col parameter from field '$field'\n"
            unless defined $col;
    }
    else {
        $field = $self->get_field_for($col);
    }
    my $cell_value = $self->get("$row,$col");
    $cell_value = undef if !$cell_value;
    $cell_value = $cell_value ? 1 : 0 if $w_type eq 'ckbutton';
    return { $field => $cell_value };
}

=head2 cell_write

Write to a cell from a TableMatrix widget.

TableMatrix designator is optional and default to 'tm1'.

The I<col> parameter can be a number - column index or a column name.

=cut

sub cell_write {
    my ( $self, $r, $c, $value ) = @_;
    die "cell_write: the \$r parameter is required"
        unless defined $r;
    die "cell_write: the \$c parameter is required"
        unless defined $c;
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
    my $w;
    eval { $w = $self->windowCget( "$r,$c", '-window' ) };
    unless ($@) {
        if ( $w =~ /JComboBox/i ) {
            my $var = $w->cget('-textvariable');
            if (ref $var eq 'SCALAR') {
                $$var = $value;
            }
            else {
                die "jcombobox update failed\n";
            }
        }
        elsif ( $w =~ /DateEntry/i ) {
            my $var = $w->cget('-textvariable');
            if (ref $var eq 'SCALAR') {
                $$var = $value;
            }
            else {
                die "dateentry update failed\n";
            }

        }
        elsif ( $w =~ /Checkbutton/i ) {
            my $var = $w->cget('-variable');
            if (ref $var eq 'SCALAR') {
                $$var = $value;
            }
            else {
                die "checkbutton update failed\n";
            }
        }
    }
    return;
}

=head2 add_row

Table matrix methods.  Add TableMatrix row.

=cut

sub add_row {
    my $self = shift;
    my $updstyle = $self->{updatestyle};

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

=head2 add_row_find

Not used.  For the search (find) in TM feature.

Add a row where the search criteria can be entered and remove it after
the search was done.

=cut

sub add_row_find {
    my $self = shift;
    $self->configure( state => 'normal' );    # normal state
    $self->insertRows('end');
    my $new_r = $self->index( 'end', 'row' );    # get new row index

    # Create find tags
    foreach my $field ( keys %{ $self->{columns} } ) {
        my $col      = $self->cell_config_for($field, 'id');
        my $findtype = $self->cell_config_for( $field, 'findtype' );
        if ( defined $findtype ) {
            print "$field: findtype = $findtype\n";
            if ( $findtype eq 'none' ) {
                $self->tagCell( 'find_none', "$new_r,$col" );
            }
            else {
                $self->tagCell( 'find_mode', "$new_r,$col" );
            }
        }
    }

    # Focus to newly inserted row, column 0
    $self->focus;
    $self->activate("$new_r,0");
    $self->see("$new_r,0");

    return $new_r;
}

=head2 remove_row

Delete TableMatrix row.

=cut

sub remove_row {
    my ( $self, $row ) = @_;
    my $updstyle = $self->{updatestyle};
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
    $self->activate("$row,1");               #
    return;
}

=head2 get_active_row

Return the active row.

=cut

sub get_active_row {
    my $self = shift;
    my $r;
    eval { $r = $self->index( 'active', 'row' ); };
    return if $@;
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
    my ( $self, $c ) = @_;
    my $rows_no  = $self->cget('-rows');
    my $rows_idx = $rows_no - 1;
    foreach my $r ( 1 .. $rows_idx ) {
        $self->embeded_sel_buttons( $r, $c );
    }
    return;
}

=head3 find_embeded_widgets

Return a list of cols with embeded widgets.

=cut

sub find_embeded_widgets {
    my $self = shift;
    my @cols;
    foreach my $field ( @{ $self->{fields} } ) {
        my $w_type = $self->cell_config_for( $field, 'embed' ) // '';
        push @cols, $field if $w_type;
    }
    return \@cols;
}

=head3 has_embeded_widget

Return true if there are embeded widgets in the TM.

=cut

sub has_embeded_widget {
    my ($self, $field) = @_;
    return exists $self->{embeded_meta}{$field};
}

=head3 add_embeded_widgets

Add embeded widgets in a row.

=cut

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
                -sticky => 'nw',
                -window => $self->build_dateentry( $row, $col ),
            );
        }
        elsif ( $w_type eq 'jcombobox' ) {
            my $choices =  $self->{embeded_meta}{$field}{choices};
            $self->windowConfigure(
                "$row,$col",
                -sticky  => 'nw',
                -window  => $self->build_jcombobox( $row, $col, $choices ),
            );
        }
        elsif ( $w_type eq 'ckbutton' or $w_type eq 'checkbutton') {
            my $p = $fields_cfg->{$field};
            $self->windowConfigure(
                "$row,$col",
                -sticky  => 'n',
                -window  => $self->build_ckbutton( $row, $col, $p ),
            );
        }
        $self->update;
    }
    return;
}

=head2 embeded_sel_buttons

Embeded windows.

Config options:

=over

=item L<selectorstyle>

The selector button style can be L<radio> the default, or L<checkbox>;

=item L<selectorcolor>

The selector button color can be any Tk color and the default is
C<lightblue>;

=back

=cut

sub embeded_sel_buttons {
    my ( $self, $row, $col ) = @_;
    return unless $self->{selectorcol};
    if ( $self->{selectorstyle} and $self->{selectorstyle} eq 'checkbox' ) {
        $self->windowConfigure(
            "$row,$col",
            -sticky => 's',
            -window =>
              $self->build_sel_ckbutton( $row, $col ),
        );
    }
    else {
        $self->windowConfigure(
            "$row,$col",
            -sticky => 's',
            -window =>
              $self->build_sel_rbbutton( $row, $col ),
        );
    }
    return;
}

=head3 build_ckbutton

Build a Checkbutton embeded widget.

=cut

sub build_ckbutton {
    my ( $self, $row, $col, $p ) = @_;
    my $text  = exists $p->{text}  ? $p->{text}  : '';
    my $color = exists $p->{color} ? $p->{color} : 'lightblue';
    my $width = exists $p->{displ_width} ? $p->{displ_width} : 5;
    my $button = $self->{frame}->Checkbutton(
        -width       => $width,
        -text        => $text,
        -indicatoron => 0,
        -selectcolor => $color,
        -offvalue    => 0,
        -onvalue     => 1,
        -state       => 'normal',
        -font        => 'button',
        -command     => sub { $self->ckbutton_browse($row, $col) }
    );
    return $button;
}

=head3 build_sel_ckbutton

Build a selector Checkbutton embeded widget.

=cut

sub build_sel_ckbutton {
    my ( $self, $row, $col ) = @_;
    my $button = $self->{frame}->Checkbutton(
        -width       => 3,
        -indicatoron => 0,
        -selectcolor => $self->{selectorcolor},
        -offvalue    => 0,
        -onvalue     => 1,
        -state       => 'normal',
        -command     => sub { $self->validate("$row,$col") }
    );
    return $button;
}

=head2 build_sel_rbbutton

Build Radiobutton embeded widget.

=cut

sub build_sel_rbbutton {
    my ( $self, $row, $col ) = @_;
    my $button = $self->{frame}->Radiobutton(
        -width       => 3,
        -variable    => \$self->{tm_sel},
        -value       => $row,
        -indicatoron => 0,
        -selectcolor => $self->{selectorcolor},
        -state       => 'normal',
        -command     => sub { $self->validate("$row,$col") }
    );
    # Default selected row == 1
    $self->set_selected($row) if $row == 1;
    return $button;
}

=head2 get_selected

Return selected table row, used for tables with embeded radion buttons
as selectors.

=cut

sub get_selected {
    my $self = shift;
    return $self->{tm_sel};
}

=head2 set_selected

Set row as selected. The value has to be true, for false values set to
undef. As a consequence it won't set as selected row 0.

=cut

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

=head2 get_selector

Return selector column.

=cut

sub get_selector {
    my $self = shift;
    return $self->{selectorcol};
}

=head2 build_dateentry

Build a DateEntry embeded widget.

=cut

sub build_dateentry {
    my ( $self, $row, $col ) = @_;
    my $date_format;# = 'dmy';
    my $width = $self->cell_config_for( $col, 'displ_width' );
    my $var;
    my $button = $self->{frame}->DateEntry(
        -textvariable => \$var,
        -daynames     => 'locale',
        #-arrowimage => 'calmonth16',
        -weekstart       => 1,
        -todaybackground => 'lightgreen',
        -parsecmd        => sub {
            Tpda3::Utils->dateentry_parse_date( 'iso', @_ );
        },
        -formatcmd => sub {
            my $date_str = Tpda3::Utils->dateentry_format_date( $date_format, @_ );
            $self->dentry_browse( $row, $col, $date_str );
        },
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
        -width              => $width,
        -relief             => 'raised',
    );
    return $button;
}

=head2 build_jcombobox

Build a JComboBox embeded widget.

=cut

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

=head jcombo_browse

Callback sub for the JComboBox embeded widget.

=cut

sub jcombo_browse {
    my ( $self, $r, $c, $jcb, $sel_index, $sel_name, $sel_value ) = @_;
    $self->set("$r,$c", $sel_value);
    return;
}

=head dentry_browse

Callback sub for the DateEntry embeded widget.

=cut

sub dentry_browse {
    my ( $self, $r, $c, $date_str ) = @_;
    $self->set("$r,$c", $date_str);
    return $date_str;
}

=head ckbutton_browse

Callback sub for the Checkbutton embeded widget.

=cut

sub ckbutton_browse {
    my ( $self, $r, $c ) = @_;
    my $value = $self->is_checked($r, $c) ? 1 : 0;
    $self->set("$r,$c", $value);
    return;
}

=head2 toggle_ckbutton

Toggle Checkbutton or set state to L<state> if defined state.

=cut

sub toggle_ckbutton {
    my ( $self, $r, $c, $state ) = @_;
    my ($w, $value);
    eval { $w = $self->windowCget( "$r,$c", -window ); };
    unless ($@) {
        if ( $w =~ /Checkbutton/i ) {
            if ( defined $state ) {
                $state ? $w->select : $w->deselect;
            }
            else {
                $state = $self->is_checked( $r, $c );
                $state ? $w->deselect : $w->select;
                $state = not $state;
            }
            $value = $self->is_checked($r, $c);
            $self->set("$r,$c", $value);
        }
    }
    return $value;
}

sub mouse_click_ckbutton {
    my ( $self, $r, $c ) = @_;
    my $w;
    eval { $w = $self->windowCget( "$r,$c", -window ); };
    unless ($@) {
        if ( $w =~ /Checkbutton/i ) {
            $w->eventGenerate('<ButtonPress-1>');
            $w->eventGenerate('<ButtonRelease-1>');
        }
    }
    return;
}

=head2 is_checked

Parameters: row, col.

Return true if a embedded CheckButton is checked.  Does not apply for
RadioButtons!

=cut

sub is_checked {
    my ( $self, $r, $c ) = @_;
    croak "is_checked: missing parameters \$r or/and \$c"
        unless defined $r and defined $c;
    my $is_checked = 0;
    my $bw;
    eval { $bw = $self->windowCget( "$r,$c", -window ); };
    unless ($@) {
        if ( $bw =~ /Checkbutton/i ) {
            my $w_var = $bw->cget('-variable');
            $is_checked = $$w_var ? $$w_var : 0;
        }
        # Radiobutton uses the global var $self->{tm_sel}
    }
    return $is_checked;
}

=head2 count_is_checked

Return how many buttons are checked.

=cut

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

=head2 activate_cell

Helper method for cell activation.  The parameters are the row and
the column.

=cut

sub activate_cell {
    my ($self, $row, $col) = @_;
    $self->activate("$row,$col");
    $self->see('active');
    return;
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

=cut
