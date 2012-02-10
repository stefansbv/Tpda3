package Tpda3::Wx::View;

use strict;
use warnings;

use Carp;
use POSIX qw (floor ceil);

use Log::Log4perl qw(get_logger);

use File::Spec::Functions qw(abs2rel);
use Wx qw{:everything};
use Wx::Perl::ListCtrl;

use base 'Wx::Frame';

use Tpda3::Config;
use Tpda3::Utils;
use Tpda3::Wx::Notebook;
use Tpda3::Wx::ToolBar;

=head1 NAME

Tpda3::Wx::App - Wx Perl application class

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Tpda3::Wx::View;

    $self->{_view} = TpdaQrt::Wx::View->new(
        $model, undef, -1, 'TpdaQrt::wxPerl',
        [ -1, -1 ],
        [ -1, -1 ],
        wxDEFAULT_FRAME_STYLE,
    );

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;
    my $model = shift;

    #- The Frame

    my $self = __PACKAGE__->SUPER::new(@_);

    Wx::InitAllImageHandlers();

    $self->{_model} = $model;

    $self->{_cfg} = Tpda3::Config->instance();

    $self->SetMinSize( Wx::Size->new( 480, 300 ) );
    $self->SetIcon( Wx::GetWxPerlIcon() );

    my $log = get_logger();

    #-- Menu
    $self->_create_menu();
    $self->_create_app_menu();

    #-- ToolBar
    $self->_create_toolbar();

    #-- Statusbar
    $self->_create_statusbar();

    $self->_set_model_callbacks();

    $self->Fit;

    $log->trace('Frame created');

    return $self;
}

=head2 _model

Return model instance

=cut

sub _model {
    my $self = shift;

    $self->{_model};
}

=head2 _cfg

Return config instance variable

=cut

sub _cfg {
    my $self = shift;

    return $self->{_cfg};
}

=head2 _set_model_callbacks

Define the model callbacks.

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
    $so->add_callback( sub { $self->set_status( $_[0], 'ms' ) } );

    # When the status changes, update gui components
    my $apm = $self->_model->get_appmode_observable;
    $apm->add_callback( sub { $self->update_gui_components(); } );

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

=head2 _create_menu

Create the menubar and the menus. Menus are defined in configuration
files.

=cut

sub _create_menu {
    my $self = shift;

    my $menu = Wx::MenuBar->new;

    $self->{_menu} = $menu;

    $self->make_menus( $self->_cfg->menubar );

    $self->SetMenuBar($menu);

    return;
}

=head2 _create_app_menu

Insert application menu. The menubars are inserted after the first
item of the default menu.

=cut

sub _create_app_menu {
    my $self = shift;

    my $attribs = $self->_cfg->appmenubar;

    $self->make_menus( $attribs, 1 );    # insert starting with position 1

    return;
}

=head2 make_menus

Make menus.

=cut

sub make_menus {
    my ( $self, $attribs, $position ) = @_;

    $position = $position ||= 0;    # default

    my $menus = Tpda3::Utils->sort_hash_by_id($attribs);

    #- Create menus
    foreach my $menu_name ( @{$menus} ) {

        $self->{$menu_name} = Wx::Menu->new();

        my @popups
            = sort { $a <=> $b } keys %{ $attribs->{$menu_name}{popup} };
        foreach my $id (@popups) {
            $self->make_popup_item(
                $self->{$menu_name},
                $attribs->{$menu_name}{popup}{$id},
                $attribs->{$menu_name}{id} . $id,    # menu Id
            );
        }

        $self->{_menu}->Insert(
            $position,
            $self->{$menu_name},
            Tpda3::Utils->ins_underline_mark(
                $attribs->{$menu_name}{label},
                $attribs->{$menu_name}{underline}
            ),
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
    my ( $self, $menu, $item, $id ) = @_;

    $menu->AppendSeparator() if $item->{sep} eq 'before';

    # Preserve some default Id's used by Wx
    $id = wxID_ABOUT if $item->{name} eq q{mn_ab};
    $id = wxID_EXIT  if $item->{name} eq q{mn_qt};

    my $label = $item->{label};
    $label .= "\t" . $item->{key} if $item->{key};    # add shortcut key

    $self->{ $item->{name} }
        = $menu->Append( $id,
        Tpda3::Utils->ins_underline_mark( $label, $item->{underline}, ),
        );

    $menu->AppendSeparator() if $item->{sep} eq 'after';

    return;
}

=head2 get_menu_popup_item

Return a menu popup by name

=cut

sub get_menu_popup_item {
    my ( $self, $name ) = @_;

    return $self->{$name};
}

=head2 get_menubar

Return the menu bar handler

=cut

sub get_menubar {
    my $self = shift;

    return $self->{_menu};
}

=head2 _create_toolbar

Create toolbar

=cut

sub _create_toolbar {
    my $self = shift;

    my $tb = Tpda3::Wx::ToolBar->new( $self, wxADJUST_MINSIZE );

    my ( $toolbars, $attribs ) = $self->toolbar_names();

    my $ico_path = $self->_cfg->cfico;

    $tb->make_toolbar_buttons( $toolbars, $attribs, $ico_path );

    $self->SetToolBar($tb);

    $self->{_tb} = $self->GetToolBar;
    $self->{_tb}->Realize;

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

=head2 enable_tool

Enable|disable tool bar button.

State can come as 0|1 and normal|disabled.

=cut

sub enable_tool {
    my ( $self, $btn_name, $state ) = @_;

    $self->{_tb}->enable_tool( $btn_name, $state );

    return;
}

=head2 create_statusbar

Create a statusbar with 3 fields.  The first field have a fixed width,
the rest have variable widths.

=cut

sub _create_statusbar {
    my $self = shift;

    $self->{_sb} = $self->CreateStatusBar(3);

    $self->SetStatusWidths( -1, 46, 120 );

    $self->{_sb}->SetStatusStyles( wxSB_NORMAL, wxSB_RAISED, wxSB_NORMAL )
        ;    #wxSB_NORMAL, wxSB_RAISED, wxSB_FLAT

    return;
}

=head2 get_statusbar

Return the statusbar handler.

=cut

sub get_statusbar {
    my $self = shift;

    return $self->{_sb};
}

=head2 dialog_popup

Define a dialog popup.

=cut

sub dialog_popup {
    my ( $self, $msgtype, $msg ) = @_;

    if ( $msgtype eq 'Error' ) {
        Wx::MessageBox( $msg, $msgtype, wxOK | wxICON_ERROR, $self );
    }
    elsif ( $msgtype eq 'Warning' ) {
        Wx::MessageBox( $msg, $msgtype, wxOK | wxICON_WARNING, $self );
    }
    else {
        Wx::MessageBox( $msg, $msgtype, wxOK | wxICON_INFORMATION, $self );
    }
}

=head2 action_confirmed

Yes - No message dialog.

=cut

sub action_confirmed {
    my ( $self, $msg ) = @_;

    my ($answer) = Wx::MessageBox(
        $msg,
        'Confirm',
        Wx::wxYES_NO(),    # if you use Wx ':everything', it's wxYES_NO
        undef,             # you needn't pass anything, much less $frame
    );

    if ( $answer == Wx::wxYES() ) {
        return 1;
    }
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

    $self->{_nb} = Tpda3::Wx::Notebook->new($self);

    #-- Panels

    $self->{_nb}->create_notebook_page( 'rec', 'Record' );
    $self->{_nb}->create_notebook_page( 'lst', 'List' );

    # $self->{_nb}->create_notebook_page('det', 'Details');

    $self->{_rc} = Wx::Perl::ListCtrl->new(
        $self->{_nb}{lst},
        -1,
        [ -1, -1 ],
        [ -1, -1 ],
        Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL,
    );

    $self->{_rc}->InsertColumn( 0, 'Empty', wxLIST_FORMAT_LEFT, 50 );

    #-- Top

    my $lst_main_sz = Wx::BoxSizer->new(wxVERTICAL);

    my $lst_sbs
        = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{lst}, -1, ' List ', ), wxHORIZONTAL,
        );

    $lst_sbs->Add( $self->{_rc}, 1, wxEXPAND, 0 );
    $lst_main_sz->Add( $lst_sbs, 1, wxALL | wxEXPAND, 5 );

    $self->{_nb}{lst}->SetSizer($lst_main_sz);

    #--

    my $main_sizer = Wx::BoxSizer->new(wxVERTICAL);
    $main_sizer->Add( $self->{_nb}, 1, wxEXPAND, 0 );
    $self->SetSizer($main_sizer);
    $self->Layout();

    return;
}

sub get_nb_current_page {
    my $self = shift;

    my $nb = $self->get_notebook();

    my $page_idx = $nb->GetSelection();

    my $current_page = $nb->{pages}{$page_idx};

    return $current_page;
}

=head2 get_notebook

Return the notebook handler. Duplicate method.

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

    $self->{_nb}->Destroy if ref $self->{_nb};

    return;
}

=head2 get_toolbar_btn

Return a toolbar button by name.

=cut

sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{_tb}->get_toolbar_btn($name);
}

=head2 get_toolbar

Return the toolbar handler.

=cut

sub get_toolbar {
    my $self = shift;

    return $self->{_tb};
}

=head2 get_recordlist

Return list control handler.

=cut

sub get_recordlist {
    my $self = shift;

    return $self->{_rc};
}

=head2 get_control_by_name

Return the control instance by name.

=cut

sub get_control_by_name {
    my ( $self, $name ) = @_;

    return $self->{$name},;
}

=head2 log_config_options

Log configuration options with data from the Config module.

=cut

sub log_config_options {
    my $self = shift;

    my $cfg  = Tpda3::Config->instance();
    my $path = $cfg->output;

    while ( my ( $key, $value ) = each( %{$path} ) ) {
        $self->log_msg("II Config: '$key' set to '$value'");
    }
}

=head2 set_status

Set status message.

Color is ignored for wxPerl.

=cut

sub set_status {
    my ( $self, $text, $sb_id, $color ) = @_;

    my $sb = $self->get_statusbar();

    if ( $sb_id eq q{db} ) {

        # Database name
        $sb->PushStatusText( $text, 2 ) if defined $text;
    }
    elsif ( $sb_id eq q{ms} ) {

        # Messages
        $sb->PushStatusText( $text, 0 ) if defined $text;
    }
    else {

        # App status
        # my $cw = $self->GetCharWidth();
        # my $ln = length $text;
        # my $cn = () = $text =~ m{i|l}g;
        # my $pl = int( ( 46 - $cw * $ln ) / 2 );
        # $pl = ceil $pl / $cw;
        # print "cw=$cw : ln=$ln : cn=$cn : pl=$pl: $text\n";
        # $text = sprintf( "%*s", $pl, $text );
        $sb->PushStatusText( $text, 1 ) if defined $text;
    }

    return;
}

=head2 dialog_msg

Set dialog message

=cut

sub dialog_msg {
    my ( $self, $message ) = @_;

    $self->dialog_popup( 'Error', $message );
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

=head2 control_set_value

Set new value for a controll

=cut

sub control_set_value {
    my ( $self, $name, $value ) = @_;

    return unless defined $value;

    my $ctrl = $self->get_control_by_name($name);

    $ctrl->ClearAll;
    $ctrl->AppendText($value);
    $ctrl->AppendText("\n");
    $ctrl->Colourise( 0, $ctrl->GetTextLength );

    return;
}

=head2 control_append_value

Append value to a control.

=cut

sub control_append_value {
    my ( $self, $name, $value ) = @_;

    return unless defined $value;

    my $ctrl = $self->get_control_by_name($name);

    $ctrl->AppendText($value);
    $ctrl->AppendText("\n");
    $ctrl->Colourise( 0, $ctrl->GetTextLength );
}

=head2 toggle_status_cn

Toggle the icon in the status bar

=cut

sub toggle_status_cn {
    my ( $self, $status ) = @_;

    if ($status) {
        $self->set_status( $self->_cfg->connection->{dbname},
            'db', 'darkgreen' );
    }
    else {
        $self->set_status( '', 'db' );
    }

    return;
}

=head2 make_list_header

Make header for list

=cut

sub make_list_header {
    my ( $self, $header_look, $header_cols, $fields ) = @_;

    #- Delete existing columns
    $self->get_recordlist->ClearAll();

    #- Make header
    $self->{lookup} = [];
    my $colcnt = 0;

    #-- For lookup columns

    foreach my $col ( @{$header_look} ) {
        my $col_attribs = $self->header_width($fields->{$col});
        $self->list_header( $col_attribs, $colcnt );

        # Save index of columns to return
        push @{ $self->{lookup} }, $colcnt;

        $colcnt++;
    }

    #-- For the rest of the columns

    foreach my $col ( @{$header_cols} ) {
        my $col_attribs = $self->header_width($fields->{$col});
        $self->list_header( $col_attribs, $colcnt );
        $colcnt++;
    }

    return;
}

=head2 header_width

Width config is in chars. Use CherWidth to compute the with in pixels.

  pixels_with = chars_number x char_width

=cut

sub header_width {
    my ( $self, $field ) = @_;

    my $label_len = length $field->{label};
    my $width     = $field->{width};
    $width = $label_len >= $width ? $label_len + 2 : $width;
    my $char_width = $self->GetCharWidth();
    my $field_attr = {
        label => $field->{label},
        width => $width * $char_width,
        order => $field->{order},
    };

    return $field_attr;
}

=head2 list_header

Make header for the list in the List tab.

=cut

sub list_header {
    my ( $self, $col_attribs, $colcnt ) = @_;

    # Label
    $self->get_recordlist->InsertColumn( $colcnt, $col_attribs->{label},
        wxLIST_FORMAT_LEFT, $col_attribs->{width}, );

    if ( defined $col_attribs->{order} ) {

        # TODO: Figure out how to sort
        # if ($attr->{order} eq 'N') {
        #     $self->{_rc}->columnGet($colcnt)
        #         ->configure( -comparecommand => sub { $_[0] <=> $_[1]} );
        # }
    }
    else {
        warn " Warning: no sort option for '$col_attribs->{label}'\n";
    }

    return;
}

=head2 get_list_text_col

Return text item from list control row and col

=cut

sub get_list_text_col {
    my ( $self, $row, $col ) = @_;

    return $self->get_recordlist->GetItemText( $row, $col );
}

=head2 get_list_text_row

Get entire row text from a list control as array ref.

=cut

sub get_list_text_row {
    my ( $self, $row ) = @_;

    my $col_cnt = $self->get_recordlist->GetColumnCount() - 1;

    my @row_text;
    foreach my $col ( 0 .. $col_cnt ) {
        push @row_text, $self->get_list_text_col( $row, $col );
    }

    return \@row_text;
}

=head2 set_list_text

Set text item from list control row and col

=cut

sub set_list_text {
    my ( $self, $row, $col, $text ) = @_;
    $self->get_recordlist->SetItemText( $row, $col, $text );
}

=head2 set_list_data

Set item data from list control

=cut

sub set_list_data {
    my ( $self, $item, $data_href ) = @_;
    $self->get_recordlist->SetItemData( $item, $data_href );
}

=head2 get_list_data

Return item data from list control

=cut

sub get_list_data {
    my ( $self, $item ) = @_;
    return $self->get_recordlist->GetItemData($item);
}

=head2 list_item_select_first

Select the first item in list

=cut

sub list_item_select_first {
    my $self = shift;

    my $items_no = $self->get_list_max_index();

    if ( $items_no > 0 ) {
        $self->get_recordlist->Select( 0, 1 );
    }
}

=head2 list_item_select_last

Select the last item in list

=cut

sub list_item_select_last {
    my $self = shift;

    my $lst = $self->get_recordlist;
    my $idx = $self->get_list_max_index() - 1;

    #$lst->Select( $idx, 1 );
    #$lst->EnsureVisible($idx);
    $self->{_rc}->Select( $idx, 1 );
    $self->{_rc}->EnsureVisible($idx);

    return;
}

=head2 get_list_max_index

Return the max index from the list control

=cut

sub get_list_max_index {
    my $self = shift;

    return $self->get_recordlist->GetItemCount();
}

=head2 get_list_selected_index

Return the selected index from the list control

=cut

sub get_list_selected_index {
    my $self = shift;

    return $self->get_recordlist->GetSelection();
}

# =head2 list_item_insert

# Insert item in list control.

# =cut

# sub list_item_insert {
#     my ( $self, $indice, $nrcrt, $title, $file ) = @_;

#     # Remember, always sort by index before insert!
#     $self->list_string_item_insert($indice);
#     $self->set_list_text($indice, 0, $nrcrt);
#     $self->set_list_text($indice, 1, $title);
#     # Set data
#     $self->set_list_data($indice, $file );
# }

=head2 list_string_item_insert

Insert string item in list control

=cut

sub list_string_item_insert {
    my ( $self, $indice ) = @_;
    $self->get_recordlist->InsertStringItem( $indice, 'dummy' );
}

=head2 list_item_clear

Delete list control item

=cut

sub list_item_clear {
    my ( $self, $item ) = @_;
    $self->get_recordlist->DeleteItem($item);
}

=head2 list_item_clear_all

Delete all list control items

=cut

sub list_item_clear_all {
    my $self = shift;

    $self->get_recordlist->DeleteAllItems;
}

=head2 list_remove_item

Remove item from list control and select the first item

=cut

sub list_remove_item {
    my $self = shift;

    my $sel_item = $self->get_list_selected_index();
    my $file_fqn = $self->get_list_data($sel_item);

    # Remove from list
    $self->list_item_clear($sel_item);

    # Set item 0 selected
    $self->list_item_select_first();

    return $file_fqn;
}

=head2 list_init

Delete the rows of the list.

=cut

sub list_init {
    my $self = shift;

    $self->get_recordlist->DeleteAllItems();

    return;
}

=head2 list_populate

Polulate list with data from query result.

=cut

sub list_populate {
    my ( $self, $ary_ref ) = @_;

    my $row_count;

    if ( ref $self->get_recordlist ) {
        $row_count = $self->get_recordlist->GetItemCount();
    }
    else {
        warn "No MList!\n";
        return;
    }

    my $record_count = scalar @{$ary_ref};
    my $column_count = scalar @{$ary_ref->[0]};

    my $list = $self->get_recordlist();

    # Data
    foreach my $record ( @{$ary_ref} ) {


        $list->InsertStringItem( $row_count, 'dummy' );
        for ( my $col = 0; $col < $column_count; $col++ ) {
            $list->SetItemText( $row_count, $col, $record->[$col] );
        }

        $row_count++;

        $self->set_status( "$row_count records fetched", 'ms' );

        # Progress bar
        # my $p = floor( $row_count * 10 / $record_cnt ) * 10;
        # if ( $p % 10 == 0 ) { $self->{progres} = $p; }
    }

    $self->set_status( "$row_count records", 'ms' );

    # $self->{progres} = 0;

    return $record_count;
}

=head2 has_list_records

Return number of records from list.

=cut

sub has_list_records {
    my $self = shift;

    my $row_count;

    if ( ref $self->get_recordlist ) {
        eval { $row_count = $self->get_recordlist->GetItemCount(); };
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

    my $sel_no = $self->get_recordlist->GetSelectedItemCount();
    if ( $sel_no <= 0 ) {
        print "No record selected\n";
        return;
    }

    my $row = $self->get_list_selected_index();

    # Return column 0 in the row
    my $selected_value = $self->get_list_text_col( $row, 0 );    # col 0

    if ( defined $selected_value ) {

        # Trim spaces
        if ( defined($selected_value) ) {
            $selected_value =~ s/^\s+//;
            $selected_value =~ s/\s+$//;
        }
    }

    return $selected_value;
}

=head2 list_raise

Raise I<List> tab and set focus to list.

=cut

sub list_raise {
    my $self = shift;

    $self->get_notebook->SetSelection(1);           # 1 is 'lst' ?
    $self->list_item_select_last();

    return;
}

=head2 w_geometry

Return window geometry

=cut

sub w_geometry {
    my $self = shift;

    # my $wsys = $self->windowingsystem;
    my $name = $self->GetName();
    my $rect = $self->GetScreenRect();

    # All dimensions are in pixels.
    my $sh = $rect->height;
    my $sw = $rect->width;
    my $x  = $rect->x;
    my $y  = $rect->y;

    my $geom = "${sw}x${sh}+$x+$y";

    # print "\nSystem   = $wsys\n";
    print "Name     = $name\n";
    print "Geometry = $geom\n";

    return $geom;
}

=head2 set_geometry

Set window geometry

=cut

sub set_geometry {
    my ( $self, $geom ) = @_;

    my ( $w, $h, $x, $y ) = $geom =~ m{(\d+)x(\d+)([+-]\d+)([+-]\d+)};
    $self->SetSize( $x, $y, $w, $h );    # wxSIZE_AUTO
    # $self->_view->SetMinSize( Wx::Size->new( $w, -1 ) );

    return;
}

=head2 on_quit

Quit.

=cut

sub on_quit {
    my $self = shift;

    $self->Close(1);

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::View
