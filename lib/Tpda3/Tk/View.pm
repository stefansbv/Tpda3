package Tpda3::Tk::View;

use strict;
use warnings;
use Carp;

use POSIX qw (floor);

use Log::Log4perl qw(get_logger);

use File::Spec::Functions qw(abs2rel catfile);
use Tk;
use Tk::widgets qw(NoteBook StatusBar Dialog DialogBox Checkbutton
                   LabFrame Listbox JComboBox);

# require Tk::ErrorDialog;

use base 'Tk::MainWindow';

use Tpda3::Config;
use Tpda3::Utils;
use Tpda3::Tk::TB; # ToolBar

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

    # Load resource file, if found
    my $resource = catfile($self->{_cfg}->cfetc, 'xresource.xrdb');
    if ($resource) {
        if (-f $resource) {
            $self->log_msg("II: Reading resource from '$resource'");
            $self->optionReadfile($resource, 'widgetDefault');
        }
        else {
            $self->log_msg("II: Resource not found: '$resource'");
        }
    }

    #-- Menu
    $self->_create_menu();
    $self->_create_app_menu();

    #-- ToolBar
    $self->_create_toolbar();

    #-- Statusbar
    $self->_create_statusbar();

    $self->_set_model_callbacks();

    $self->set_geometry_main();

    $self->define_dialogs();

    $self->{lookup} = undef;                 # info about list header

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
    $co->add_callback( sub { $self->toggle_status_cn( $_[0] ); } );

    my $so = $self->_model->get_stdout_observable;
    $so->add_callback( sub{ $self->set_status( $_[0], 'ms') } );

    # When the status changes, update gui components
    my $apm = $self->_model->get_appmode_observable;
    $apm->add_callback( sub { $self->update_gui_components(); } );

    # When the modified status changes, update statusbar
    my $svs = $self->_model->get_scrdata_rec_observable;
    $svs->add_callback( sub{ $self->set_status( $_[0], 'ss') } );

    return;
}

=head2 set_modified_record

Set modified to 1 if not already set but only if in I<edit> or I<add>
mode.

=cut

sub set_modified_record {
    my $self = shift;

    if (   $self->_model->is_mode('edit')
        or $self->_model->is_mode('add') )
    {
        $self->_model->set_scrdata_rec(1) if !$self->_model->is_modified;
    }

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
        $geom = '492x80+20+20';              # default
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

Log messages.

TODO: get_logger only once.

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
        -width      => 13,
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

    # Second label for modified status
    $self->{_sb}{ss} = $sb->addLabel(
        -width  => 3,
        -relief => 'sunken',
        -anchor     => 'center',
        -side       => 'right',
        -background => 'lightyellow',
    );

    # Mode
    $self->{_sb}{md} = $sb->addLabel(
        -width      => 4,
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
    elsif ( $sb_id eq 'ss' ) {
        #         _scrdata_rec       status text
        my $str = !defined $text   ? ''
                : $text            ? 'M'
                :                    'S';
        $sb->configure( -textvariable => \$str ) if defined $str;
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

    $self->{_tb} = $self->TB();

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
    my ($self) = @_;                         # , $det_page

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
     # $self->create_notebook_panel('det', 'Details') if $det_page;

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


=head2 remove_notebook_panel

Remove a NoteBook panel

=cut

sub remove_notebook_panel {
    my ($self, $panel) = @_;

    $self->{_nb}->delete($panel);

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

=head2 get_nb_current_page

Return the current page of the Tk::NoteBook widget.

=cut

sub get_nb_current_page {
    my $self = shift;

    return $self->get_notebook->raised();
}

=head2 notebook_page_clean

Clean a page of the Tk::NoteBook widget, remove all child widgets.

=cut

sub notebook_page_clean {
    my ($self, $page) = @_;

    my $frame = $self->get_notebook($page);

    $frame->Walk(
        sub {
            my $widget = shift;
            $widget->destroy;
        }
    );

    return;
}

=head2 define_dialogs

Define some dialogs

=cut

sub define_dialogs {
    my $self = shift;

    $self->{dialog1} = $self->Dialog(
        -text           => 'Nothing to search for!',
        -bitmap         => 'info',
        -title          => 'Info',
        -default_button => 'Ok',
        -buttons        => [qw/Ok/]
    );

    $self->{dialog2} = $self->Dialog(
        -text           => 'Add record?',
        -bitmap         => 'question',
        -title          => 'Insert record',
        -default_button => 'Ok',
        -buttons        => [qw/Ok Cancel/]
    );

    # $self->{asksave} = $self->DialogBox(
    #     -title   => 'Save?',
    #     -buttons => [qw{Yes No Cancel}],
    # );
    # $self->{asksave}->geometry('400x300');
    # $self->{asksave}->bind(
    #     '<Escape>',
    #     sub { $self->{asksave}->Subwidget('B_Cancel')->invoke }
    # );

    # # Nice trick to position buttons to the right
    # # Source: PM by lamprecht on Apr 22, 2011 at 22:09 UTC
    # my $bframe = $self->{asksave}->Subwidget('bottom');
    # for ($bframe->children) {
    #     $_->packForget;
    #     $_->pack(-side => 'right',
    #              -padx => 3,
    #              -pady => 3,
    #          );
    # }

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

Prepare the header for list in the List tab.

=cut

sub make_list_header {
    my ($self, $header_look, $header_cols, $fields) = @_;

    #- Delete existing columns
    $self->get_recordlist->selectionClear( 0, 'end' );
    $self->get_recordlist->columnDelete( 0, 'end' );

    #- Make header
    $self->{lookup} = [];
    my $colcnt = 0;

    #-- For lookup columns

    foreach my $col ( @{$header_look} ) {
        $self->list_header( $fields->{$col}, $colcnt );

        # Save index of columns to return
        push @{ $self->{lookup} }, $colcnt;

        $colcnt++;
    }

    #-- For the rest of the columns

    foreach my $col ( @{$header_cols} ) {
        $self->list_header( $fields->{$col}, $colcnt );
        $colcnt++;
    }

    return;
}

=head2 list_header

Make header for the list in the List tab.

=cut

sub list_header {
    my ($self, $col, $colcnt) = @_;

    # Label
    $self->get_recordlist->columnInsert( 'end', -text => $col->{label} );

    # Background
    $self->get_recordlist->columnGet($colcnt)->Subwidget('heading')
        ->configure( -background => 'tan' );

    # Width
    $self->get_recordlist->columnGet($colcnt)->Subwidget('heading')
        ->configure( -width => $col->{width} );

    # Sort order, (A)lpha is default
    if ( defined $col->{order} ) {
        if ( $col->{order} eq 'N' ) {
            $self->get_recordlist->columnGet($colcnt)
                ->configure( -comparecommand => sub { $_[0] <=> $_[1] } );
        }
    }
    else {
        print "WW: No sort option for '$col'\n";
    }

    return;
}

=head2 list_init

Delete the rows of the list.

=cut

sub list_init {
    my $self = shift;

    $self->get_recordlist->selectionClear( 0, 'end' );
    $self->get_recordlist->delete( 0, 'end' );

    return;
}

=head2 list_populate

Polulate list with data from query result.

=cut

sub list_populate {
    my ( $self, $ary_ref ) = @_;

    my $row_count;

    if ( Exists( $self->get_recordlist ) ) {
        eval { $row_count = $self->get_recordlist->size(); };
        if ($@) {
            warn "Error: $@";
            $row_count = 0;
        }
    }
    else {
        warn "No MList!\n";
        return;
    }

    my $record_count = scalar @{$ary_ref};

    # Data
    foreach my $record ( @{$ary_ref} ) {
        $self->get_recordlist->insert( 'end', $record );
        $self->get_recordlist->see('end');
        $row_count++;
        $self->set_status("$row_count records fetched", 'ms');
        $self->get_recordlist->update;

        # Progress bar
        my $p = floor( $row_count * 10 / $record_count ) * 10;
        if ( $p % 10 == 0 ) { $self->{progres} = $p; }
    }

    $self->set_status("$row_count records listed", 'ms');

    # Activate and select last
    $self->get_recordlist->selectionClear( 0, 'end' );
    $self->get_recordlist->activate('end');
    $self->get_recordlist->selectionSet('end');
    $self->get_recordlist->see('active');
    $self->{progres} = 0;

    return $record_count;
}

=head2 list_raise

Raise I<List> tab and set focus to list.

=cut

sub list_raise {
    my $self = shift;

    $self->{_nb}->raise('lst');
    $self->get_recordlist->focus;

    return;
}

=head2 has_list_records

Return number of records from list.

=cut

sub has_list_records {
    my $self = shift;

    my $row_count;

    if ( Exists( $self->get_recordlist ) ) {
        eval { $row_count = $self->get_recordlist->size(); };
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
        # No records
        return;
    }

    my @selected;
    my $indecs;

    eval { @selected = $self->get_recordlist->curselection(); };
    if ($@) {
        warn "Error: $@";
        # $self->refresh_sb( 'll', 'No record selected' );
        return;
    }
    else {
        $indecs = pop @selected; # first row in case of multiselect
        if (!defined $indecs) {
            # Activate the last row
            $indecs = 'end';
            $self->get_recordlist->selectionClear( 0, 'end' );
            $self->get_recordlist->activate($indecs);
            $self->get_recordlist->selectionSet($indecs);
            $self->get_recordlist->see('active');
        }
    }

    # In scalar context, getRow returns the value of column 0
    my @idxs = @{ $self->{lookup} };      # indices for Pk and Fk cols
    my @returned;
    eval {
        @returned = ( $self->get_recordlist->getRow($indecs) )[@idxs];
    };
    if ($@) {
        warn "Error: $@";
        # $self->refresh_sb( 'll', 'No record selected!' );
        return;
    }
    else {
        @returned = Tpda3::Utils->trim(@returned) if @returned;
    }

    return \@returned;
}

=head2 list_remove_selected

Remove the selected row from the list.

First it compares the Pk and the Fk values from the screen, with the
selected row contents in the list.

=cut

sub list_remove_selected {
    my ($self, $pk_val, $fk_val) = @_;

    my $sel = $self->list_read_selected();
    if ( !ref $sel ) {
        print "EE: Nothing selected!, use brute force? :)\n";
        return;
    }

    my $fk_idx = $self->{lookup}[1];

    my $found;
    if ( $sel->[0] eq $pk_val ) {

        # Check fk, if defined
        if ( defined $fk_idx ) {
            $found = 1 if $sel->[1] eq $fk_val;
        }
        else {
            $found = 1;
        }
    }
    else {
        print "EE: No matching list row!\n";
        return;
    }

    #- OK, found, delete from list

    my @selected;
    eval { @selected = $self->get_recordlist->curselection(); };
    if ($@) {
        warn "Error: $@";
        # $self->refresh_sb( 'll', 'No record selected' );
        return;
    }
    else {
        my $indecs = pop @selected; # first row in case of multiselect
        if (defined $indecs) {
            $self->get_recordlist->delete($indecs);
        }
        else {
            print "EE: Nothing selected!\n";
        }
    }

    return;
}

=head2 list_locate

This should be never needed and is not used.  Using brute force to
locate the record in the list. ;)

=cut

sub list_locate {
    my ($self, $pk_val, $fk_val) = @_;

    my $pk_idx = $self->{lookup}[0];      # indices for Pk and Fk cols
    my $fk_idx = $self->{lookup}[1];
    my $idx;

    my @returned = $self->get_recordlist->get( 0, 'end' );
    my $i = 0;
    foreach my $rec (@returned) {
        if ( $rec->[$pk_idx] eq $pk_val ) {

            # Check fk, if defined
            if ( defined $fk_idx ) {
                if ( $rec->[$fk_idx] eq $fk_val ) {
                    $idx = $i;
                    last;    # found!
                }
            }
            else {
                $idx = $i;
                last;    # found!
            }
        }

        $i++;
    }

    return $idx;
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

1;    # End of Tpda3::Tk::View
