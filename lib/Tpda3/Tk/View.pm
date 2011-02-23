package Tpda3::Tk::View;

use strict;
use warnings;

use Carp;
use POSIX qw (floor);

use Log::Log4perl qw(get_logger);

use File::Spec::Functions qw(abs2rel);
use Tk;
use Tk::widgets qw(NoteBook StatusBar Dialog Checkbutton
                   LabFrame MListbox JComboBox Font);

# require Tk::ErrorDialog;

use base 'Tk::MainWindow';

use Tpda3::Config;
use Tpda3::Utils;
use Tpda3::Tk::ToolBar;

=head1 NAME

Tpda3::Tk::App - Tk Perl application class

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Tk::Notebook;

    $self->{_nb} = Tpda3::Tk::Notebook->new( $gui );

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;
    my $model = shift;

    #- The MainWindow

    my $self = __PACKAGE__->SUPER::new(@_);

    $self->{_model} = $model;

    $self->{_cfg} = Tpda3::Config->instance();

    $self->title(" Tpda3 ");
    $self->optionReadfile('./xresource.xrdb', 'userDefault');

    #-- Menu
    $self->_create_menu();
    $self->_create_app_menu();

    #-- ToolBar
    $self->_create_toolbar();

    #-- Statusbar
    $self->_create_statusbar();

    $self->_set_model_callbacks();

    $self->set_geometry_main();

    return $self;
}

=head2 _model

Return model instance

=cut

sub _model {
    my $self = shift;

    return $self->{_model};
}

=head2 _cfg

Return config instance variable

=cut

sub _cfg {
    my $self = shift;

    return $self->{_cfg};
}

=head2 _set_model_callbacks

Define the model callbacks

=cut

sub _set_model_callbacks {
    my $self = shift;

    my $co = $self->_model->get_connection_observable;
    $co->add_callback(
        sub {
            $self->toggle_status_cn( $_[0] );
        }
    );

    my $so = $self->_model->get_stdout_observable;
    $so->add_callback( sub{ $self->set_status( $_[0], 'ms') } );

    # When the status changes, update gui components
    my $apm = $self->_model->get_appmode_observable;
    $apm->add_callback(
        sub { $self->update_gui_components(); } );

    return;
}

=head2 update_gui_components

When the application status (mode) changes, update gui components.
Screen controls (widgets) are not handled here, but in controller
module.

=cut

sub update_gui_components {
    my $self = shift;

    my $mode = $self->_model->get_appmode();

    $self->set_status($mode, 'md');          # update statusbar

    SWITCH: {
          $mode eq 'find' && do {
              $self->{_tb}->toggle_tool_check( 'tb_ad', 0 );
              $self->{_tb}->toggle_tool_check( 'tb_fm', 1 );
              last SWITCH;
          };
          $mode eq 'add' && do {
              $self->{_tb}->toggle_tool_check( 'tb_ad', 1 );
              $self->{_tb}->toggle_tool_check( 'tb_fm', 0 );
              last SWITCH;
          };

          # Else
          $self->{_tb}->toggle_tool_check( 'tb_ad', 0 );
          $self->{_tb}->toggle_tool_check( 'tb_fm', 0 );
      }

    return;
}

=head2 set_geometry_main

Set main window geometry.  Load instance config, than set geometry for
the window.  Fall back to a hardwired default if no instance config
yet.

=cut

sub set_geometry_main {
    my $self = shift;

    $self->_cfg->config_load_instance();

    my $geom;
    if ( $self->_cfg->can('geometry') ) {
        $geom = $self->_cfg->geometry->{'main'};
    }
    else {
        $geom = '492x80+100+100';            # default
    }

    $self->geometry($geom);

    return;
}

=head2 set_geometry

Set window geometry

=cut

sub set_geometry {
    my ($self, $geom) = @_;

    $self->geometry($geom);

    return;
}

=head2 log_msg

Log messages

=cut

sub log_msg {
    my ( $self, $msg ) = @_;

    my $log = get_logger();

    $log->info($msg);

    return;
}

=head2 _create_menu

Create the menu

=cut

sub _create_menu {
    my $self = shift;

    #- Menu bar

    $self->{_menu} = $self->Menu();

    # Get MenuBar atributes

    my $attribs = $self->_cfg->menubar;

    $self->make_menus($attribs);

    $self->configure( -menu => $self->{_menu} );

    return;
}

sub _create_app_menu {
    my $self = shift;

    my $attribs = $self->_cfg->appmenubar;

    $self->make_menus($attribs, 2);   # Add starting with position = 2

    return;
}

=head2 make_menus

Make menus

=cut

sub make_menus {
    my ($self, $attribs, $position) = @_;

    $position = 1 if ! $position;
    my $menus = Tpda3::Utils->sort_hash_by_id($attribs);

    #- Create menus
    foreach my $menu_name ( @{$menus} ) {

        $self->{_menu}{$menu_name} = $self->{_menu}->Menu( -tearoff => 0 );

        my @popups = sort { $a <=> $b } keys %{ $attribs->{$menu_name}{popup} };
        foreach my $id (@popups) {
            $self->make_popup_item(
                $self->{_menu}{$menu_name},
                $attribs->{$menu_name}{popup}{$id},
            );
        }

        $self->{_menu}->insert(
            $position,
            'cascade',
            -menu      => $self->{_menu}{$menu_name},
            -label     => $attribs->{$menu_name}{label},
            -underline => $attribs->{$menu_name}{underline},
        );

        $position++;
    }

    return;
}

=head2 get_app_menus_list

Get application menus list, needed for binding the command to load the
screen.  We only need the name of the popup which is also the name of
the screen (and also the name of the module).

=cut

sub get_app_menus_list {
    my $self = shift;

    my $attribs = $self->_cfg->appmenubar;
    my $menus   = Tpda3::Utils->sort_hash_by_id($attribs);

    my @menulist;
    foreach my $menu_name ( @{$menus} ) {
        my @popups = sort { $a <=> $b } keys %{ $attribs->{$menu_name}{popup} };
        foreach my $item (@popups) {
            push @menulist, $attribs->{$menu_name}{popup}{$item}{name};
        }
    }

    return \@menulist;
}

=head2 make_popup_item

Make popup item

=cut

sub make_popup_item {
    my ( $self, $menu, $item ) = @_;

    $menu->add('separator') if $item->{sep} eq 'before';

    $self->{_menu}{ $item->{name} } = $menu->command(
        -label       => $item->{label},
        -accelerator => $item->{key},
        -underline   => $item->{underline},
    );

    $menu->add('separator') if $item->{sep} eq 'after';

    return;
}

=head2 get_menu_popup_item

Return a menu popup by name

=cut

sub get_menu_popup_item {
    my ( $self, $name ) = @_;

    return $self->{_menu}{$name};
}

=head2 create_statusbar

Create the status bar

=cut

sub _create_statusbar {
    my $self = shift;

    my $sb = $self->StatusBar();

    # Dummy label for left space
    my $ldumy = $sb->addLabel(
        -width  => 1,
        -relief => 'flat',
    );

    # First label for various messages
    $self->{_sb}{ms} = $sb->addLabel( -relief => 'flat' );

    # Connection icon
    $self->{_sb}{cn} = $sb->addLabel(
        -width  => 20,
        -relief => 'raised',
        -anchor => 'center',
        -side   => 'right',
    );

    # Database name
    $self->{_sb}{db} = $sb->addLabel(
        -width      => 15,
        -anchor     => 'center',
        -side       => 'right',
        -background => 'lightyellow',
    );

    # Progress
    $self->{progres} = 0;
    $self->{_sb}{pr} = $sb->addProgressBar(
        -length     => 100,
        -from       => 0,
        -to         => 100,
        -variable   => \$self->{progres},
        -foreground => 'blue',
    );

    # Mode
    $self->{_sb}{md} = $sb->addLabel(
        -width      => 6,
        -anchor     => 'center',
        -side       => 'right',
        -foreground => 'blue',
        -background => 'lightyellow',
    );

    return;
}

=head2 get_statusbar

Return the status bar handler

=cut

sub get_statusbar {
    my ( $self, $sb_id ) = @_;

    return $self->{_sb}{$sb_id};
}

=head2 set_status

Set message to status bar

=cut

sub set_status {
    my ( $self, $text, $sb_id, $color ) = @_;

    my $sb = $self->get_statusbar($sb_id);

    if ( $sb_id eq 'cn' ) {
        $sb->configure( -image => $text ) if defined $text;
    }
    else {
        $sb->configure( -textvariable => \$text ) if defined $text;
        $sb->configure( -foreground   => $color ) if defined $color;
    }

    return;
}

=head2 _create_toolbar

Create toolbar

=cut

sub _create_toolbar {
    my $self = shift;

    $self->{_tb} = Tpda3::Tk::ToolBar->new($self);

    my ($toolbars, $attribs) = $self->toolbar_names();

    $self->{_tb}->make_toolbar_buttons($toolbars, $attribs);

    return;
}

=head2 toolbar_names

Get Toolbar names as array reference from config.

=cut

sub toolbar_names {
    my $self = shift;

    # Get ToolBar button atributes
    my $attribs = $self->_cfg->toolbar;

    # TODO: Change the config file so we don't need this sorting anymore
    # or better keep them sorted and ready to use in config
    my $toolbars = Tpda3::Utils->sort_hash_by_id($attribs);

    return ($toolbars, $attribs);
}

=head2 create_notebook

Create the NoteBook and the 3 panes.  The pane first named 'rec'
contains widgets mostly of the type Entry, mapped to the fields of a
table.  The second pane contains a MListbox widget and is used for
listing the search results.  The third pane is for records from a
dependent table.

=cut

sub create_notebook {
    my $self = shift;

    #- NoteBook

    $self->{_nb} = $self->NoteBook()->pack(
        -side   => 'top',
        -padx   => 3, -pady   => 3,
        -ipadx  => 6, -ipady  => 6,
        -fill   => 'both',
        -expand => 1,
    );

    #- Panels

    $self->create_notebook_panel('rec', 'Record');
    $self->create_notebook_panel('lst', 'List');
    # $self->create_notebook_panel('det', 'Details');

    # Frame box
    my $frm_box = $self->{_nb}{lst}->LabFrame(
        -foreground => 'blue',
        -label      => 'Search results',
        -labelside  => 'acrosstop'
    )->pack( -expand => 1, -fill => 'both' );

    $self->{_rc} = $frm_box->Scrolled(
        'MListbox',
        -scrollbars         => 'osoe',
        -background         => 'white',
        -textwidth          => 10,
        -highlightthickness => 2,
        -width              => 0,
        -selectmode         => 'browse',
        -relief             => 'sunken',
        -columns            => [ [qw/-text Nul -textwidth 10/] ]
    );

    $self->{_rc}->pack( -expand => 1, -fill => 'both' );

    $self->{_nb}->pack(
        -side   => 'top',
        -fill   => 'both',
        -padx   => 5, -pady   => 5,
        -expand => 1,
    );

    # Initialize
    $self->{_nb}->raise('rec');

    return;
}

=head2 create_notebook_panel

Create a NoteBook panel

=cut

sub create_notebook_panel {
    my ($self, $panel, $label) = @_;

    $self->{_nb}{$panel} = $self->{_nb}->add(
        $panel,
        -label     => $label,
        -underline => 0,
    );

    return;
}

=head2 get_notebook

Return the notebook handler

=cut

sub get_notebook {
    my ($self, $page) = @_;

    if ($page) {
        return $self->{_nb}{$page};
    }
    else {
        return $self->{_nb};
    }
}

=head2 destroy_notebook

Destroy existing window, before the creation of an other.

=cut

sub destroy_notebook {
    my $self = shift;

    $self->{_nb}->destroy if Tk::Exists( $self->{_nb} );

    return;
}

=head2 get_toolbar_btn

Return a toolbar button when we know the its name

=cut

sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{_tb}->get_toolbar_btn($name);
}

=head2 enable_tool

Toggle tool bar button.  If state is defined then set to state do not
toggle.

State can come as 0 | 1 and normal | disabled.

=cut

sub enable_tool {
    my ($self, $btn_name, $state) = @_;

    $self->{_tb}->enable_tool($btn_name, $state);

    return;
}

=head2 toggle_status_cn

Toggle the icon in the status bar

=cut

sub toggle_status_cn {
    my ($self, $status) = @_;

    if ($status) {
        $self->set_status('connectyes16','cn');
        $self->set_status($self->_cfg->connection->{dbname},'db','darkgreen');
    }
    else {
        $self->set_status('connectno16','cn');
        $self->set_status('','db');
    }

    return;
}

=head2 on_quit

Destroy window on quit

=cut

sub on_quit {
    my $self = shift;

    $self->destroy();

    return;
}

=head2 w_geometry

Return window geometry

=cut

sub w_geometry {
    my $self = shift;

    my $wsys = $self->windowingsystem;
    my $name = $self->name;
    my $geom = $self->geometry;

    # All dimensions are in pixels.
    my $sh = $self->screenheight;
    my $sw = $self->screenwidth;

    print "\nSystem   = $wsys\n";
    print "Name     = $name\n";
    print "Geometry = $geom\n";
    print "Screen   = $sw x $sh\n";

    return $geom;
}

=head2 get_recordlist

Return the record list handler

=cut

sub get_recordlist {
    my $self  = shift;

    return $self->{_rc};
}

=head2 make_list_header

Make header for list

=cut

sub make_list_header {
    my ($self, $header_cols, $header_attr) = @_;

    # Delete existing columns
    $self->{_rc}->selectionClear( 0, 'end' );
    $self->{_rc}->columnDelete( 0, 'end' );

    # Header
    my $colcnt = 0;
    foreach my $col ( @{$header_cols} ) {
        my $attr = $header_attr->{$col};

        $self->{_rc}->columnInsert( 'end', -text => $attr->{label} );
        $self->{_rc}->columnGet($colcnt)
            ->Subwidget('heading')
            ->configure( -background => 'tan' );
        $self->{_rc}->columnGet($colcnt)
            ->Subwidget('heading')
            ->configure( -width => $attr->{width} );
        if ( defined $attr->{order} ) {
            if ($attr->{order} eq 'N') {
                $self->{_rc}->columnGet($colcnt)
                    ->configure( -comparecommand => sub { $_[0] <=> $_[1]} );
            }
        }
        else {
            warn " Warning: no sort option for '$col'\n";
        }

        $colcnt++;
    }

    return;
}

=head2 list_init

Delete the rows of the list.

=cut

sub list_init {
    my $self = shift;

    $self->{_rc}->selectionClear( 0, 'end' );
    $self->{_rc}->delete( 0, 'end' );

    return;
}

=head2 list_populate

Polulate list with data from query result.

=cut

sub list_populate {
    my ( $self, $paramdata ) = @_;

    my $row_count;

    if ( Exists( $self->{_rc} ) ) {
        eval { $row_count = $self->{_rc}->size(); };
        if ($@) {
            warn "Error: $@";
            $row_count = 0;
        }
    }
    else {
        warn "No MList!\n";
        return;
    }

    my $ary_ref = $self->_model->query_records_find($paramdata);
    my $record_count = scalar @{$ary_ref};

    # Data
    foreach my $record ( @{$ary_ref} ) {
        $self->{_rc}->insert( 'end', $record );
        $self->{_rc}->see('end');
        $row_count++;
        $self->set_status("$row_count records fetched", 'ms');
        $self->{_rc}->update;

        # Progress bar
        my $p = floor( $row_count * 10 / $record_count ) * 10;
        if ( $p % 10 == 0 ) { $self->{progres} = $p; }
    }

    $self->set_status("$row_count records listed", 'ms');

    # Activate and select last
    $self->{_rc}->selectionClear( 0, 'end' );
    $self->{_rc}->activate('end');
    $self->{_rc}->selectionSet('end');
    $self->{_rc}->see('active');
    $self->{progres} = 0;

    # Raise List tab if found
    if ($record_count > 0) {
        $self->{_nb}->raise('lst');
    }

    return $record_count;
}

=head2 has_list_records

Return number of records from list.

=cut

sub has_list_records {
    my $self = shift;

    my $row_count;

    if ( Exists( $self->{_rc} ) ) {
        eval { $row_count = $self->{_rc}->size(); };
        if ($@) {
            warn "Error: $@";
            $row_count = 0;
        }
    }
    else {
        warn "Error, List doesn't exists?\n";
        $row_count = 0;
    }

    return $row_count;
}

=head2 list_read_selected

Read and return selected row (column 0) from list

=cut

sub list_read_selected {
    my $self = shift;

    if ( !$self->has_list_records ) {
        warn "No records!\n";
        return;
    }

    my (@selected, $sel);
    eval { @selected = $self->{_rc}->curselection(); };
    if ($@) {
        warn "Error: $@";
        # $self->refresh_sb( 'll', 'No record selected' );
        return;
    }
    else {

        # Default to the first row
        $sel = pop @selected;
        if ($sel) {
            unless ( $sel > 0 ) {

                # print "Prima inregistrare\n";
                $sel = 0;

                # Selecteaza si activeaza
                $self->{_rc}->selectionClear( 0, 'end' );
                $self->{_rc}->activate(0);
                $self->{_rc}->selectionSet(0);
                $self->{_rc}->see('active');
            }
        }
    }

    # In scalar context, getRow returns the value of column 0
    # Column 0 has to be a Pk ...
    my $selected_value;
    eval { $selected_value = $self->{_rc}->getRow($sel); };
    if ($@) {
        warn "Error: $@";
        # $self->refresh_sb( 'll', 'No record selected!' );
        return;
    }
    else {

        # Trim spaces
        if ( defined($selected_value) ) {
            $selected_value =~ s/^\s+//;
            $selected_value =~ s/\s+$//;
        }
    }

    print "selected_value is $selected_value\n";
    return $selected_value;
}

=head2 make_tablematrix_header

Write header on row 0 of TableMatrix

=cut

sub make_tablematrix_header {
    my ($self, $tm_table, $tm_fields) = @_;

    # Set TableMatrix tags
    my $cols = scalar keys %{$tm_fields};
    $self->set_tablematrix_tags( $tm_table, $cols, $tm_fields );

    return;
}

=head2 set_tablematrix_tags

Set tags for the table matrix.

=cut

sub set_tablematrix_tags {
    my ($self, $xtable, $cols, $tm_fields) = @_;

    # TM is SpreadsheetHideRows type increase cols number with 1
    $cols += 1 if $xtable =~ m/SpreadsheetHideRows/;

    # Tags for the detail data:
    $xtable->tagConfigure(
        'detail',
        -bg     => 'darkseagreen2',
        -relief => 'sunken',
    );
    $xtable->tagConfigure(
        'detail2',
        -bg     => 'burlywood2',
        -relief => 'sunken',
    );
    $xtable->tagConfigure(
        'detail3',
        -bg     => 'lightyellow',
        -relief => 'sunken',
    );

    $xtable->tagConfigure(
        'expnd',
        -bg     => 'grey85',
        -relief => 'raised',
    );
    $xtable->tagCol( 'expnd', 0 );

    # Make enter do the same thing as return:
    $xtable->bind( '<KP_Enter>', $xtable->bind('<Return>') );

    if ($cols) {
        $xtable->configure( -cols => $cols );
        $xtable->configure( -rows => 1 ); # Keep table dim in grid
    }
    $xtable->tagConfigure(
        'active',
        -bg     => 'lightyellow',
        -relief => 'sunken',
    );
    $xtable->tagConfigure(
        'title',
        -bg     => 'tan',
        -fg     => 'black',
        -relief => 'raised',
        -anchor => 'n',
    );
    $xtable->tagConfigure( 'find_left', -anchor => 'w', -bg => 'lightgreen' );
    $xtable->tagConfigure(
        'find_center',
        -anchor => 'n',
        -bg     => 'lightgreen',
    );
    $xtable->tagConfigure(
        'find_right',
        -anchor => 'e',
        -bg     => 'lightgreen',
    );
    $xtable->tagConfigure('ro_left'     , -anchor => 'w', -bg => 'lightgrey');
    $xtable->tagConfigure('ro_center'   , -anchor => 'n', -bg => 'lightgrey');
    $xtable->tagConfigure('ro_right'    , -anchor => 'e', -bg => 'lightgrey');
    $xtable->tagConfigure('enter_left'  , -anchor => 'w', -bg => 'white');
    $xtable->tagConfigure('enter_center', -anchor => 'n', -bg => 'white');
    $xtable->tagConfigure(
        'enter_center_blue',
        -anchor => 'n',
        -bg     => 'lightblue',
    );
    $xtable->tagConfigure( 'enter_right', -anchor => 'e', -bg => 'white' );
    $xtable->tagConfigure( 'find_row', -bg => 'lightgreen' );

    # TableMatrix header, Set Name, Align, Width
    foreach my $field ( keys %{$tm_fields} ) {
        my $col = $tm_fields->{$field}{id};
        $xtable->tagCol( $tm_fields->{$field}{tag}, $col );
        $xtable->colWidth( $col, $tm_fields->{$field}{width} );
        $xtable->set( "0,$col", $tm_fields->{$field}{label} );

        my $xtvar  = $xtable->cget( -variable );
    }

    $xtable->tagRow( 'title', 0 );
    if ( $xtable->tagExists('expnd') ) {
        # Change the tag priority
        $xtable->tagRaise( 'expnd', 'title' );
    }

    return;
}

# sub Tk::Error {
#     my ($widget, $error, @where) = @_;

#     croak("$widget, $error"); # , @where
# }

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Tk::View
