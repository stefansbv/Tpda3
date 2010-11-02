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

Version 0.05

=cut

our $VERSION = '0.05';

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
    $self->_control_states_set;

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

    $self->toggle_interface_controls;
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
            my $scr_name = $self->{_scr_id} || 'main';
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
            $self->toggle_mode_find();
        }
    );

    #-- Find execute
    $self->_view->get_toolbar_btn('tb_fe')->bind(
        '<ButtonRelease-1>' => sub {
            my $success = 0;
            if ( $self->_model->is_mode('find') ) {
                $success = $self->application_find_exec;
            }
            else {
                print "WARN: Not in find mode\n";
            }
            # $self->toggle_interface_controls if $success;
        }
    );

    #-- Find count
    $self->_view->get_toolbar_btn('tb_fc')->bind(
        '<ButtonRelease-1>' => sub {
            my $records = 0;
            if ( $self->_model->is_mode('find') ) {
                $records = $self->application_find_count;
                print " $records records found\n";
            }
            else {
                print "WARN: Not in find mode\n";
            }
            $self->toggle_interface_controls if $records;
        }
    );

    #-- Add mode
    $self->_view->get_toolbar_btn('tb_ad')->bind(
        '<ButtonRelease-1>' => sub {
            $self->toggle_mode_add();
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

            print "$page tab activated\n";
        },
    );

    return;
}

=head2 control_states_set

Data structure with setting for the different modes of the controls.

=cut

sub _control_states_set {
    my $self = shift;

    $self->{control_states} = {
        off    => {
            state      => 'disabled',
            background => 'disabled_bgcolor',
        },
        on     => {
            state      => 'normal',
            background => 'from_config',
        },
        find   => {
            state      => 'normal',
            background => 'lightgreen',
        },
        edit   => {
            state      => 'from_config',
            background => 'from_config',
        },
    };

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

=head2 screen_load

Load screen chosen from the menu.

=cut

sub screen_load {
    my ( $self, $module ) = @_;

    $self->_model->set_idlemode();

    $self->{_scr_id} = lc $module;           # for instance config filename

    my $loglevel_old = $self->_log->level();

    # Set log level to trace in this sub
    $self->_log->level($Log::Log4Perl::TRACE);

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
    my $name  = ucfirst $self->_cfg->cfname;
    my $class = "Tpda3::App::${name}::${module}";
    (my $file = "$class.pm") =~ s/::/\//g;
    require $file;

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

    # my $ctrls = $self->{_screen}->get_controls();

    # $self->screen_controls_state_to('off');
    # $self->_model->set_idlemode();            ???

    # Restore default log level
    $self->_log->level($loglevel_old);
}

=head2 toggle_interface_controls

Toggle controls appropriate for different states of the application.

TODO: There is a distinct state at the beginning when no screen is
loaded yet.

=cut

sub toggle_interface_controls {
    my $self = shift;

    my ($toolbars, $attribs) = $self->{_view}->toolbar_names();

    my $mode = $self->_model->get_appmode;

    foreach my $name ( @{$toolbars} ) {
        my $status = $attribs->{$name}{state}{$mode};
        $self->_view->toggle_tool( $name, $status );
    }

    return;
}

=head2 set_controls_tb

Toggle the toolbar buttons state.

=cut

sub set_controls_tb {
    my ( $self, $btn_name, $status ) = @_;

    my $state = $status ? 'normal' : 'disabled';

    $self->_view->toggle_tool($btn_name, $state);

    return;
}

=head2 toggle_screen_controls

Screen methods according to mode

=cut

sub toggle_screen_controls {
    my $self = shift;

    $self->do_something( $self->_model->get_appmode );

    return;
}

=head2 do_something

Inspired by an article on Planet Perl
by Ovid Tue 19 Oct 2010 03:32:02 PM EET

Invoke a method acording to the status of the application.

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

=head2 application_idle

when in I<idle> mode set status to I<normal> and clear all controls
content in the I<Screen> than set status of controls to I<disabled>.

=cut

sub application_idle {
    my $self = shift;

    print " i am in idle mode\n";
    $self->screen_controls_state_to('on');
    $self->screen_write();                   # Empty the controls
    $self->screen_controls_state_to('off');

    return;
}

=head2 application_add

When in I<add> mode set status to I<normal> and clear all controls
content in the I<Screen> and change the background to the default
color as specified in the configuration.

=cut

sub application_add {
    my ($self, ) = @_;

    print " i am in add mode\n";

    # Test record data
    my $record_ref = {
        productcode        => 'S700_2047',
        productname        => 'HMS Bounty',
        buyprice           => '39.83',
        msrp               => '90.52',
        productvendor      => 'Unimax Art Galleries',
        productscale       => '1:700',
        quantityinstock    => '3501',
        productline        => 'Ships',
        productlinecode    => '2',
        productdescription => 'Measures 30 inches Long x 27 1/2 inches High x 4 3/4 inches Wide. Many extras including rigging, long boats, pilot house, anchors, etc. Comes with three masts, all square-rigged.',
    };

    $self->screen_controls_state_to('edit');
    $self->screen_write($record_ref);

    return;
}

=head2 application_find

When in I<find> mode set status to I<normal> and clear all controls
content in the I<Screen> and change the background to light green.

=cut

sub application_find {
    my ($self, ) = @_;

    print " i am in find mode\n";
    $self->screen_controls_state_to('on');
    $self->screen_write();                   # Empty the controls
    $self->screen_controls_state_to('find');

    return;
}

=head2 application_find_exec

Execute find

=cut

sub application_find_exec {
    my ($self, ) = @_;

    print " i run find\n";
    $self->screen_read();

    return 1;
}

=head2 application_find_count

Execute find: count

=cut

sub application_find_count {
    my ($self, ) = @_;

    print " i run find count\n";

    $self->screen_read();

    $self->_model->count_records( $self->{scrdata} );

    # $self->screen_controls_state_to('idle');

    return 1;
}

=head2 screen_read

Read screen controls (widgets) and save in a Perl data stucture.

=cut

sub screen_read {
     my ($self, $all) = @_;

     # Initialize
     $self->{scrdata} = {};

     # Scan and write to controls
     foreach my $field ( keys %{ $self->{_scrcfg}{fields} } ) {

         my $field_cfg_hr = $self->{_scrcfg}{fields}{$field};
         my $ctrl_ref     = $self->{_screen}->get_controls();

         # Control type?
         my $ctrltype = $field_cfg_hr->{ctrltype};
         my $ctrlrw   = $field_cfg_hr->{rw};

         print " Field: $field \[$ctrltype\]\n";

         # Skip READ ONLY fields if not FIND status
         # Read ALL if $all == true (don't skip)
         if ( ! ( $all or $self->_model->is_mode('find') ) ) {
             if ($ctrlrw eq 'r') {
                 print " skiping RO field '$field'\n";
                 next;
             }
         }

         # Run appropriate sub according to control (entry widget) type
         my $sub_name = "control_read_$ctrltype";
         if ( $self->can($sub_name) ) {
             $self->$sub_name( $ctrl_ref, $field );
         }
         else {
             print "WARN: New ctrl type '$ctrltype' for reading '$field'?\n";
         }
     }

     return;
}

=head2 control_read_e

Read contents of a Tk::Entry control.

=cut

sub control_read_e {
    my ( $self, $ctrl_ref, $field ) = @_;

    unless ( $ctrl_ref->{$field}[1] ) {
        warn "Undefined: [e] $field\n";
        return;
    }

    my $value = $ctrl_ref->{$field}[1]->get;

    # Clean '\n' from end
    $value =~ s/\n$//mg;    # m=multiline

    # Add value if not empty
    if ( $value =~ /\S+/ ) {
        $self->{scrdata}{$field} = $value;
        print "Screen (e): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{scrdata}{$field} = undef;
            print "Screen (e): $field = undef\n";
        }
    }

    return;
}

=head2 control_read_t

Read contents of a Tk::Text control.

=cut

sub control_read_t {
    my ( $self, $ctrl_ref, $field ) = @_;

    unless ( $ctrl_ref->{$field}[1] ) {
        warn "Undefined: [t] $field\n";
        return;
    }

    my $value = $ctrl_ref->{$field}[1]->get( '0.0', 'end' );

    # Clean '\n' from end
    $value =~ s/\n$//mg;    # m=multiline

    # Add value if not empty
    if ( $value =~ /\S+/ ) {
        $self->{scrdata}{$field} = $value;
        print "Screen (t): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{scrdata}{$field} = undef;
            print "Screen (t): $field = undef\n";
        }
    }

    return;
}

=head2 screen_write

Write record to screen.  Controls must be I<on> to allow write.

=cut

sub screen_write {
    my ($self, $record_ref) = @_;

    unless ( ref $record_ref ) {
        $self->_log->trace("No record data, emptying the screen");
    }

    # Scan and write to controls
    foreach my $field ( keys %{ $self->{_scrcfg}{fields} } ) {

        my $field_cfg_hr = $self->{_scrcfg}{fields}{$field};
        my $ctrl_ref     = $self->{_screen}->get_controls();

        # Control type?
        my $ctrltype = $field_cfg_hr->{ctrltype};

        my $value = $record_ref->{ lc $field };
        if ( defined $value ) {

            # Trim spaces and \n
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
            $value =~ s/\n$//mg;    # m=multiline

            my $decimals = $field_cfg_hr->{decimals};
            if ( $decimals ) {
                if ( $decimals > 0 ) {

                    # if decimals > 0, format as number
                    $value = sprintf( "%.${decimals}f", $value );
                }
            }
        }

        # Run appropriate sub according to control (entry widget) type
        my $sub_name = "control_write_$ctrltype";
        if ( $self->can($sub_name) ) {
            $self->$sub_name( $ctrl_ref, $field, $value );
        }
        else {
            print "WARN: New ctrl type '$ctrltype' for writing '$field'?\n";
        }
    }

    return;
}

=head2 toggle_mode_find

Toggle find mode

=cut

sub toggle_mode_find {
    my $self = shift;

    $self->_model->is_mode('find')
        ? $self->_model->set_idlemode
        : $self->_model->set_findmode;
    $self->toggle_interface_controls;
    $self->toggle_screen_controls;

    return;
}

=head2 toggle_mode_add

Toggle add mode

=cut

sub toggle_mode_add {
    my $self = shift;

    $self->_model->is_mode('add')
        ? $self->_model->set_idlemode
        : $self->_model->set_addmode;
    $self->toggle_interface_controls;
    $self->toggle_screen_controls;

    return;
}

=head2 screen_controls_state_to

Toggle all controls state from I<Screen>.

=cut

sub screen_controls_state_to {
    my ( $self, $state ) = @_;

    my $ctrl_ref       = $self->{_screen}->get_controls();
    my $control_states = $self->control_states($state);

    foreach my $field ( keys %{ $self->{_scrcfg}{fields} } ) {
        my $field_cfg_hr = $self->{_scrcfg}{fields}{$field};

        # Skip for some control types
        # next if $field_cfg_hr->{ctrltype} = '';

        my $ctrl_state = $control_states->{state};
        $ctrl_state = $field_cfg_hr->{state}
            if $ctrl_state eq 'from_config';

        my $bkground = $control_states->{background};
        my $bg_color = $bkground;
        $bg_color = $field_cfg_hr->{bgcolor}
            if $bkground eq 'from_config';
        $bg_color = $self->{_screen}->get_bgcolor()
            if $bkground eq 'disabled_bgcolor';

        # Special case for find mode and fields with 'findtype' set to none
        if ( $state eq 'find' ) {
            if ( $field_cfg_hr->{findtype} eq 'none' ) {
                $ctrl_state = 'disabled';
                $bg_color   = $self->{_screen}->get_bgcolor();
            }
        }

        # Configure controls
        $ctrl_ref->{$field}[1]->configure( -state => $ctrl_state, );
        $ctrl_ref->{$field}[1]->configure( -background => $bg_color, );
    }

    return;
}

=head2 control_write_e

Write to a Tk::Entry widget.  If I<$value> not true, than only delete.

=cut

sub control_write_e {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    # Tip Entry 'e'
    $ctrl_ref->{$field}[1]->delete( 0, 'end'  );
    $ctrl_ref->{$field}[1]->insert( 0, $value ) if $value;

    return;
}

=head2 control_write_t

Write to a Tk::Text widget.  If I<$value> not true, than only delete.

=cut

sub control_write_t {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    # Tip TextEntry 't'
    $ctrl_ref->{$field}[1]->delete( '1.0', 'end' );
    $ctrl_ref->{$field}[1]->insert( '1.0', $value ) if $value;

    return;
}

=head2 control_states

Return settings for controls, according to the state of the application.

=cut

sub control_states {
    my ($self, $state) = @_;

    return $self->{control_states}{$state};
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
