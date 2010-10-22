package Tpda3::Tk::Controller;

use strict;
use warnings;

use Log::Log4perl qw(get_logger);

use Tk;

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
        _toolbar => $view->get_toolbar,
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
    # $self->_model->db_connect();

    $self->_model->set_idlemode();
    $self->toggle_controls;
}

=head2 _set_event_handlers

Setup event handlers

=cut

sub _set_event_handlers {
    my $self = shift;

    #- Menu

    #-- Exit
    my $pop = $self->_view->get_menu_popup_item('mn_qt');
    $pop->configure(
        -command => sub {
            $self->_view->on_quit;
        }
    );

    #- Toolbar

    #-- Connect
    $self->_view->get_toolbar_btn('tb_cn')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->toggle_db_connect;
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

=head2 toggle_controls

Toggle controls appropriate for diferent states of the application

=cut

sub toggle_controls {
    my $self = shift;

    my $is_edit = 0; # $self->_model->is_editmode ? 1 : 0;

    # Tool buttons states
    my $states = {
        tb_cn => !$is_edit,
        tb_fm => $is_edit,
        tb_fe => $is_edit,
        tb_fc => $is_edit,
        tb_pr => $is_edit,
        tb_tn => $is_edit,
        tb_tr => $is_edit,
        tb_cl => $is_edit,
        tb_rr => $is_edit,
        tb_ad => $is_edit,
        tb_rm => $is_edit,
        tb_sv => $is_edit,
        tb_qt => !$is_edit,
    };

    foreach my $btn ( keys %{$states} ) {
        $self->toggle_controls_tb( $btn, $states->{$btn} );
    }

    # # List control
    # $self->{_list}->Enable(!$is_edit);

    # # Controls by page Enabled in edit mode
    # foreach my $page ( qw(para list conf sql ) ) {
    #     $self->toggle_controls_page( $page, $is_edit );
    # }
}

=head2 toggle_controls_tb

Toggle the toolbar buttons state

=cut

sub toggle_controls_tb {
    my ( $self, $btn_name, $status ) = @_;

    my $state = $status ? 'normal' : 'disabled';
    # print " $btn_name is $state\n";
    my $tb_btn = $self->_view->get_toolbar_btn($btn_name);
    $tb_btn->configure( -state => $state );
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
