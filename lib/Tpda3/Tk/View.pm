package Tpda3::Tk::View;

use strict;
use warnings;

use POSIX qw (floor);
use Log::Log4perl qw(get_logger);
use File::Spec::Functions qw(abs2rel catfile);

use Tk;
use Tk::widgets qw(NoteBook StatusBar Dialog DialogBox Checkbutton
    LabFrame MListbox JComboBox MsgBox);

use base 'Tk::MainWindow';

require Tpda3::Config;
require Tpda3::Utils;
require Tpda3::Tk::TB;    # ToolBar

=head1 NAME

Tpda3::Tk::App - Tk Perl application class

=head1 VERSION

Version 0.50

=cut

our $VERSION = 0.50;

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

    $self->{_tset}  = 0;                     # temporizer
    $self->{_model} = $model;

    $self->{_cfg} = Tpda3::Config->instance();

    $self->title(" Tpda3 ");

    # Load resource file, if found
    my $resource = catfile( $self->{_cfg}->cfetc, 'xresource.xrdb' );
    if ($resource) {
        if ( -f $resource ) {
            $self->log_msg("II: Reading resource from '$resource'");
            $self->optionReadfile( $resource, 'widgetDefault' );
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

    $self->{lookup}  = undef;    # info about list header
    $self->{nb_prev} = q{};
    $self->{nb_curr} = q{};

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

    # Show message in status bar
    my $so = $self->_model->get_stdout_observable;
    $so->add_callback( sub { $self->status_message( $_[0] ) } );

    # When the status changes, update gui components
    my $apm = $self->_model->get_appmode_observable;
    $apm->add_callback( sub { $self->update_gui_components(); } );

    # When the modified status changes, update statusbar
    my $svs = $self->_model->get_scrdata_rec_observable;
    $svs->add_callback( sub { $self->set_status( $_[0], 'ss' ) } );

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

    $self->set_status( $mode, 'md' );    # update statusbar

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
the window.  Fall back to default if no instance config yet.

=cut

sub set_geometry_main {
    my $self = shift;

    $self->_cfg->config_load_instance();

    my $geom;
    if ( $self->_cfg->can('geometry') ) {
        my $go = $self->_cfg->geometry();
        if (exists $go->{main}) {
            $geom = $go->{main};
        }
    }
    unless ($geom) {
        # Failed, set main geom from config
        $geom = $self->_cfg->cfgeom->{main};
    }

    $self->geometry($geom);

    return;
}

=head2 set_geometry

Set window geometry

=cut

sub set_geometry {
    my ( $self, $geom ) = @_;

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

    $self->make_menus( $attribs, 2 );    # Add starting with position = 2

    return;
}

=head2 make_menus

Make menus

=cut

sub make_menus {
    my ( $self, $attribs, $position ) = @_;

    $position = 1 if !$position;
    my $menus = Tpda3::Utils->sort_hash_by_id($attribs);

    #- Create menus
    foreach my $menu_name ( @{$menus} ) {

        $self->{_menu}{$menu_name} = $self->{_menu}->Menu( -tearoff => 0 );

        my @popups
            = sort { $a <=> $b } keys %{ $attribs->{$menu_name}{popup} };
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
        my @popups
            = sort { $a <=> $b } keys %{ $attribs->{$menu_name}{popup} };
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

=head2 set_menu_enable

Enable / disable menus.

=cut

sub set_menu_enable {
        my ( $self, $menu, $state ) = @_;

        $self->get_menu_popup_item($menu)->configure( -state => $state );

        return;
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
        -width      => 3,
        -relief     => 'sunken',
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

=head2 status_message

Message types:

=over

=item error  message with I<darkred> color

=item warn   message with I<yellow> color

=item info   message with I<darkgreen> color

=back

=cut

sub status_message {
    my ($self, $text) = @_;

    (my $type, $text) = split /#/, $text, 2;

    my $color;
  SWITCH: {
        $type eq 'error' && do { $color = 'darkred';   last SWITCH; };
        $type eq 'info'  && do { $color = 'darkgreen'; last SWITCH; };
        $type eq 'warn'  && do { $color = 'orange';    last SWITCH; };

        # Default
        $color = 'red';
    }

    $self->set_status( $text, 'ms', $color );

    return;
}

=head2 set_status

Display message in the status bar.  Colour name can also be passed to
the method in the message string separated by a # char.

=cut

sub set_status {
    my ( $self, $text, $sb_id, $color ) = @_;

    my $sb = $self->get_statusbar($sb_id);

    if ( $sb_id eq 'cn' ) {
        $sb->configure( -image => $text ) if defined $text;
    }
    elsif ( $sb_id eq 'ss' ) {
        my $str
            = !defined $text ? ''
            : $text          ? 'M'
            :                  'S';
        $sb->configure( -textvariable => \$str ) if defined $str;
    }
    else {
        $sb->configure( -textvariable => \$text ) if defined $text;
        $sb->configure( -foreground   => $color ) if defined $color;
        $self->temporized_clear($text) if $text and $sb_id eq 'ms';
    }

    return;
}

=head2 temporized_clear

Temporized clear for messages.

=cut

sub temporized_clear {
    my $self = shift;

    return if $self->{_tset} == 1;

    $self->after(
        50000,    # miliseconds
        sub {
            $self->set_status( '', 'ms' );
            $self->{_tset} = 0;
        }
    );

    $self->{_tset} = 1;

    return;
}

=head2 _create_toolbar

Create toolbar

=cut

sub _create_toolbar {
    my $self = shift;

    $self->{_tb} = $self->TB(qw/-movable 0 -side top -cursorcontrol 0/);

    my ( $toolbars, $attribs ) = $self->toolbar_names();

    $self->{_tb}->make_toolbar_buttons( $toolbars, $attribs );

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

    return ( $toolbars, $attribs );
}

=head2 create_notebook

Create the NoteBook and the 3 panes.  The pane first named 'rec'
contains widgets mostly of the type Entry, mapped to the fields of a
table.  The second pane contains a MListbox widget and is used for
listing the search results.  The third pane is for records from a
dependent table.

=cut

sub create_notebook {
    my ($self) = @_;    # , $det_page

    #- NoteBook

    $self->{_nb} = $self->NoteBook()->pack(
        -side   => 'top',
        -padx   => 3,
        -pady   => 3,
        -ipadx  => 6,
        -ipady  => 6,
        -fill   => 'both',
        -expand => 1,
    );

    #- Panels

    my $localized = $self->_cfg->localize->{notebook};
    $self->create_notebook_panel( 'rec', $localized->{lbl_record} );
    $self->create_notebook_panel( 'lst', $localized->{lbl_list} );

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
        -padx   => 5,
        -pady   => 5,
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
    my ( $self, $panel, $label ) = @_;

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
    my ( $self, $panel ) = @_;

    $self->{_nb}->delete($panel);

    return;
}

=head2 get_notebook

Return the notebook handler

=cut

sub get_notebook {
    my ( $self, $page ) = @_;

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

    my $nb = $self->get_notebook;

    return unless ref $nb;

    return $nb->raised();
}

=head2 set_nb_current

Save current notbook page.

=cut

sub set_nb_current {
    my ( $self, $page ) = @_;

    $self->{nb_prev} = $self->{nb_curr};    # previous tab name
    $self->{nb_curr} = $page;               # current tab name

    return;
}

=head2 get_nb_previous_page

NOTE: $nb->info('focusprev') doesn't work.

=cut

sub get_nb_previous_page {
    my $self = shift;

    return $self->{nb_prev};
}

=head2 notebook_page_clean

Clean a page of the Tk::NoteBook widget, remove all child widgets.

=cut

sub notebook_page_clean {
    my ( $self, $page ) = @_;

    my $frame = $self->get_notebook($page);

    $frame->Walk(
        sub {
            my $widget = shift;
            $widget->destroy;
        }
    );

    return;
}

=head2 nb_set_page_state

Enable/disable notebook pages.

=cut

sub nb_set_page_state {
    my ($self, $page, $state) = @_;

    $self->get_notebook()->pageconfigure( $page, -state => $state );

    return;
}

=head2 dialog_confirm

Confirmation dialog.

=cut

sub dialog_confirm {
    my ( $self, $message, $details ) = @_;

    # Not localisable button labels

    # my $dialog_q = $self->MsgBox(
    #     -title   => 'Question',
    #     -type    => 'yesnocancel',
    #     -icon    => 'question',
    #     -message => $message,
    #     -detail  => $details,
    # );

    # return $dialog_q->Show();

    my $locale_data = $self->_cfg->localize->{dialog};

    require Tpda3::Tk::Dialog::Message;
    my $dlg = Tpda3::Tk::Dialog::Message->new($locale_data);

    return $dlg->message_dialog($self, $message, $details);
}

=head2 dialog_info

Informations message dialog.

=cut

sub dialog_info {
    my ( $self, $message, $details ) = @_;

    my $dialog_i = $self->MsgBox(
        -title   => 'Info',
        -type    => 'ok',
        -icon    => 'info',
        -message => $message,
        -detail  => $details,
    );

    return $dialog_i->Show();
}

=head2 dialog_error

Error message dialog.

=cut

sub dialog_error {
    my ( $self, $message, $details ) = @_;

    my $dialog_e = $self->MsgBox(
        -title   => 'Info',
        -type    => 'ok',
        -icon    => 'error',
        -message => $message,
        -detail  => $details,
    );

    return $dialog_e->Show();
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
    my ( $self, $btn_name, $state ) = @_;

    $self->{_tb}->enable_tool( $btn_name, $state );

    return;
}

=head2 toggle_status_cn

Toggle the icon in the status bar

=cut

sub toggle_status_cn {
    my ( $self, $status ) = @_;

    if ($status) {
        $self->set_status( 'connectyes16', 'cn' );
        $self->set_status( $self->_cfg->connection->{dbname},
            'db', 'darkgreen' );
    }
    else {
        $self->set_status( 'connectno16', 'cn' );
        $self->set_status( '',            'db' );
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

sub get_geometry {
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
    my $self = shift;

    return $self->{_rc};
}

=head2 make_list_header

Prepare the header for list in the List tab.

=cut

sub make_list_header {
    my ( $self, $header_look, $header_cols, $fields ) = @_;

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
    my ( $self, $col, $colcnt ) = @_;

    # Label
    $self->get_recordlist->columnInsert( 'end', -text => $col->{label} );

    # Background
    $self->get_recordlist->columnGet($colcnt)->Subwidget('heading')
        ->configure( -background => 'tan' );

    # Width
    $self->get_recordlist->columnGet($colcnt)->Subwidget('heading')
        ->configure( -width => $col->{width} );

    # Sort order, (A)lpha is default
    if ( defined $col->{datatype} ) {
        if ( $col->{datatype} eq 'integer' or $col->{datatype} eq 'numeric' ) {
            $self->get_recordlist->columnGet($colcnt)
                ->configure( -comparecommand => sub { $_[0] <=> $_[1] } );
        }
    }
    else {
        print "WW: No 'datatype' attribute for '$col->{label}'\n";
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

Populate list with data from query result.

=cut

sub list_populate {
    my ( $self, $ary_ref ) = @_;

    return unless ref $ary_ref eq 'ARRAY';

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

    my $list = $self->get_recordlist();

    # Data
    foreach my $record ( @{$ary_ref} ) {
        $list->insert( 'end', $record );
        $list->see('end');
        $row_count++;
        $list->update;

        # Progress bar
        my $p = floor( $row_count * 10 / $record_count ) * 10;
        if ( $p % 10 == 0 ) { $self->{progres} = $p; }
    }

    # Activate and select last
    $list->selectionClear( 0, 'end' );
    $list->activate('end');
    $list->selectionSet('end');
    $list->see('active');
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
        $indecs = pop @selected;    # first row in case of multiselect
        if ( !defined $indecs ) {

            # Activate the last row
            $indecs = 'end';
            $self->get_recordlist->selectionClear( 0, 'end' );
            $self->get_recordlist->activate($indecs);
            $self->get_recordlist->selectionSet($indecs);
            $self->get_recordlist->see('active');
        }
    }

    # In scalar context, getRow returns the value of column 0
    my @idxs = @{ $self->{lookup} };    # indices for Pk and Fk cols
    my @returned;
    eval { @returned = ( $self->get_recordlist->getRow($indecs) )[@idxs]; };
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
    my ( $self, $pk_val, $fk_val ) = @_;

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
        my $indecs = pop @selected;    # first row in case of multiselect
        if ( defined $indecs ) {
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
    my ( $self, $pk_val, $fk_val ) = @_;

    my $pk_idx = $self->{lookup}[0];    # indices for Pk and Fk cols
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
                last;        # found!
            }
        }

        $i++;
    }

    return $idx;
}

=head2 event_handler_for_menu

Event handlers.

Configure callback for menu

=cut

sub event_handler_for_menu {
    my ( $self, $name, $calllback ) = @_;

    $self->get_menu_popup_item($name)->configure( -command => $calllback );

    return;
}

=head2 event_handler_for_tb_button

Event handlers.

Configure callback for toolbar button.

=cut

sub event_handler_for_tb_button {
    my ( $self, $name, $calllback ) = @_;

    $self->get_toolbar_btn($name)->configure( -command => $calllback );

    return;
}

=head2 list_control_choices

Configure choices.

=cut

sub list_control_choices {
    my ($self, $control, $choices) = @_;

    $control->removeAllItems();
    $control->configure( -choices => $choices );

    return;
}

=head2 control_write_e

Write to a Tk::Entry widget.  If I<$value> not true, than only delete.

=cut

sub control_write_e {
    my ( $self, $control_ref, $value, $state ) = @_;

    my $control = $control_ref->[1];

    $state = $state || $control->cget ('-state');

    $value = q{} unless defined $value;    # empty

    $control->configure( -state => 'normal' );

    $control->delete( 0, 'end' );
    $control->insert( 0, $value ) if defined $value;

    $control->configure( -state => $state );

    return;
}

=head2 control_write_t

Write to a Tk::Text widget.  If I<$value> not true, than only delete.

=cut

sub control_write_t {
    my ( $self, $control_ref, $value, $state ) = @_;

    my $control = $control_ref->[1];

    $state = $state || $control->cget ('-state');

    $value = q{} unless defined $value;    # Empty

    # Tip TextEntry 't'
    $control->delete( '1.0', 'end' );
    $control->insert( '1.0', $value ) if defined $value;

    $control->configure( -state => $state );

    return;
}

=head2 control_write_d

Write to a Tk::DateEntry widget.  If I<$value> not true, than only delete.

Date is required to come from the database in the ISO format.

=cut

sub control_write_d {
    my ( $self, $control_ref, $value, $state, $date_format ) = @_;

    my $control = $control_ref->[1];

    $state = $state || $control->cget('-state');

    $value = q{} unless defined $value;    # empty

    if ($value) {
        my ( $y, $m, $d )
            = Tpda3::Utils->dateentry_parse_date( 'iso', $value );
        $value
            = Tpda3::Utils->dateentry_format_date( $date_format, $y, $m, $d );
    }

    ${ $control_ref->[0] } = $value;

    $control->configure( -state => $state );

    return;
}

=head2 control_write_m

Write to a Tk::JComboBox widget.  If I<$value> not true, than only
delete.

=cut

sub control_write_m {
    my ( $self, $control_ref, $value, $state ) = @_;

    my $control = $control_ref->[1];

    $state = $state || $control->cget ('-state');

    if ($value) {
        $control->setSelected( $value, -type => 'value' );
    }
    else {
        ${ $control_ref->[0] } = q{};    # Empty
    }

    $control->configure( -state => $state );

    return;
}

=head2 control_write_c

Write to a Tk::Checkbox widget.

=cut

sub control_write_c {
    my ( $self, $control_ref, $value, $state ) = @_;

    my $control = $control_ref->[1];

    $state = $state || $control->cget ('-state');

    $value = 0 unless $value;
    if ( $value == 1 ) {
        $control->select;
    }
    else {
        $control->deselect;
    }

    $control->configure( -state => $state );

    return;
}

=head2 control_write_r

Write to a Tk::RadiobuttonGroup widget.

=cut

sub control_write_r {
    my ( $self, $control_ref, $value, $state ) = @_;

    my $control = $control_ref->[1];

    $state = $state || $control->cget('-state');

    if ($value) {
        ${ $control_ref->[0] } = $value;
    }
    else {
        ${ $control_ref->[0] } = undef;
    }

    $control->configure( -state => $state );

    return;
}

#-- Read

=head2 control_read_e

Read contents of a Tk::Entry control.

=cut

sub control_read_e {
    my ( $self, $control_ref ) = @_;

    return $control_ref->[1]->get;
}

=head2 control_read_t

Read contents of a Tk::Text control.

=cut

sub control_read_t {
    my ( $self, $control_ref ) = @_;

    return $control_ref->[1]->get( '0.0', 'end' );
}

=head2 control_read_d

Read contents of a Tk::DateEntry control.

=cut

sub control_read_d {
    my ( $self, $control_ref, $date_format ) = @_;

    my $control = $control_ref->[0];

    # Value from widget variable or the empty string
    my $value = ${$control} || q{};
    if ($value) {

        # Skip date formatting for find mode
        if ( !$self->_model->is_mode('find') ) {
            my ( $y, $m, $d )
                = Tpda3::Utils->dateentry_parse_date( $date_format, $value );
            if ( $y and $m and $d ) {
                $value = Tpda3::Utils->dateentry_format_date( 'iso', $y, $m,
                    $d );
            }
        }
    }

    return $value;
}

=head2 control_read_m

Read contents of a Tk::JComboBox control.

=cut

sub control_read_m {
    my ( $self, $control_ref ) = @_;

    my $control = $control_ref->[0];

    my $value = ${$control};    # value from variable

    return $value;
}

=head2 control_read_c

Read state of a Checkbox.

=cut

sub control_read_c {
    my ( $self, $control_ref ) = @_;

    my $control = $control_ref->[0];

    my $value = ${$control};

    return $value;
}

=head2 control_read_r

Read RadiobuttonGroup.

=cut

sub control_read_r {
    my ( $self, $control_ref ) = @_;

    my $control = $control_ref->[0];

    my $value = ${$control} || q{};

    return $value;
}

=head2 configure_controls

Enable / disable controls and set background color.

=cut

sub configure_controls {
    my ($self, $ctrl_ref, $ctrl_state, $bg_color) = @_;

    $ctrl_ref->configure( -state      => $ctrl_state, );
    $ctrl_ref->configure( -background => $bg_color, );

    return;
}

=head2 make_binding_entry

Key is always ENTER.

=cut

sub make_binding_entry {
    my ($self, $control, $key, $calllback) = @_;

    $control->bind( $key => $calllback, );

    return;
}

=head2 lookup_description

Dictionary lookup.

=cut

sub lookup_description {
    my ($self, $para) = @_;

    my $descr_caen = $self->_model->tbl_lookup_query($para);

    return $descr_caen->[0];
}

=head2 tbl_find_query

Call method in Model.

=cut

sub tbl_find_query {
    my ($self, $para, $debug) = @_;

    my ($ary_ref, $sql) = $self->_model->query_filter_find($para, $debug);

    return ($ary_ref, $sql);
}

=head2 tbl_find_query

Call method in Model.

=cut

sub tbl_count_query {
    my ($self, $para) = @_;

    my $records_count = $self->_model->query_records_count($para);

    return $records_count;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Tk::View
