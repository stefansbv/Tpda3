package Tpda3::Tk::Controller;

use strict;
use warnings;

use Tk;
use Class::Unload;
use Log::Log4perl qw(get_logger);

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
    };

    $self->{_log} = get_logger();

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
            $self->_model->is_findmode
                ? $self->_model->set_idlemode
                : $self->_model->set_findmode;
        }
    );

    #-- Add mode
    $self->_view->get_toolbar_btn('tb_ad')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_addmode
                ? $self->_model->set_idlemode
                : $self->_model->set_addmode;
        }
    );

    #-- Quit
    $self->_view->get_toolbar_btn('tb_qt')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_view->on_quit;
        }
    );
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

=head2 _screen

Return current screen instance variable.

=cut

sub _screen {
    my $self = shift;

    return $self->{_screen};
}

=head2 toggle_controls

Toggle controls appropriate for diferent states of the application

=cut

sub toggle_controls {
    my $self = shift;

    my $is_edit = 0; # $self->_model->is_editmode ? 1 : 0;

    # Tool buttons states
    my $states = {
        tb_cn => !$is_edit,
        tb_fm => !$is_edit,
        tb_fe => $is_edit,
        tb_fc => $is_edit,
        tb_pr => $is_edit,
        tb_tn => $is_edit,
        tb_tr => $is_edit,
        tb_cl => $is_edit,
        tb_rr => $is_edit,
        tb_ad => !$is_edit,
        tb_rm => !$is_edit,
        tb_sv => $is_edit,
        tb_qt => !$is_edit,
    };

    foreach my $btn ( keys %{$states} ) {
        $self->set_controls_tb( $btn, $states->{$btn} );
    }

    # foreach my $page ( qw(para list conf sql ) ) {
    #     $self->toggle_controls_page( $page, $is_edit );
    # }
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

=head2 toggle_controls_page

Toggle the controls on page

=cut

sub toggle_controls_page {
    my ($self, $page, $is_edit) = @_;

    # my $get = 'get_controls_'.$page;
    # my $controls = $self->_view->$get();

    # foreach my $control ( @{$controls} ) {
    #     foreach my $name ( keys %{$control} ) {

    #         my $state = $control->{$name}->[1];  # normal | disabled
    #         my $color = $control->{$name}->[2];  # name

    #         # Controls state are defined in View as strings
    #         # Here we need to transform them to 0|1
    #         my $editable;
    #         if (!$is_edit) {
    #             $editable = 0;
    #             $color = 'lightgrey'; # Default color for disabled ctrl
    #         }
    #         else {
    #             $editable = $state eq 'normal' ? 1 : 0;
    #         }

    #         if ($page ne 'sql') {
    #             $control->{$name}->[0]->SetEditable($editable);
    #         }
    #         else {
    #             $control->{$name}->[0]->Enable($editable);
    #         }

    #         $control->{$name}->[0]->SetBackgroundColour(
    #             Tk::Colour->new( $color ),
    #         );
    #     }
    # }
}

=head2 screen_load

Load screen chosen from the menu

=cut

sub screen_load {
    my ($self, $what) = @_;

    my $loglevel_old = $self->{_log}->level();

    # Set log level to trace in this sub
    $self->{_log}->level($Log::Log4perl::TRACE);

    # Unload current screen
    if ( $self->{_curent} ) {
        Class::Unload->unload( $self->{_curent} );

        if ( ! Class::Inspector->loaded( $self->{_curent} ) ) {
            $self->{_log}->trace("Unloaded $self->{_curent} screen");
        }
        else {
            $self->{_log}->trace("Error unloading  $self->{_curent} screen");
        }
    }

    # Destroy existing NoteBook widget
    $self->_view->destroy_notebook();

    # Make new NoteBook widget
    $self->_view->create_notebook();

    my $class = "Tpda3::App::test::$what";
    (my $file = "$class.pm") =~ s/::/\//g;
    require $file;
    $class->import;

    if ($class->can('run_screen') ) {
        $self->{_log}->trace("Screen $class can 'run_screen'");
    }
    else {
        $self->{_log}->error("Error, screen $class can not 'run_screen'");
    }

    # New screen instance
    $self->{_screen} = $class->new();

    # Show screen
    $self->{idobj} = $self->{_screen}->run_screen(
        $self->_view->{_nb}{rec},
    );

    # Store currently loaded screen class
    $self->{_curent} = $class;

    # Restore default log level
    $self->{_log}->level($loglevel_old);
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
