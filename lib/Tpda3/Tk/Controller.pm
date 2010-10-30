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

=head2 _set_event_handler_nb

Separate event handler for NoteBook because must be initialized only
after the NoteBook is (re)created and that happens when a new screen is
required (selected from the applications menu) to load.

=cut

sub _set_event_handler_nb {
    my ( $self, $page ) = @_;

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

Toggle controls appropriate for different states of the application.

There is a distinct state at the beginning when no screen is loaded yet.

=cut

sub toggle_controls {
    my $self = shift;

    my ($toolbars, $attribs) = $self->{_view}->toolbar_names();

    my $mode = $self->_model->get_appmode;

    foreach my $name (@{$toolbars}) {
        my $status = $attribs->{$name}{state}{$mode};
        # print "$name : $status\n";
        $self->_view->toggle_tool($name, $status);
    }

    $self->do_something($mode);

    return;
}

=head2 set_controls_tb

Toggle the toolbar buttons state.

=cut

sub set_controls_tb {
    my ( $self, $btn_name, $status ) = @_;

    my $state = $status ? 'normal' : 'disabled';
    # print " $btn_name is $state\n";

    $self->_view->toggle_tool($btn_name, $state);
}

=head2 do_something

Inspired by an article on Planet Perl
by Ovid Tue 19 Oct 2010 03:32:02 PM EET

=cut

sub do_something {
    my ($self, $mode) = @_;

    my %method_for = (
        add  => 'application_add',
        find => 'application_find',
        idle => 'application_idle',
    );

    if ( my $method_name = $method_for{$mode} ) {
        $self->$method_name();
    }

    return;
}

sub application_idle {
    my ($self, ) = @_;

    print " i am in idle mode\n";

    return;
}

sub application_add {
    my ($self, ) = @_;

    print " i am in add mode\n";

    return;
}

=head2 application_find

When in I<find> mode set status to normal and clear to all controls
from the I<Screen> and change the background to light green.

=cut

sub application_find {
    my ($self, ) = @_;

    print " i am in find mode\n";
    $self->screen_write();

    return;
}

=head2 screen_load

Load screen chosen from the menu.

=cut

sub screen_load {
    my ( $self, $module ) = @_;

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

    # Make new NoteBook widget and setup callback
    $self->_view->create_notebook();
    $self->_set_event_handler_nb('rec');

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

    # Load the new screen configuration
    $self->{_scrcfg} = Tpda3::Config::Screen->new();
    $self->_scrcfg->config_screen_load($self->{_scr_id} . '.conf');

    # Update window geometry
    my $geom = $self->_scrcfg->geom;
    $self->_view->set_geometry($geom);

    # Store currently loaded screen class
    $self->{_curent} = $class;

    my $ctrls = $self->{_screen}->get_controls();

    # Restore default log level
    $self->_log->level($loglevel_old);
}

sub screen_read {
    my ($self, $eobj, $all) = @_;

    # Initialize
    $self->{scrdata} = {};

    # # Entry (widget) objects hash
    # # Entry objects hash EXPERIMENTAL
    # $eobj = $self->get_eobj() unless defined $eobj;
    # # my $eobj = $self->get_eobj();

    # # Scan fields
    # foreach my $field ( keys %{$eobj} ) {

    #     my $etip = $eobj->{$field}[0];    # Type of Entry
    #     my $erw  = $eobj->{$field}[1];    # R/W

    #     # print " Field: $field [$erw]\n";
    #     # RFC
    #     # Skip READ ONLY fields if not FIND status
    #     # Read ALL if $all == true (don't skip)
    #     if ( ! ( $all or $self->is_app_status_find() ) ) {
    #         if ($erw eq 'r') {
    #             print " skiping RO field '$field'\n"
    #                 if $self->{run_ref}{verbose} >= 2;
    #             next;
    #         }
    #     }

    #     # Run appropriate sub according to entry widget type
    #     my $sub_name = "screen_read_entry_$etip";
    #     if ( $self->can($sub_name) ) {
    #         $self->$sub_name( $eobj, $field );
    #     }
    #     else {
    #         print "New type of Entry for reading '$field'?\n";
    #     }
    # }

    return;
}

sub control_read_entry_e {
    my ( $self, $eobj, $field ) = @_;

    # # Tip Entry 'e'
    # unless ( $eobj->{$field}[3] ) {
    #     warn "Undefined: [e] $field\n";
    #     return;
    # }

    # my $value = $eobj->{$field}[3]->get;

    # # Clean '\n' from end
    # $value =~ s/\n$//mg;        # m=multiline

    # # Support search for NULL fields
    # if ($value =~ /NULL/) {
    #     $self->{scrdata}{"$field:b"} = 'NULL';
    # } else {

    #     # Add value if not empty
    #     if ( $value =~ /\S+/ ) {
    #         $self->{scrdata}{"$field:e"} = $value;
    #         # print "Screen (e): $field = $value\n";
    #     } else {
    #         # If update(=edit) status, add NULL value
    #         if ( $self->is_app_status_edit() ) {
    #             $self->{scrdata}{"$field:e"} = undef;
    #             # print "Screen (e): $field = undef\n";
    #         }
    #     }
    # }

    return;
}

=head2 screen_write

Write to all controls from I<Screen>.

=cut

sub screen_write {
    my ($self, $inreg_ref, $sursa) = @_;

    # unless ( ref $inreg_ref ) {
    #     warn "  no records, to write to screen?\n";
    #     return;
    # }

    # Entry objects hash
    # my $eobj = $self->get_eobj();

    # # Save screen status
    # my $stare      = $self->get_app_status();
    # my $stari      = $self->{coord}->get_app_status_def($stare);
    # my $scr_status = $stari->[0];

    # # Swich on to allow write
    # $self->{gui}->sw_ecran('on');

    # Scan and fill Entry widgets
    foreach my $field ( keys %{ $self->{_scrcfg}{fields} } ) {
        print "name is $field:\n";
        my $field_cfg_hr = $self->{_scrcfg}{fields}{$field};
        my $ctrl_ref     = $self->{_screen}->get_controls();

        # Control type?
        my $ctrltype = $field_cfg_hr->{ctrltype};

        my $value = 'T';            # $inreg_ref->{ lc $field };
        print "$field => $value\n";

        if ( defined $value ) {              # TODO: Check this!
            # Trim spaces and \n
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
            $value =~ s/\n$//mg; # m=multiline
        }
        else {
            next;
        }

        #     my $places = $eobj->{$field}[6];
        #     if ( (defined $places ) and ( $places > 0 ) ) {

        #         # If PLACES > 0, format as number
        #         $value = sprintf( "%.${places}f", $value );
        #     }

        my $sub_name = "control_write_entry_$ctrltype";
        print " do $sub_name\n";

        # Run appropriate sub according to control (entry widget) type
        if ( $self->can($sub_name) ) {
            $self->$sub_name( $ctrl_ref, $field, $value );
        }
        else {
            print "New type of Entry for writing '$field'?\n";
        }
    }

    # # Different messages
    # if ( $sursa eq 'db' ) {
    #     # $self->{gui}->refresh_sb('ll','Record loaded', "blue");
    # }
    # elsif ( $sursa eq 're' ) {
    #     $self->{gui}->refresh_sb( 'll', 'Record reloaded', 'blue' );
    # }
    # else {
    #     $self->{gui}->refresh_sb( 'll', 'Restored', 'blue' );
    # }

    # # Restore screen status
    # if ( $scr_status ) {
    #     $self->{gui}->sw_ecran($scr_status);
    # }

    return;
}

sub control_write_entry_e {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    # Tip Entry 'e'
    $ctrl_ref->{$field}[1]->delete( 0, 'end'  );
    $ctrl_ref->{$field}[1]->insert( 0, $value );

    return;
}

sub control_write_entry_t {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    # Tip TextEntry 't'
    $ctrl_ref->{$field}[1]->delete( '1.0', 'end' );
    $ctrl_ref->{$field}[1]->insert( '1.0', $value );

    return;
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
