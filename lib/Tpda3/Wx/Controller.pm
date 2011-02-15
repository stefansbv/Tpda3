package Tpda3::Wx::Controller;

use strict;
use warnings;

use Wx ':everything';
use Wx::Event qw(EVT_CLOSE EVT_CHOICE EVT_MENU EVT_TOOL EVT_BUTTON
                 EVT_AUINOTEBOOK_PAGE_CHANGED EVT_LIST_ITEM_SELECTED);

use Tpda3::Model;
use Tpda3::Wx::App;
use Tpda3::Wx::View;

=head1 NAME

Tpda3::Wx::Controller - The Controller

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Wx::Controller;

    my $controller = Tpda3::Wx::Controller->new();

    $controller->start();


=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $model = Tpda3::Model->new();

    my $app = Tpda3::Wx::App->create($model);

    my $self = {
        _model   => $model,
        _app     => $app,
        _view    => $app->{_view},
        _toolbar => $app->{_view}->get_toolbar,
    };

    bless $self, $class;

    $self->_set_event_handlers;

    # $self->_view->Show( 1 );

    return $self;
}

=head2 start

Populate list with titles, Log configuration options, set default
choice for export and initial mode.

TODO: make a more general method

=cut

sub start {
    my ($self, ) = @_;

    # $self->_view->list_populate_all();

    # $self->_view->log_config_options();

    # # Connect to database at start
    # $self->_model->db_connect();

    # my $default_choice = $self->_view->get_choice_default();
    # $self->_model->set_choice("0:$default_choice");

    # $self->_model->set_idlemode();
    # $self->toggle_controls;
}

=head2 _set_event_handlers

Close the application window

=cut

my $closeWin = sub {
    my ( $self, $event ) = @_;

    $self->Destroy();
};

=head2 _set_event_handlers

The About dialog

=cut

my $about = sub {
    my ( $self, $event ) = @_;

    Wx::MessageBox(
        "Tpda3 - v0.01\n(C) 2010 - 2011 Stefan Suciu\n\n"
            . " - WxPerl $Wx::VERSION\n"
            . " - " . Wx::wxVERSION_STRING,
        "About Tpda3-wxPerl",

        wxOK | wxICON_INFORMATION,
        $self
    );
};

=head2 _set_event_handlers

The exit sub

=cut

my $exit = sub {
    my ( $self, $event ) = @_;

    $self->Close( 1 );
};

=head2 _set_event_handlers

Setup event handlers

=cut

sub _set_event_handlers {
    my $self = shift;

    #- Menu
    EVT_MENU $self->_view, wxID_ABOUT, $about; # Change icons !!!
    EVT_MENU $self->_view, wxID_HELP, $about;
    EVT_MENU $self->_view, wxID_EXIT,  $exit;

    #- Toolbar

    #- Quit
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_qt')->GetId, $exit;

    #- Frame
    EVT_CLOSE $self->_view, $closeWin;
}

=head2 _model

Return model instance variable

=cut

sub _model {
    my $self = shift;

    return $self->{_model};
}

=head2 _view

Return view instance variable

=cut

sub _view {
    my $self = shift;

    return $self->{_view};
}

=head2 toggle_controls

Toggle controls appropriate for diferent states of the application

=cut

sub toggle_controls {
    my $self = shift;

    my $is_edit = $self->_model->is_editmode ? 1 : 0;

    # Tool buttons states
    my $states = {
        tb_cn => !$is_edit,
        tb_sv => $is_edit,
        tb_rf => !$is_edit,
        tb_ad => !$is_edit,
        tb_rm => !$is_edit,
        tb_ls => !$is_edit,
        tb_go => !$is_edit,
        tb_qt => !$is_edit,
    };

    foreach my $btn ( keys %{$states} ) {
        $self->toggle_controls_tb( $btn, $states->{$btn} );
    }

    # List control
    $self->{_list}->Enable(!$is_edit);

    # Controls by page Enabled in edit mode
    foreach my $page ( qw(para list conf sql ) ) {
        $self->toggle_controls_page( $page, $is_edit );
    }
}

=head2 toggle_controls_tb

Toggle the toolbar buttons state

=cut

sub toggle_controls_tb {
    my ( $self, $btn_name, $status ) = @_;

    my $tb_btn = $self->_view->get_toolbar_btn_id($btn_name);
    $self->{_toolbar}->EnableTool( $tb_btn, $status );
}

=head2 toggle_controls_page

Toggle the controls on page

=cut

sub toggle_controls_page {
    my ($self, $page, $is_edit) = @_;

    my $get = 'get_controls_'.$page;
    my $controls = $self->_view->$get();

    foreach my $control ( @{$controls} ) {
        foreach my $name ( keys %{$control} ) {

            my $state = $control->{$name}->[1];  # normal | disabled
            my $color = $control->{$name}->[2];  # name

            # Controls state are defined in View as strings
            # Here we need to transform them to 0|1
            my $editable;
            if (!$is_edit) {
                $editable = 0;
                $color = 'lightgrey'; # Default color for disabled ctrl
            }
            else {
                $editable = $state eq 'normal' ? 1 : 0;
            }

            if ($page ne 'sql') {
                $control->{$name}->[0]->SetEditable($editable);
            }
            else {
                $control->{$name}->[0]->Enable($editable);
            }

            $control->{$name}->[0]->SetBackgroundColour(
                Wx::Colour->new( $color ),
            );
        }
    }
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 - 2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of Tpda3::Wx::Controller
