package Tpda3::Wx::View;

use strict;
use warnings;

use Carp;
use POSIX qw (floor);

use Log::Log4perl qw(get_logger);

use File::Spec::Functions qw(abs2rel);
use Wx qw[:everything];
#use Wx::Perl::ListCtrl;
#use Wx::STC;

use base 'Wx::Frame';

use Tpda3::Config;
use Tpda3::Utils;
#use Tpda3::Wx::Notebook;
use Tpda3::Wx::ToolBar;

=head1 NAME

Tpda3::Wx::App - Wx Perl application class

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Tpda3::Wx::Notebook;

    $self->{_nb} = Tpda3::Wx::Notebook->new( $gui );

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;
    my $model = shift;

    #- The Frame

    my $self = __PACKAGE__->SUPER::new( @_ );

    Wx::InitAllImageHandlers();

    $self->{_model} = $model;

    $self->{_cfg} = Tpda3::Config->instance();

    $self->SetMinSize( Wx::Size->new( 460, 240 ) );
    $self->SetIcon( Wx::GetWxPerlIcon() );

    #-- Menu
    $self->create_menu();

    #-- ToolBar
    $self->_create_toolbar();

    #-- Statusbar
    $self->create_statusbar();

    #-- Notebook
    # $self->{_nb} = Tpda3::Wx::Notebook->new( $self );

    # $self->_set_model_callbacks();

    $self->Fit;

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

Define the model callbacks

=cut

sub _set_model_callbacks {
    my $self = shift;

    my $tb = $self->get_toolbar();
    #-
    my $co = $self->_model->get_connection_observable;
    $co->add_callback(
        sub { $tb->ToggleTool( $self->get_toolbar_btn_id('tb_cn'), $_[0] ) } );
    #--
    my $em = $self->_model->get_editmode_observable;
    $em->add_callback(
        sub {
            $tb->ToggleTool( $self->get_toolbar_btn_id('tb_ed'), $_[0] );
            $self->toggle_sql_replace();
        }
    );
    #--
    my $upd = $self->_model->get_itemchanged_observable;
    $upd->add_callback(
        sub { $self->controls_populate(); } );
    #--
    my $so = $self->_model->get_stdout_observable;
    #$so->add_callback( sub{ $self->log_msg( $_[0] ) } );
    $so->add_callback( sub{ $self->status_msg( @_ ) } );

    my $xo = $self->_model->get_exception_observable;
    # $xo->add_callback( sub{ $self->dialog_msg( @_ ) } );
    $xo->add_callback( sub{ $self->log_msg( @_ ) } );
}

=head2 create_menu

Create the menu

=cut

sub create_menu {
    my $self = shift;

    my $menu = Wx::MenuBar->new;

    $self->{_menu} = $menu;

    my $menu_app = Wx::Menu->new;
    $menu_app->Append( wxID_EXIT, "E&xit\tAlt+X" );
    $menu->Append( $menu_app, "&App" );

    my $menu_help = Wx::Menu->new();
    $menu_help->AppendString( wxID_HELP, "&Contents...", q{} );
    $menu_help->AppendString( wxID_ABOUT, "&About", q{} );
    $menu->Append( $menu_help, "&Help" );

    $self->SetMenuBar($menu);
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

    my ($toolbars, $attribs) = $self->toolbar_names();

    my $ico_path = $self->{_cfg}->cfico;

    $tb->make_toolbar_buttons($toolbars, $attribs, $ico_path);

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

    return ($toolbars, $attribs);
}

=head2 create_statusbar

Create the status bar

=cut

sub create_statusbar {
    my $self = shift;

    my $sb = $self->CreateStatusBar( 3 );
    $self->{_sb} = $sb;

    $self->SetStatusWidths( 260, -1, -2 );
}

=head2 get_statusbar

Return the status bar handler

=cut

sub get_statusbar {
    my $self = shift;

    return $self->{_sb};
}

=head2 get_notebook

Return the notebook handler

=cut

sub get_notebook {
    my $self = shift;

    return $self->{_nb};
}

=head2 dialog_popup

Define a dialog popup.

=cut

sub dialog_popup {
    my ( $self, $msgtype, $msg ) = @_;
    if ( $msgtype eq 'Error' ) {
        Wx::MessageBox( $msg, $msgtype, wxOK|wxICON_ERROR, $self )
    }
    elsif ( $msgtype eq 'Warning' ) {
        Wx::MessageBox( $msg, $msgtype, wxOK|wxICON_WARNING, $self )
    }
    else {
        Wx::MessageBox( $msg, $msgtype, wxOK|wxICON_INFORMATION, $self )
    }
}

=head2 action_confirmed

Yes - No message dialog.

=cut

sub action_confirmed {
    my ( $self, $msg ) = @_;

    my( $answer ) =  Wx::MessageBox(
        $msg,
        'Confirm',
        Wx::wxYES_NO(),  # if you use Wx ':everything', it's wxYES_NO
        undef,           # you needn't pass anything, much less $frame
     );

     if( $answer == Wx::wxYES() ) {
         return 1;
     }
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

=head2 get_choice_default

Return the choice default option, the first element in the array.

=cut

sub get_choice_default {
    my $self = shift;

    return $self->{_tb}->get_choice_options(0);
}

=head2 get_listcontrol

Return the list control handler.

=cut

sub get_listcontrol {
    my $self = shift;

    return $self->{_list};
}

=head2 get_controls_list

Return a AoH with information regarding the controls from the list page.

=cut

sub get_controls_list {
    my $self = shift;

    return [
        { title       => [ $self->{title}      , 'normal'  , 'white'     ] },
        { filename    => [ $self->{filename}   , 'disabled', 'lightgrey' ] },
        { output      => [ $self->{output}     , 'normal'  , 'white'     ] },
        { sheet       => [ $self->{sheet}      , 'normal'  , 'white'     ] },
        { description => [ $self->{description}, 'normal'  , 'white'     ] },
    ];
}

=head2 get_controls_para

Return a AoH with information regarding the controls from the parameters page.

=cut

sub get_controls_para {
    my $self = shift;

    return [
        { descr1 => [ $self->{descr1}, 'normal'  , 'white' ] },
        { value1 => [ $self->{value1}, 'normal'  , 'white' ] },
        { descr2 => [ $self->{descr2}, 'normal'  , 'white' ] },
        { value2 => [ $self->{value2}, 'normal'  , 'white' ] },
        { descr3 => [ $self->{descr3}, 'normal'  , 'white' ] },
        { value3 => [ $self->{value3}, 'normal'  , 'white' ] },
        { descr4 => [ $self->{descr4}, 'normal'  , 'white' ] },
        { value4 => [ $self->{value4}, 'normal'  , 'white' ] },
        { descr5 => [ $self->{descr5}, 'normal'  , 'white' ] },
        { value5 => [ $self->{value5}, 'normal'  , 'white' ] },
    ];
}

=head2 get_controls_sql

Return a AoH with information regarding the controls from the SQL page.

=cut

sub get_controls_sql {
    my $self = shift;

    return [
        { sql => [ $self->{sql}, 'normal'  , 'white' ] },
    ];
}

=head2 get_controls_conf

Return a AoH with information regarding the controls from the
configurations page.

None at this time.

=cut

sub get_controls_conf {
    my $self = shift;

    return [];
}

=head2 get_control_by_name

Return the control instance by name.

=cut

sub get_control_by_name {
    my ($self, $name) = @_;

    return $self->{$name},
}

=head2 get_list_text

Return text item from list control row and col

=cut

sub get_list_text {
    my ($self, $row, $col) = @_;

    return $self->get_listcontrol->GetItemText( $row, $col );
}

=head2 set_list_text

Set text item from list control row and col

=cut

sub set_list_text {
    my ($self, $row, $col, $text) = @_;
    $self->get_listcontrol->SetItemText( $row, $col, $text );
}

=head2 set_list_data

Set item data from list control

=cut

sub set_list_data {
    my ($self, $item, $data_href) = @_;
    $self->get_listcontrol->SetItemData( $item, $data_href );
}

=head2 get_list_data

Return item data from list control

=cut

sub get_list_data {
    my ($self, $item) = @_;
    return $self->get_listcontrol->GetItemData( $item );
}

=head2 list_item_select_first

Select the first item in list

=cut

sub list_item_select_first {
    my ($self) = @_;

    my $items_no = $self->get_list_max_index();

    if ( $items_no > 0 ) {
        $self->get_listcontrol->Select(0, 1);
    }
}

=head2 list_item_select_last

Select the last item in list

=cut

sub list_item_select_last {
    my ($self) = @_;

    my $items_no = $self->get_list_max_index();
    my $idx = $items_no - 1;
    $self->get_listcontrol->Select( $idx, 1 );
    $self->get_listcontrol->EnsureVisible($idx);
}

=head2 get_list_max_index

Return the max index from the list control

=cut

sub get_list_max_index {
    my ($self) = @_;

    return $self->get_listcontrol->GetItemCount();
}

=head2 get_list_selected_index

Return the selected index from the list control

=cut

sub get_list_selected_index {
    my ($self) = @_;

    return $self->get_listcontrol->GetSelection();
}

=head2 list_item_insert

Insert item in list control

=cut

sub list_item_insert {
    my ( $self, $indice, $nrcrt, $title, $file ) = @_;

    # Remember, always sort by index before insert!
    $self->list_string_item_insert($indice);
    $self->set_list_text($indice, 0, $nrcrt);
    $self->set_list_text($indice, 1, $title);
    # Set data
    $self->set_list_data($indice, $file );
}

=head2 list_string_item_insert

Insert string item in list control

=cut

sub list_string_item_insert {
    my ($self, $indice) = @_;
    $self->get_listcontrol->InsertStringItem( $indice, 'dummy' );
}

=head2 list_item_clear

Delete list control item

=cut

sub list_item_clear {
    my ($self, $item) = @_;
    $self->get_listcontrol->DeleteItem($item);
}

=head2 list_item_clear_all

Delete all list control items

=cut

sub list_item_clear_all {
    my ($self) = @_;
    $self->get_listcontrol->DeleteAllItems;
}

=head2 log_config_options

Log configuration options with data from the Config module

=cut

sub log_config_options {
    my $self = shift;

    my $cfg  = Tpda3::Config->instance();
    my $path = $cfg->output;

    while ( my ( $key, $value ) = each( %{$path} ) ) {
        $self->log_msg("II Config: '$key' set to '$value'");
    }
}

=head2 list_populate_all

Populate all other pages except the configuration page

=cut

sub list_populate_all {

    my ($self) = @_;

    my $titles = $self->_model->get_list_data();

    # Clear list
    $self->list_item_clear_all();

    # Populate list in sorted order
    my @titles = sort { $a <=> $b } keys %{$titles};
    foreach my $indice ( @titles ) {
        my $nrcrt = $titles->{$indice}[0];
        my $title = $titles->{$indice}[1];
        my $file  = $titles->{$indice}[2];
        # print "$nrcrt -> $title\n";
        $self->list_item_insert($indice, $nrcrt, $title, $file);
    }

    # Set item 0 selected on start
    $self->list_item_select_first();
}

=head2 list_populate_item

Add new item in list control and select the last item

=cut

sub list_populate_item {
    my ( $self, $rec ) = @_;

    my $idx = $self->get_list_max_index();
    $self->list_item_insert( $idx, $idx + 1, $rec->{title}, $rec->{file} );
    $self->list_item_select_last();
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

=head2 get_detail_data

Return detail data from the selected list control item

=cut

sub get_detail_data {
    my $self = shift;

    my $sel_item  = $self->get_list_selected_index();
    my $file_fqn  = $self->get_list_data($sel_item);
    my $ddata_ref = $self->_model->get_detail_data($file_fqn);

    return ( $ddata_ref, $file_fqn, $sel_item );
}

=head2 controls_populate

Populate controls with data from XML

=cut

sub controls_populate {
    my $self = shift;

    my ($ddata_ref, $file_fqn) = $self->get_detail_data();

    my $cfg  = Tpda3::Config->instance();
    my $qdfpath =$cfg->cfgpath;

    #-- Header
    # Write in the control the filename, remove path config path
    my $file_rel = File::Spec->abs2rel( $file_fqn, $qdfpath ) ;

    # Add real path to control
    $ddata_ref->{header}{filename} = $file_rel;
    $self->controls_write_page('list', $ddata_ref->{header} );

    #-- Parameters
    my $params = $self->params_data_to_hash( $ddata_ref->{parameters} );
    $self->controls_write_page('para', $params );

    #-- SQL
    $self->control_set_value( 'sql', $ddata_ref->{body}{sql} );

    #--- Highlight SQL parameters
    $self->toggle_sql_replace();
}

=head2 toggle_sql_replace

Toggle sql replace

=cut

sub toggle_sql_replace {
    my $self = shift;

    #- Detail data
    my ( $ddata, $file_fqn ) = $self->get_detail_data();

    #-- Parameters
    my $params = $self->params_data_to_hash( $ddata->{parameters} );

    if ( $self->_model->is_editmode ) {
        $self->control_set_value( 'sql', $ddata->{body}{sql} );
    }
    else {
        $self->control_replace_sql_text( $ddata->{body}{sql}, $params );
    }
}

=head2 control_replace_sql_text

Replace sql text control

=cut

sub control_replace_sql_text {
    my ($self, $sqltext, $params) = @_;

    my ($newtext, $positions) = $self->string_replace_pos($sqltext, $params);

    # Write new text to control
    $self->control_set_value('sql', $newtext);
}

=head2 status_msg

Set status message

=cut

sub status_msg {
    my ( $self, $msg ) = @_;

    my ( $text, $sb_id ) = split ':', $msg; # Work around until I learn how
                                            # to pass other parameters ;)

    $sb_id = 0 if $sb_id !~ m{[0-9]}; # Fix for when file name contains ':'
    $self->get_statusbar()->SetStatusText( $text, $sb_id );
}

=head2 dialog_msg

Set dialog message

=cut

sub dialog_msg {
    my ( $self, $message ) = @_;

    $self->dialog_popup( 'Error', $message );
}

=head2 log_msg

Set log message

=cut

sub log_msg {
    my ( $self, $message ) = @_;

    $self->control_append_value( 'log', $message );
}

=head2 process_sql

Get the sql text string from the QDF file, prepare it for execution.

=cut

sub process_sql {
    my $self = shift;

    my ($data, $file_fqn, $item) = $self->get_detail_data();

    my ($bind, $sqltext) = $self->string_replace_for_run(
        $data->{body}{sql},
        $data->{parameters},
    );

    if ($bind and $sqltext) {
        $self->_model->run_export(
            $data->{header}{output}, $bind, $sqltext);
    }
}

=head2 params_data_to_hash

Transform data in simple hash reference format

TODO: Move this to model?

=cut

sub params_data_to_hash {
    my ($self, $params) = @_;

    my $parameters;
    foreach my $parameter ( @{ $params->{parameter} } ) {
        my $id = $parameter->{id};
        if ($id) {
            $parameters->{"value$id"} = $parameter->{value};
            $parameters->{"descr$id"} = $parameter->{descr};
        }
    }

    return $parameters;
}

=head2 string_replace_pos

Replace string pos

=cut

sub string_replace_pos {

    my ($self, $text, $params) = @_;

    my @strpos;

    while (my ($key, $value) = each ( %{$params} ) ) {
        next unless $key =~ m{value[0-9]}; # Skip 'descr'

        # Replace  text and return the strpos
        $text =~ s/($key)/$value/pm;
        my $pos = $-[0];
        push(@strpos, [ $pos, $key, $value ]);
    }

    # Sorted by $pos
    my @sortedpos = sort { $a->[0] <=> $b->[0] } @strpos;

    return ($text, \@sortedpos);
}

=head2 string_replace_for_run

Prepare sql text string for execution.  Replace the 'valueN' string
with with '?'.  Create an array of parameter values, used for binding.

Need to check if number of parameters match number of 'valueN' strings
in SQL statement text and print an error if not.

=cut

sub string_replace_for_run {
    my ( $self, $sqltext, $params ) = @_;

    my @bind;
    foreach my $rec ( @{ $params->{parameter} } ) {
        my $value = $rec->{value};
        my $p_num = $rec->{id};         # Parameter number for bind_param
        my $var   = 'value' . $p_num;
        unless ( $sqltext =~ s/($var)/\?/pm ) {
            $self->log_msg("EE Parameter mismatch, to few parameters in SQL");
            return;
        }

        push( @bind, [ $p_num, $value ] );
    }

    # Check for remaining not substituted 'value[0-9]' in SQL
    if ( $sqltext =~ m{(value[0-9])}pm ) {
        $self->log_msg("EE Parameter mismatch, to many parameters in SQL");
        return;
    }

    return ( \@bind, $sqltext );
}

=head2 control_set_value

Set new value for a controll

=cut

sub control_set_value {
    my ($self, $name, $value) = @_;

    return unless defined $value;

    my $ctrl = $self->get_control_by_name($name);

    $ctrl->ClearAll;
    $ctrl->AppendText($value);
    $ctrl->AppendText( "\n" );
    $ctrl->Colourise( 0, $ctrl->GetTextLength );

}

=head2 control_set_value

Set new value for a controll

=cut

sub control_append_value {
    my ($self, $name, $value) = @_;

    return unless defined $value;

    my $ctrl = $self->get_control_by_name($name);

    $ctrl->AppendText($value);
    $ctrl->AppendText( "\n" );
    $ctrl->Colourise( 0, $ctrl->GetTextLength );
}

=head2 controls_write_page

Write all controls on page with data

=cut

sub controls_write_page {
    my ($self, $page, $data) = @_;

    # Get controls name and object from $page
    my $get = 'get_controls_'.$page;
    my $controls = $self->$get();

    foreach my $control ( @{$controls} ) {
        foreach my $name ( keys %{$control} ) {

            my $value = $data->{$name};

            # Cleanup value
            if ( defined $value ) {
                $value =~ s/\n$//mg;    # Multiline
            }
            else {
                $value = q{};           # Empty
            }

            $control->{$name}[0]->SetValue($value);
        }
    }
}

=head2 controls_read_page

Read all controls from page and return an array reference

=cut

sub controls_read_page {
    my ( $self, $page ) = @_;

    # Get controls name and object from $page
    my $get      = 'get_controls_' . $page;
    my $controls = $self->$get();
    my @records;

    foreach my $control ( @{$controls} ) {
        foreach my $name ( keys %{$control} ) {
            my $value;
            if ($page ne 'sql') {
                $value = $control->{$name}[0]->GetValue();
            }
            else {
                $value = $control->{$name}[0]->GetText();
            }

            push(@records, { $name => $value } ) if ($name and $value);
        }
    }

    return \@records;
}

=head2 save_query_def

Save query definition file

=cut

sub save_query_def {
    my $self = shift;

    my (undef, $file_fqn, $item) = $self->get_detail_data();

    my $head = $self->controls_read_page('list');
    my $para = $self->controls_read_page('para');
    my $body = $self->controls_read_page('sql');

    my $new_title =
      $self->_model->save_query_def( $file_fqn, $head, $para, $body );

    # Update title in list
    $self->set_list_text( $item, 1, $new_title );
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010 - 2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of Tpda3::Wx::View
