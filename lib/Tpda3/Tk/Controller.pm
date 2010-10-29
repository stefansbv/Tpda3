package Tpda3::Tk::Controller;

use strict;
use warnings;

use Data::Dumper;

use Tk;
use Class::Unload;
use Log::Log4perl qw(get_logger :levels);

use Tpda3::Config;
use Tpda3::Config::Screen;
use Tpda3::Model;
use Tpda3::Tk::View;

=head1 NAME

Tpda3::Tk::Controller - The Controller

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Tk::Controller;

    my $controller = Tpda3::Tk::Controller->new();

    $controller->start();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $app ) = @_;

    my $model = Tpda3::Model->new();

    my $view = Tpda3::Tk::View->new(
        $model,
    );

    my $self = {
        _model   => $model,
        _view    => $view,
        _curent  => undef,
        _screen  => undef,
        _scrcfg  => undef,
        _scr_id  => undef,
        _cfg     => Tpda3::Config->instance(),
        _log     => get_logger(),
    };

    bless $self, $class;

    $self->_set_event_handlers;

    return $self;
}

=head2 start

Initialization of states

=cut

sub start {
    my $self = shift;

    # Connect to database at start
    $self->_model->toggle_db_connect();

    $self->_model->set_idlemode();

    $self->toggle_controls;
}

=head2 _set_event_handlers

Setup event handlers

=cut

sub _set_event_handlers {
    my $self = shift;

    #- Base menu

    #-- Exit
    $self->_view->get_menu_popup_item('mn_qt')->configure(
        -command => sub {
            $self->_view->on_quit;
        }
    );

    #-- Save geometry
    $self->_view->get_menu_popup_item('mn_sg')->configure(
        -command => sub {
            my $scr_name = $self->{_scr_id} ||= 'main';
            $self->_cfg
              ->config_save_instance( $scr_name, $self->_view->w_geometry() );
        }
    );

    #- Custom application menu from menu.yml

    my $appmenus = $self->_view->get_app_menus_list();
    foreach my $item ( @{$appmenus} ) {
        $self->_view->get_menu_popup_item($item)->configure(
            -command => sub {
                $self->screen_load($item);
            }
        );
    }

    #- Toolbar

    #-- Connect
    $self->_view->get_toolbar_btn('tb_cn')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->toggle_db_connect;
        }
    );

    #-- Find mode
    $self->_view->get_toolbar_btn('tb_fm')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('find')
                ? $self->_model->set_idlemode
                : $self->_model->set_findmode;
            $self->toggle_controls;
        }
    );

    #-- Add mode
    $self->_view->get_toolbar_btn('tb_ad')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('add')
                ? $self->_model->set_idlemode
                : $self->_model->set_addmode;
            $self->toggle_controls;
        }
    );

    #-- Quit
    $self->_view->get_toolbar_btn('tb_qt')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_view->on_quit;
        }
    );

    return;
}

=head2 event_handler_nb

Separate event handler fro notebook because must be initialized only
after the notebook is created.

=cut

sub event_handler_nb {
    my ($self, $page) = @_;

    my $nb = $self->_view->get_notebook();

    $nb->pageconfigure(
        $page,
        -raisecmd => sub {
            # print "$page tab activated\n";
        },
    );

    return;
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

=head2 _screen

Return current screen instance variable.

=cut

sub _screen {
    my $self = shift;

    return $self->{_screen};
}

=head2 _scrcfg

Return current screen config instance variable.

=cut

sub _scrcfg {
    my $self = shift;

    return $self->{_scrcfg};
}

=head2 toggle_controls

Toggle controls appropriate for diferent states of the application

=cut

sub toggle_controls {
    my $self = shift;

    my ($toolbars, $attribs) = $self->{_view}->toolbar_names();

    my $mode = $self->_model->get_appmode;

    foreach my $name (@{$toolbars}) {
        my $status = $attribs->{$name}{state}{$mode};
        # print "$name : $status\n";
        #$self->set_controls_tb( $name, $status );
        $self->_view->toggle_tool($name, $status);
    }

    return;
}

=head2 set_controls_tb

Toggle the toolbar buttons state

=cut

sub set_controls_tb {
    my ( $self, $btn_name, $status ) = @_;

    my $state = $status ? 'normal' : 'disabled';
    # print " $btn_name is $state\n";

    $self->_view->toggle_tool($btn_name, $state);
}

=head2 screen_load

Load screen chosen from the menu

=cut

sub screen_load {
    my ($self, $module) = @_;

    $self->{_scr_id} = lc $module;           # for instance config filename

    my $loglevel_old = $self->_log->level();

    # Set log level to trace in this sub
    $self->_log->level($TRACE);

    # Unload current screen
    if ( $self->{_curent} ) {
        Class::Unload->unload( $self->{_curent} );

        if ( ! Class::Inspector->loaded( $self->{_curent} ) ) {
            $self->_log->trace("Unloaded '$self->{_curent}' screen");
        }
        else {
            $self->_log->trace("Error unloading '$self->{_curent}' screen");
        }
    }

    # Destroy existing NoteBook widget
    $self->_view->destroy_notebook();

    # Make new NoteBook widget
    $self->_view->create_notebook();
    $self->event_handler_nb('rec');

    # The application name
    my $name = ucfirst $self->_cfg->cfname;
    my $class = "Tpda3::App::${name}::${module}";
    (my $file = "$class.pm") =~ s/::/\//g;
    require $file;
    # $class->import;

    if ($class->can('run_screen') ) {
        $self->_log->trace("Screen '$class' can 'run_screen'");
    }
    else {
        $self->_log->error("Error, screen '$class' can not 'run_screen'");
    }

    # New screen instance
    $self->{_screen} = $class->new();

    # Show screen
    my $nb = $self->_view->get_notebook('rec');
    $self->{idobj} = $self->{_screen}->run_screen($nb);

    # Load screen config, and replace the precedent screen config
    $self->{_scrcfg} = Tpda3::Config::Screen->new();
    $self->_scrcfg->config_screen_load($self->{_scr_id} . '.conf');

    # foreach my $fld ( keys %{ $self->{_scrcfg}{screen}{table}{fields} } ) {
    #     print '', $self->{_scrcfg}{screen}{table}{fields}{$fld}{ctrlref}, "\n";
    # }

    # Update window geometry
    my $geom = $self->_scrcfg->screen->{pos};
    $self->_view->set_geometry($geom);

    # Store currently loaded screen class
    $self->{_curent} = $class;

    my $ctrls = $self->{_screen}->get_controls();

    # Restore default log level
    $self->_log->level($loglevel_old);
}

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

1; # End of Tpda3::Tk::Controller
