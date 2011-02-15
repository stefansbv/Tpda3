package Tpda3::Wx::Controller;

use strict;
use warnings;

use Wx q{:everything};
use Wx::Event qw(EVT_CLOSE EVT_CHOICE EVT_MENU EVT_TOOL EVT_BUTTON
                 EVT_AUINOTEBOOK_PAGE_CHANGED EVT_LIST_ITEM_SELECTED);

use Log::Log4perl qw(get_logger :levels);

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
        _scrcls  => undef,
        _scrobj  => undef,
        _scrcfg  => undef,
        _scrstr  => undef,
        _cfg     => Tpda3::Config->instance(),
        _log     => get_logger(),
    };

    bless $self, $class;

    # my $loglevel_old = $self->_log->level();

    $self->_set_event_handlers;

    return $self;
}

=head2 start

Populate list with titles, Log configuration options, set default
choice for export and initial mode.

TODO: make a more general method

=cut

sub start {
    my ($self, ) = @_;

    $self->_log->trace("start");

    # Check if we have user and pass, if not, show dialog
    if ( !$self->_cfg->user or !$self->_cfg->pass ) {
        my $pd = Tpda3::Wx::Dialog::Pwd->new;
        $pd->run_dialog( $self->_view );
    }

    # Check again ...
    if ( $self->_cfg->user and $self->_cfg->pass ) {

        # Connect to database
        $self->_model->toggle_db_connect();
    }
    else {
        $self->_view->on_quit;
    }

    return;
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

Setup event handlers for the interface.

=cut

sub _set_event_handlers {
    my $self = shift;

    $self->_log->trace("Setup event handlers");

    #- Frame
    EVT_CLOSE $self->_view, $closeWin;

    #- Base menu

    EVT_MENU $self->_view, wxID_ABOUT, $about; # Change icons !!!
    EVT_MENU $self->_view, wxID_EXIT,  $exit;
    # EVT_MENU $self->_view, wxID_HELP,  $help;

    # Config dialog
    # $self->_view->get_menu_popup_item('mn_fn')->configure(
    #     -command => sub {
    #         $self->_view->show_config_dialog;
    #     }
    # );

    #- Custom application menu from menu.yml

    # my $appmenus = $self->_view->get_app_menus_list();
    # foreach my $item ( @{$appmenus} ) {
    #     $self->_view->get_menu_popup_item($item)->configure(
    #         -command => sub {
    #             $self->screen_module_load($item);
    #         }
    #     );
    # }

    #- Toolbar

    #-- Attach to desktop - pin (save geometry to config file)
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_at')->GetId, sub {
        my $scr_name = $self->{_scrstr} || 'main';
        $self->_cfg->config_save_instance(
            $scr_name,
            # $self->_view->w_geometry();
        );
    };

    #-- Find mode
    # $self->_view->get_toolbar_btn('tb_fm')->bind(
    #     '<ButtonRelease-1>' => sub {
    #         # From add mode forbid find mode
    #         if ( !$self->_model->is_mode('add') ) {
    #             $self->toggle_mode_find();
    #         }
    #     }
    # );

    #-- Find execute
    # $self->_view->get_toolbar_btn('tb_fe')->bind(
    #     '<ButtonRelease-1>' => sub {
    #         if ( $self->_model->is_mode('find') ) {
    #             $self->record_find_execute;
    #         }
    #         else {
    #             print "WARN: Not in find mode\n";
    #         }
    #     }
    # );

    #-- Find count
    # $self->_view->get_toolbar_btn('tb_fc')->bind(
    #     '<ButtonRelease-1>' => sub {
    #         if ( $self->_model->is_mode('find') ) {
    #             $self->record_find_count;
    #         }
    #         else {
    #             print "WARN: Not in find mode\n";
    #         }
    #     }
    # );

    #-- Add mode
    # $self->_view->get_toolbar_btn('tb_ad')->bind(
    #     '<ButtonRelease-1>' => sub {
    #         $self->toggle_mode_add();
    #     }
    # );

    #-- Quit
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_qt')->GetId, $exit;

    #-- Make some key bindings

    # $self->_view->bind( '<Alt-x>' => sub { $self->_view->on_quit } );
    # $self->_view->bind(
    #     '<F7>' => sub {
    #         # From add mode forbid find mode
    #         if ( !$self->_model->is_mode('add') ) {
    #             $self->toggle_mode_find();
    #         }
    #     }
    # );
    # $self->_view->bind(
    #     '<F8>' => sub {
    #         if ( $self->_model->is_mode('find') ) {
    #             $self->record_find_execute;
    #         }
    #         else {
    #             print "WARN: Not in find mode\n";
    #         }
    #     }
    # );

    return;
}

=head2 _model

Return model instance variable.

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

=head2 _cfg

Return config instance variable

=cut

sub _cfg {
    my $self = shift;

    return $self->{_cfg};
}

=head2 _log

Return log instance variable

=cut

sub _log {
    my $self = shift;

    return $self->{_log};
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
