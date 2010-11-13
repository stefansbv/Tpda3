package Tpda3::Tk::Controller;

use strict;
use warnings;

use Data::Dumper;

use Tk;
use Class::Unload;
use Log::Log4perl qw(get_logger :levels);

use Tpda3::Utils;
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

=over

=item _scrcls  - class name of the current screen

=item _scrobj  - current screen object

=item _scrcfg  - screen configs object

=item _scrstr  - module file name in lower case

=back

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
        _scrcls  => undef,
        _scrobj  => undef,
        _scrcfg  => undef,
        _scrstr  => undef,
        _cfg     => Tpda3::Config->instance(),
        _log     => get_logger(),
    };

    bless $self, $class;

    $self->_control_states_init;

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

    return;
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
            my $scr_name = $self->{_scrstr} || 'main';
            $self->_cfg->config_save_instance(
                $scr_name, $self->_view->w_geometry() );
        }
    );

    #-- Connect / disconnect
    $self->_view->get_menu_popup_item('mn_cn')->configure(
        -command => sub {
            $self->_model->toggle_db_connect;
        }
    );

    # Config dialog
    $self->_view->get_menu_popup_item('mn_fn')->configure(
        -command => sub {
            $self->_view->show_config_dialog;
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

    #-- Attach to desktop - pin (save geometry to config file)
    # $self->_view->get_toolbar_btn('tb_at')->bind(
    #     '<ButtonRelease-1>' => sub {
    #         my $scr_name = $self->{_scrstr} || 'main';
    #         $self->_cfg
    #             ->config_save_instance( $scr_name, $self->_view->w_geometry() );
    #     }
    # );

    #-- Find mode
    # $self->_view->get_toolbar_btn('tb_fm')->bind(
    #     '<ButtonRelease-1>' => sub {
    #         $self->toggle_mode_find();
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
    # $self->_view->get_toolbar_btn('tb_qt')->bind(
    #     '<ButtonRelease-1>' => sub {
    #         $self->_view->on_quit;
    #     }
    # );

    #-- Make some key bindings

    $self->_view->bind( '<Alt-x>' => sub { $self->_view->on_quit } );
    $self->_view->bind( '<F7>'    => sub { $self->toggle_mode_find } );
    $self->_view->bind( '<F8>'    => sub { $self->record_find_execute } );

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
            if ($page eq 'lst') {
                $self->set_app_mode('sele');
            }
            else {
                if ( $self->record_load ) {
                    print " loaded\n";
                    $self->set_app_mode('edit');
                }
                else {
                    $self->set_app_mode('idle');
                }
            }
        },
    );

    return;
}

=head2 set_app_mode

Set application mode

=cut

sub set_app_mode {
    my ($self, $mode) = @_;

    $self->_model->set_mode($mode);

    my %method_for = (
        add  => 'on_screen_mode_add',
        find => 'on_screen_mode_find',
        idle => 'on_screen_mode_idle',
        edit => 'on_screen_mode_edit',
        sele => 'on_screen_mode_sele',
    );

    # $self->toggle_interface_controls;

    return unless ref $self->{_scrobj};

    if ( my $method_name = $method_for{$mode} ) {
        $self->$method_name();
    }

    return;
}

=head2 is_record

Return true if a record is loaded in screen.

=cut

sub is_record {
    my $self = shift;

    return;
}

=head2 on_screen_mode_idle

when in I<idle> mode set status to I<normal> and clear all controls
content in the I<Screen> than set status of controls to I<disabled>.

=cut

sub on_screen_mode_idle {
    my $self = shift;

    print " i am in idle mode\n";
    $self->set_screen_controls_state_to('on');
    $self->screen_write();                   # Empty the controls
    $self->set_screen_controls_state_to('off');

    return;
}

=head2 on_screen_mode_add

When in I<add> mode set status to I<normal> and clear all controls
content in the I<Screen> and change the background to the default
color as specified in the configuration.

=cut

sub on_screen_mode_add {
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

    $self->set_screen_controls_state_to('edit');
    $self->screen_write($record_ref);

    return;
}

=head2 on_screen_mode_find

When in I<find> mode set status to I<normal> and clear all controls
content in the I<Screen> and change the background to light green.

=cut

sub on_screen_mode_find {
    my ($self, ) = @_;

    print " i am in find mode\n";
    $self->set_screen_controls_state_to('on');
    $self->screen_write();                   # Empty the controls
    $self->set_screen_controls_state_to('find');

    return;
}

=head2 on_screen_mode_edit

When in I<edit> mode set status to I<normal> and change the background
to the default color as specified in the configuration.

=cut

sub on_screen_mode_edit {
    my $self = shift;

    print " i am in edit mode\n";

    $self->set_screen_controls_state_to('edit');

    return;
}

=head2 on_screen_mode_sele

Noting to do here.

=cut

sub on_screen_mode_sele {
    my $self = shift;

    print " i am in sele mode\n";

    return;
}

=head2 _control_states_init

Data structure with setting for the different modes of the controls.

=cut

sub _control_states_init {
    my $self = shift;

    $self->{control_states} = {
        off  => {
            state      => 'disabled',
            background => 'disabled_bgcolor',
        },
        on   => {
            state      => 'normal',
            background => 'from_config',
        },
        find => {
            state      => 'normal',
            background => 'lightgreen',
        },
        edit => {
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

    return $self->{_scrobj};
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

    $self->{_scrstr} = lc $module;

    my $loglevel_old = $self->_log->level();

    # Set log level to trace in this sub
    $self->_log->level($TRACE);

    # Unload current screen
    if ( $self->{_scrcls} ) {
        Class::Unload->unload( $self->{_scrcls} );

        if ( ! Class::Inspector->loaded( $self->{_scrcls} ) ) {
            $self->_log->trace("Unloaded '$self->{_scrcls}' screen");
        }
        else {
            $self->_log->trace("Error unloading '$self->{_scrcls}' screen");
        }
    }

    # Destroy existing NoteBook widget
    $self->_view->destroy_notebook();

    # Make new NoteBook widget and setup callback
    $self->_view->create_notebook();
    $self->_set_event_handler_nb('rec');
    $self->_set_event_handler_nb('lst');

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
    $self->{_scrobj} = $class->new();

    # Show screen
    my $nb = $self->_view->get_notebook('rec');
    $self->{idobj} = $self->{_scrobj}->run_screen($nb);

    # Load the new screen configuration
    $self->{_scrcfg} = Tpda3::Config::Screen->new();
    $self->_scrcfg->config_screen_load($self->{_scrstr} . '.conf');

    # Load instance config
    $self->_cfg->config_load_instance();

    # Update window geometry form instance config fi exists or from
    # defaults
    my $geom;
    if ( $self->_cfg->can('geometry') ) {
        $geom = $self->_cfg->geometry->{ $self->{_scrstr} };
    }
    else {
        $geom = $self->_scrcfg->geom;
    }
    $self->_view->set_geometry($geom);

    # Store currently loaded screen class
    $self->{_scrcls} = $class;

    $self->set_app_mode('idle');

    $self->_view->make_list_header( $self->_scrcfg->columns );

    # Load lists into JBrowseEntry or JComboBox widgets
    $self->screen_init();

    # Restore default log level
    $self->_log->level($loglevel_old);

    return;
}

=head2 screen_init

Load options in Listbox like widgets - JCombobox support only.

All JBrowseEntry or JComboBox widgets must have a <lists> record in
config to define where the data for the list come from:

 <lists>
     <statuscode>
         table   = status
         code    = code
         name    = description
         default = none
     </statuscode>
 </lists>

=cut

sub screen_init {
    my $self = shift;

    # Entry objects hash
    my $ctrl_ref = $self->{_scrobj}->get_controls();

    foreach my $field ( keys %{ $self->{_scrcfg}{fields} } ) {

        my $field_cfg_hr = $self->{_scrcfg}{fields}{$field};

        # Control config attributes
        my $ctrltype = $field_cfg_hr->{ctrltype};
        my $ctrlrw   = $field_cfg_hr->{rw};

        next unless $ctrl_ref->{$field}[0]; # Undefined widget variable

        my $para = $self->{_scrcfg}{lists}{$field};

        next unless ref $para eq 'HASH';   # Undefined, skip

        # Query table and return data to fill the lists
        my $cod_h_ref = $self->{_model}->get_codes($field, $para);

        if ( $ctrltype eq 'm' ) {

            # JComboBox
            if ( $ctrl_ref->{$field}[1] ) {
                $ctrl_ref->{$field}[1]->removeAllItems();
                while ( my ( $code, $label ) = each( %{$cod_h_ref} ) ) {
                    $ctrl_ref->{$field}[1]
                        ->insertItemAt( 'end', $label, -value => $code );
                }
            }
        }
        elsif ( $ctrltype eq 'l' ) {

            my @lvpairs;
            while ( my ( $code, $label ) = each( %{$cod_h_ref} ) ) {
                push( @lvpairs,{ value => $code, label => $label });
            }

            # MatchingBE
            if ( $ctrl_ref->{$field}[1] ) {
                $ctrl_ref->{$field}[1]->configure(
                    -labels_and_values => \@lvpairs,
                );
            }
        }
    }

    return;
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
        # $self->_view->toggle_tool( $name, $status );
    }

    return;
}

=head2 record_load

Load the selected record in screen

=cut

sub record_load {
    my $self = shift;

    my $value = $self->_view->list_read_selected();

    if ( !$value ) {
        warn "No list selected value";
        return;
    }

    # Table configs
    my $table_hr  = $self->{_scrcfg}->table;
    my $fields_hr = $self->{_scrcfg}->fields;

    my $paramdata = {};

    # Table data
    $paramdata->{table} = $table_hr->{view};   # use view instead of table
    my $field = $table_hr->{pkfld}{name};

    # Construct where, add findtype info
    $paramdata->{where}{$field} = [ $value, $fields_hr->{$field}{findtype} ];
    $paramdata->{pkfld} = $field;

    my $record = $self->_model->query_record($paramdata);

    $self->set_screen_controls_state_to('on');
    $self->screen_write($record);

    return 1;
}

=head2 record_find_execute

Execute find

=cut

sub record_find_execute {
    my $self = shift;

    $self->screen_read();

    # Table configs
    my $table_hr  = $self->{_scrcfg}->table;
    my $fields_hr = $self->{_scrcfg}->fields;
    # Columns configs
    my $cols_ref  = $self->_scrcfg->columns;

    my $paramdata = {};

    # Columns data (for found list)
    my @cols;
    foreach my $col (@{ $cols_ref->{column} } ) {
        push(@cols,  $col->{name} );
    }
    $paramdata->{columns} = \@cols;

    # Add findtype info to screen data
    while ( my ( $field, $value ) = each( %{$self->{scrdata} } ) ) {
        $paramdata->{where}{$field} = [ $value, $fields_hr->{$field}{findtype} ];
    }

    # Table data
    $paramdata->{table}  = $table_hr->{view};   # use view instead of table
    $paramdata->{pkfld} = $table_hr->{pkfld}{name};

    $self->_view->list_init();
    my $record_count = $self->_view->list_populate($paramdata);

    # Set mode to sele if found
    if ($record_count > 0) {
        $self->set_app_mode('sele');
    }

    return;
}

=head2 record_find_count

Execute find: count

=cut

sub record_find_count {
    my $self = shift;

    $self->screen_read();

    # Table configs
    my $table_hr  = $self->{_scrcfg}->table;
    my $fields_hr = $self->{_scrcfg}->fields;

    my $paramdata = {};

    # Add findtype info to screen data
    while ( my ( $field, $value ) = each( %{$self->{scrdata} } ) ) {
        $paramdata->{where}{$field} = [ $value, $fields_hr->{$field}{findtype} ];
    }

    # Table data
    $paramdata->{table} = $table_hr->{view};   # use view instead of table
    $paramdata->{pkfld} = $table_hr->{pkfld}{name};

    $self->_model->count_records($paramdata);

    return;
}

=head2 screen_read

Read screen controls (widgets) and save in a Perl data stucture.

=cut

sub screen_read {
     my ($self, $all) = @_;

     # Initialize
     $self->{scrdata} = {};

     my $ctrl_ref = $self->{_scrobj}->get_controls();

     # Scan and write to controls
     foreach my $field ( keys %{ $self->{_scrcfg}{fields} } ) {

         my $field_cfg_hr = $self->{_scrcfg}{fields}{$field};

         # Control config attributes
         my $ctrltype = $field_cfg_hr->{ctrltype};
         my $ctrlrw   = $field_cfg_hr->{rw};

         # print " Field: $field \[$ctrltype\]\n";

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
             print "WARN: No '$ctrltype' ctrl type for reading '$field'!\n";
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

=head2 control_read_d

Read contents of a Tk::DateEntry control.

=cut

sub control_read_d {
    my ( $self, $ctrl_ref, $field ) = @_;

    unless ( $ctrl_ref->{$field}[1] ) {
        warn "Undefined: [d] $field\n";
        return;
    }

    my $value = ${ $ctrl_ref->{$field}[0] }; # Value from variable

    # Delete '\n' from end
    $value =~ s/\n$//mg;        # m=multiline

    # # Get configured date style and format accordingly
    # my $dstyle = $self->{conf}->get_misc_config('datestyle');
    # if ($dstyle and $value) {

    #     # Date should go to database in ISO format
    #     my ($y,$m,$d) = $self->{utils}->dateentry_parse_date($dstyle, $value);

    #     $value = $self->{utils}->dateentry_format_date('iso', $y, $m, $d);
    # }
    # else {
    #     # default to ISO
    # }

    # Add value if not empty
    if ( $value =~ /\S+/ ) {
        $self->{scrdata}{$field} = $value;
        print "Screen (d): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{scrdata}{$field} = undef;
            print "Screen (d): $field = undef\n";
        }
    }

    return;
}

=head2 control_read_m

Read contents of a Tk::JComboBox control.

=cut

sub control_read_m {
    my ( $self, $ctrl_ref, $field ) = @_;

    unless ( $ctrl_ref->{$field}[1] ) {
        warn "Undefined: [m] $field\n";
        return;
    }

    my $value = ${ $ctrl_ref->{$field}[0] }; # Value from variable

    # Delete '\n' from end
    $value =~ s/\n$//mg;        # m=multiline

    # Add value if not empty
    if ( $value =~ /\S+/ ) {
        $self->{scrdata}{$field} = $value;
        print "Screen (m): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{scrdata}{$field} = undef;
            print "Screen (m): $field = undef\n";
        }
    }

    return;
}

=head2 control_read_l

Read contents of a Tk::MatchingBE control.

=cut

sub control_read_l {
    my ( $self, $ctrl_ref, $field ) = @_;

    unless ( $ctrl_ref->{$field}[1] ) {
        warn "Undefined: [l] $field\n";
        return;
    }

    my $value = $ctrl_ref->{$field}[1]->get_selected_value();

    # Delete '\n' from end
    $value =~ s/\n$//mg;        # m=multiline

    # Add value if not empty
    if ( $value =~ /\S+/ ) {
        $self->{scrdata}{$field} = $value;
        print "Screen (l): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{scrdata}{$field} = undef;
            print "Screen (l): $field = undef\n";
        }
    }

    return;
}

=head2 screen_write

Write record to screen.  Controls must be I<on> to allow write.

No need to empty the screen before calling I<screen_write>, the methods
defined for each control (widget) type should handle the case when
the value parameter is undef.

=cut

sub screen_write {
    my ($self, $record_ref) = @_;

    unless ( ref $record_ref ) {
        $self->_log->trace("No record data, emptying the screen");
    }

    my $ctrl_ref = $self->{_scrobj}->get_controls();

    # Scan and write to controls
    foreach my $field ( keys %{ $self->{_scrcfg}{fields} } ) {

        my $field_cfg_hr = $self->{_scrcfg}{fields}{$field};

        # Control config attributes
        my $ctrltype = $field_cfg_hr->{ctrltype};

        my $value = $record_ref->{ lc $field };
        if ( defined $value ) {

            # Trim spaces and '\n' from the end
            $value = Tpda3::Utils->trim($value);

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
            print "WARN: No '$ctrltype' ctrl type for writing '$field'!\n";
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
        ? $self->set_app_mode('idle')
        : $self->set_app_mode('find');

    return;
}

=head2 toggle_mode_add

Toggle add mode

=cut

sub toggle_mode_add {
    my $self = shift;

    $self->_model->is_mode('add')
        ? $self->set_app_mode('idle')
        : $self->set_app_mode('add');

    return;
}

=head2 set_screen_controls_state_to

Toggle all controls state from I<Screen>.

=cut

sub set_screen_controls_state_to {
    my ( $self, $state ) = @_;

    my $ctrl_ref       = $self->{_scrobj}->get_controls();
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
        $bg_color = $self->{_scrobj}->get_bgcolor()
            if $bkground eq 'disabled_bgcolor';

        # Special case for find mode and fields with 'findtype' set to none
        if ( $state eq 'find' ) {
            if ( $field_cfg_hr->{findtype} eq 'none' ) {
                $ctrl_state = 'disabled';
                $bg_color   = $self->{_scrobj}->get_bgcolor();
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

    $value = q{} unless defined $value; # Empty

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

    $value = q{} unless defined $value; # Empty

    # Tip TextEntry 't'
    $ctrl_ref->{$field}[1]->delete( '1.0', 'end' );
    $ctrl_ref->{$field}[1]->insert( '1.0', $value ) if $value;

    return;
}

=head2 control_write_d

Write to a Tk::DateEntry widget.  If I<$value> not true, than only delete.

=cut

sub control_write_d {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    $value = q{} unless defined $value; # Empty

    # Date should come from database in ISO format
    my ( $y, $m, $d ) = Tpda3::Utils->dateentry_parse_date('iso', $value);

    # Get configured date style and format accordingly
    my $dstyle = 'iso'; #$self->{conf}->get_misc_config('datestyle');
    if ($dstyle and $value) {
        $value = Tpda3::Utils->dateentry_format_date($dstyle, $y, $m, $d);
    }
    else {
        # default to ISO
    }

    ${ $ctrl_ref->{$field}[0] } = $value;

    return;
}

=head2 control_write_m

Write to a Tk::JComboBox widget.  If I<$value> not true, than only delete.

=cut

sub control_write_m {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    $value = q{} unless defined $value; # Empty

    $ctrl_ref->{$field}[1]->setSelected( $value, -type => 'value' );

    return;
}

=head2 control_write_l

Write to a Tk::MatchingBE widget.

=cut

sub control_write_l {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    return unless defined $value; # Empty

    $ctrl_ref->{$field}[1]->set_selected_value($value);

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
