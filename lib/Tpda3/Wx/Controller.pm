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

    $self->_control_states_init;

    $self->_set_event_handlers;

    return $self;
}

=head2 start

Check if we have user and pass, if not, show dialog.  Connect do
database.

=cut

sub start {
    my ($self, ) = @_;

    $self->_log->trace("start");

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
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_fm')->GetId, sub {
        # From add mode forbid find mode
        if ( !$self->_model->is_mode('add') ) {
            $self->toggle_mode_find();
        }
    };

    #-- Find execute
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_fe')->GetId, sub {
        if ( $self->_model->is_mode('find') ) {
            $self->record_find_execute;
        }
        else {
            print "WARN: Not in find mode\n";
        }
    };

    #-- Find count
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_fc')->GetId, sub {
        if ( $self->_model->is_mode('find') ) {
            $self->record_find_count;
        }
        else {
            print "WARN: Not in find mode\n";
        }
    };

    #-- Add mode
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_ad')->GetId, sub {
        $self->toggle_mode_add();
    };

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

=head2 _set_event_handler_nb

Separate event handler for NoteBook because must be initialized only
after the NoteBook is (re)created and that happens when a new screen is
required (selected from the applications menu) to load.

=cut

sub _set_event_handler_nb {
    my ( $self, $page ) = @_;

    $self->_log->trace("Setup event handler on NoteBook for '$page'");

    #- NoteBook events

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

=head2 _set_event_handler_screen

Setup event handlers for screen controls.

TODO: Should setup event handlers only for widgets that actually exists
in the screen, regardless of the screen type.

=cut

sub _set_event_handler_screen {
    my $self = shift;

    $self->_log->trace("Setup event handler for screen");
    #- screen ToolBar

    #-- Add row button
    $self->{_scrobj}->get_toolbar_btn('tb2ad')->bind(
        '<ButtonRelease-1>' => sub {
            $self->add_tmatrix_row();
        }
    );

    #-- Remove row button
    $self->{_scrobj}->get_toolbar_btn('tb2rm')->bind(
        '<ButtonRelease-1>' => sub {
            $self->remove_tmatrix_row();
        }
    );

    return;
}

=head2 setup_lookup_bindings

Create bindings for widgets as defined in the configuration file in
the I<bindings> section.

For example in orders.conf:

  <bindings>
    <customername>
      table = customers
      field = customernumber
    </customername>
  </bindings>

This will create a binding for the I<customername> widget, alowing the
user to lookup the I<customernumber> in the I<customer> table.

=cut

sub setup_lookup_bindings {
    my $self = shift;

    my $dict     = Tpda3::Lookup->new;
    my $ctrl_ref = $self->{_scrobj}->get_controls();
    my $bindings = $self->_scrcfg->bindings;

    $self->_log->trace("Setup binding for configured widgets");

    foreach my $lookup ( keys %{$bindings} ) {
        unless ( $ctrl_ref->{$lookup}[1] ) {
            # Skip nonexistent
            $self->_log->trace("Wrong binding config for '$lookup'");
            next;
        }

        $self->_log->trace("Setup binding for '$lookup'");

        my $para = {                     # parameter for Search dialog
            table  => $bindings->{$lookup}{table},
            lookup => $lookup,
        };

        # Add lookup field to columns
        my $field_cfg = $self->_scrcfg->maintable->{columns}{$lookup};
        my @cols;
        my $rec = {};
        $rec->{$lookup} = {
            width => $field_cfg->{width},
            label => $field_cfg->{label},
            order => $field_cfg->{order},
        };
        push @cols, $rec;

        if ( ref $bindings->{$lookup}{field} ) {

            # Multiple fields returned as array
            foreach my $fld ( @{ $bindings->{$lookup}{field} } ) {
                my $field_cfg = $self->_scrcfg->maintable->{columns}{$fld};
                my $rec = {};
                $rec->{$fld} = {
                    width => $field_cfg->{width},
                    label => $field_cfg->{label},
                    order => $field_cfg->{order},
                };
                push @cols, $rec;
            }
        }
        else {
            # One field, no array
            my $fld       = $bindings->{$lookup}{field};
            my $field_cfg = $self->_scrcfg->maintable->{columns}{$fld};
            my $rec = {};
            $rec->{$fld} = {
                width => $field_cfg->{width},
                label => $field_cfg->{label},
                order => $field_cfg->{order},
            };
            push @cols, $rec;
        }

        $para->{columns} = [@cols];

        $ctrl_ref->{$lookup}[1]->bind(
            '<KeyPress-Return>' => sub {
                my $record = $dict->lookup( $self->_view, $para );
                $self->screen_write($record, 'fields');
            }
        );
    }

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

    $self->toggle_interface_controls;

    return unless ref $self->{_scrobj};

    # TODO: Should this be called on all screens?
    $self->toggle_screen_interface_controls;

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

    $self->screen_write(undef, 'clear');      # Empty the main controls
    $self->control_tmatrix_write();
    $self->controls_state_set('off');
    $self->_log->trace("Mode has changed to 'idle'");

    return;
}

=head2 on_screen_mode_add

When in I<add> mode set status to I<normal> and clear all controls
content in the I<Screen> and change the background to the default
color as specified in the configuration.

=cut

sub on_screen_mode_add {
    my ($self, ) = @_;

    $self->_log->trace("Mode has changed to 'add'");

    # Test record data
    # my $record_ref = {
    #     productcode        => 'S700_2047',
    #     productname        => 'HMS Bounty',
    #     buyprice           => '39.83',
    #     msrp               => '90.52',
    #     productvendor      => 'Unimax Art Galleries',
    #     productscale       => '1:700',
    #     quantityinstock    => '3501',
    #     productline        => 'Ships',
    #     productlinecode    => '2',
    #     productdescription => 'Measures 30 inches Long x 27 1/2 inches High x 4 3/4 inches Wide. Many extras including rigging, long boats, pilot house, anchors, etc. Comes with three masts, all square-rigged.',
    # };

    $self->screen_write(undef, 'clear');
    $self->control_tmatrix_write();
    $self->controls_state_set('edit');

    return;
}

=head2 on_screen_mode_find

When in I<find> mode set status to I<normal> and clear all controls
content in the I<Screen> and change the background to light green.

=cut

sub on_screen_mode_find {
    my ($self, ) = @_;

    $self->screen_write(undef, 'clear'); # Empty the controls
    $self->control_tmatrix_write();
    $self->controls_state_set('find');
    $self->_log->trace("Mode has changed to 'find'");

    return;
}

=head2 on_screen_mode_edit

When in I<edit> mode set status to I<normal> and change the background
to the default color as specified in the configuration.

=cut

sub on_screen_mode_edit {
    my $self = shift;

    $self->controls_state_set('edit');
    $self->_log->trace("Mode has changed to 'edit'");

    return;
}

=head2 on_screen_mode_sele

Noting to do here.

=cut

sub on_screen_mode_sele {
    my $self = shift;

    $self->_log->trace("Mode has changed to 'sele'");

    return;
}

=head2 _control_states_init

Data structure with setting for the different modes of the controls.

=cut

sub _control_states_init {
    my $self = shift;

    $self->{control_states} = {
        off  => {
            state      => 0,
            background => 'disabled_bgcolor',
        },
        on   => {
            state      => 1,
            background => 'from_config',
        },
        find => {
            state      => 1,
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

=head2 screen_module_load

Load screen chosen from the menu.

=cut

sub screen_module_load {
    my ( $self, $module ) = @_;

    $self->{_scrstr} = lc $module;

    # Load the new screen configuration
    $self->{_scrcfg} = Tpda3::Config::Screen->new();
    $self->_scrcfg->config_screen_load($self->{_scrstr} . '.conf');

    # Destroy existing NoteBook widget
    $self->_view->destroy_notebook();

    # Unload current screen
    if ( $self->{_scrcls} ) {
        Class::Unload->unload( $self->{_scrcls} );
        # Class::Unload->unload( 'Tpda3::Config::Screen' );

        if ( ! Class::Inspector->loaded( $self->{_scrcls} ) ) {
            $self->_log->trace("Unloaded '$self->{_scrcls}' screen");
        }
        else {
            $self->_log->trace("Error unloading '$self->{_scrcls}' screen");
        }
    }

    # Make new NoteBook widget and setup callback
    $self->_view->create_notebook();
    $self->_set_event_handler_nb('rec');
    $self->_set_event_handler_nb('lst');

    # The application and class names
    #my $name  = ucfirst $self->_cfg->cfname;
    my $name = $self->_cfg->application->{module};
    my $class = "Tpda3::App::${name}::${module}";
    (my $file = "$class.pm") =~ s/::/\//g;
    require $file;

    unless ($class->can('run_screen') ) {
        my $msg = "Error! Screen '$class' can not 'run_screen'";
        print "$msg\n";
        $self->_log->error($msg);

        return;
    }

    # New screen instance
    $self->{_scrobj} = $class->new();
    $self->_log->trace("New screen instance: $module");

    # Show screen
    my $nb = $self->_view->get_notebook('rec');
    $self->{_scrobj}->run_screen($nb);
    $self->_log->trace("Show screen $module");

    my $screen_type = $self->_scrcfg->screen->{type};

    # Load instance config
    $self->_cfg->config_load_instance();

    # Update window geometry from instance config if exists or from
    # defaults
    my $geom;
    if ( $self->_cfg->can('geometry') ) {
        $geom = $self->_cfg->geometry->{ $self->{_scrstr} };
        unless ($geom) {
            $geom = $self->_scrcfg->screen->{geom};
        }
    }
    else {
        $geom = $self->_scrcfg->screen->{geom};
    }
    $self->_view->set_geometry($geom);

    # Event handlers
    $self->_set_event_handler_screen() if $screen_type eq 'tablematrix';
    #-- Lookup bindings
    $self->setup_lookup_bindings();

    # Store currently loaded screen class
    $self->{_scrcls} = $class;

    $self->set_app_mode('idle');

    # List header
    my @header_cols = @{ $self->_scrcfg->found_cols->{col} };
    my $fields = $self->_scrcfg->maintable->{columns};
    my $header_attr = {};
    foreach my $col ( @header_cols ) {
        $header_attr->{$col} = {
            label =>  $fields->{$col}{label},
            width =>  $fields->{$col}{width},
            order =>  $fields->{$col}{order},
        };
    }

    $self->_view->make_list_header( \@header_cols, $header_attr );

    if ($screen_type eq 'tablematrix') {
        # TableMatrix header
        my $tm_fields = $self->_scrcfg->table->{columns};
        my $tm_object = $self->{_scrobj}->get_tm_controls('tm1');
        $self->_view->make_tablematrix_header( $tm_object, $tm_fields );
    }

    # Load lists into JBrowseEntry or JComboBox widgets
    $self->screen_init();

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
    return unless scalar keys %{$ctrl_ref};

    foreach my $field ( keys %{ $self->_scrcfg->maintable->{columns} } ) {

        # Control config attributes
        my $fld_cfg  = $self->_scrcfg->maintable->{columns}{$field};
        my $ctrltype = $fld_cfg->{ctrltype};
        my $ctrlrw   = $fld_cfg->{rw};

        next unless $ctrl_ref->{$field}[0]; # Undefined widget variable

        my $para = $self->_scrcfg->{lists}{$field};

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

Toggle controls (tool bar buttons) appropriate for different states of
the application.

=cut

sub toggle_interface_controls {
    my $self = shift;

    my ($toolbars, $attribs) = $self->{_view}->toolbar_names();

    my $mode = $self->_model->get_appmode;

    foreach my $name ( @{$toolbars} ) {
        my $status = $attribs->{$name}{state}{$mode};
        $self->_view->enable_tool( $name, $status );
    }

    return;
}

=head2 toggle_screen_interface_controls

Toggle screen controls (toolbar buttons) appropriate for different
states of the application.

Curently used by the toolbar buttons attached to the TableMatrix
widget in some screens.

=cut

sub toggle_screen_interface_controls {
    my $self = shift;

    # Get ToolBar button atributes
    my $attribs  = $self->_cfg->toolbar2;
    my $toolbars = Tpda3::Utils->sort_hash_by_id($attribs);

    my $mode = $self->_model->get_appmode;

    foreach my $name ( @{$toolbars} ) {
        my $state = $attribs->{$name}{state}{$mode};
        $self->{_scrobj}->enable_tool($name, $state);
    }

    return;
}

=head2 record_load

Load the selected record in screen

=cut

sub record_load {
    my $self = shift;

    my $value = $self->_view->list_read_selected();

    if ( ! defined $value ) {
        print "No value selected in list";
        return;
    }

    # Table metadata
    my $table_hr  = $self->_scrcfg->maintable;
    my $fields_hr = $table_hr->{columns};
    my $pk_col    = $table_hr->{pkcol}{name};

    # Construct where, add findtype info
    my $params = {};
    $params->{table} = $table_hr->{view};   # use view instead of table
    $params->{where}{$pk_col} = [ $value, $fields_hr->{$pk_col}{findtype} ];
    $params->{pkcol} = $pk_col;

    my $record = $self->_model->query_record($params);

    $self->screen_write($record);

    my $screen_type = $self->_scrcfg->screen->{type};
    if ($screen_type eq 'tablematrix') {

        # Table metadata
        my $table_hr  = $self->_scrcfg->table;
        my $fields_hr = $table_hr->{columns};

        # Construct where, add findtype info
        $params->{table} = $table_hr->{view};
        $params->{fkcol} = $table_hr->{fkcol}{name};

        my $records = $self->_model->query_record_batch($params);

        $self->control_tmatrix_write($records);
    }

    return 1;
}

=head2 record_find_execute

Execute search.

Searching by DATE

Date type entry fields are a special case. Note that type_of_entry='d'
and the variable name begins with a 'd'. If the user enters a year
like '2009' (four digits) in a date field than the WHERE Clause will
look like this:

  WHERE (EXTRACT YEAR FROM b_date) = 2009

Another case is where the user enters a year and a month separated by
a slash, a point or a dash. The order can be reversed too: month-year

  2009.12 or 2009/12 or 2009-12
  12.2009 or 12/2009 or 12-2009

The result WHERE Clause has to be the same:

  WHERE EXTRACT (YEAR FROM b_date) = 2009 AND
        EXTRACT (MONTH FROM b_date) = 12

The case when an entire date is entered is treated as a whole string
and is processed by the DB SQL server differently by vendor.

  WHERE b_date = '2009-12-31'

TODO: convert the date string to ISO before building the WHERE Clause

=cut

sub record_find_execute {
    my $self = shift;

    $self->screen_read();

    # Table configs
    my $table_hr  = $self->_scrcfg->maintable;
    my $fields_hr = $self->_scrcfg->maintable->{columns};

    my $params = {};

    # Columns data (for found list)
    $params->{columns} = $self->_scrcfg->found_cols->{col};

    # Add findtype info to screen data
    while ( my ( $field, $value ) = each( %{$self->{scrdata} } ) ) {
        $params->{where}{$field} = [ $value, $fields_hr->{$field}{findtype} ];
    }

    # Table data
    $params->{table} = $table_hr->{view};   # use view instead of table
    $params->{pkcol} = $table_hr->{pkcol}{name};

    $self->_view->list_init();
    my $record_count = $self->_view->list_populate($params);

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
    my $table_hr  = $self->_scrcfg->maintable;
    my $fields_hr = $self->_scrcfg->maintable->{columns};

    my $params = {};

    # Add findtype info to screen data
    while ( my ( $field, $value ) = each( %{$self->{scrdata} } ) ) {
        $params->{where}{$field} = [ $value, $fields_hr->{$field}{findtype} ];
    }

    # Table data
    $params->{table} = $table_hr->{view};   # use view instead of table
    $params->{pkcol} = $table_hr->{pkcol}{name};

    $self->_model->count_records($params);

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
     return unless scalar keys %{$ctrl_ref};

     # Scan and write to controls
     foreach my $field ( keys %{ $self->_scrcfg->maintable->{columns} } ) {

         my $fld_cfg = $self->_scrcfg->maintable->{columns}{$field};

         # Control config attributes
         my $ctrltype = $fld_cfg->{ctrltype};
         my $ctrlrw   = $fld_cfg->{rw};

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

    # Add value if not empty
    if ( $value =~ /\S+/ ) {

        # Clean '\n' from end
        $value =~ s/\n$//mg;    # m=multiline

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

    # Add value if not empty
    if ( $value =~ /\S+/ ) {

        # Clean '\n' from end
        $value =~ s/\n$//mg;    # m=multiline

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

    # Value from variable or empty string
    my $value = ${ $ctrl_ref->{$field}[0] } || q{};

    # # Get configured date style and format accordingly
    # my $dstyle = $self->{conf}->get_misc_config('datestyle');
    # if ($dstyle and $value) {

    #     # Skip date formatting for find mode
    #     if ( !$self->is_app_status_find ) {

    #         # Date should go to database in ISO format
    #         my ( $y, $m, $d ) =
    #           $self->{utils}->dateentry_parse_date( $dstyle, $value );

    #         $value = $self->{utils}->dateentry_format_date( 'iso', $y, $m, $d );
    #     }
    # }
    # else {
    #     # default to ISO
    # }

    # Add value if not empty
    if ( $value =~ /\S+/ ) {

        # Delete '\n' from end
        $value =~ s/\n$//mg;        # m=multiline

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

    # Add value if not empty
    if ( $value =~ /\S+/ ) {

        # Delete '\n' from end
        $value =~ s/\n$//mg;        # m=multiline

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

    my $value = $ctrl_ref->{$field}[1]->get_selected_value() || q{};

    # Add value if not empty
    if ( $value =~ /\S+/ ) {

        # Delete '\n' from end
        $value =~ s/\n$//mg;        # m=multiline

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

Write record to screen.  It first turns controls I<on> to allow write.

First parameter is a hash reference with the field names as keys.

The second parameter is optional and can have the following values:

=over

=item record - write the entire record to controls, undef values too

=item fields - write only the fields present in the hash reference

=item clear  - clear all widgets contents

=back

If the second parameter is present, obviously the first has to be
present to, at least as 'undef'.

=cut

sub screen_write {
    my ($self, $record_ref, $option) = @_;

    $option ||= 'record';             # default option record

    # $self->_log->trace("Write '$option' screen controls");

    my $ctrl_ref = $self->{_scrobj}->get_controls();

    return unless scalar keys %{$ctrl_ref};  # no controls?

  FIELD:
    foreach my $field ( keys %{ $self->_scrcfg->maintable->{columns} } ) {

        my $fld_cfg = $self->_scrcfg->maintable->{columns}{$field};

        my $ctrl_state = $ctrl_ref->{$field}[1]->cget( -state );
        $ctrl_ref->{$field}[1]->configure( -state => 'normal' );

        # Control config attributes
        my $ctrltype = $fld_cfg->{ctrltype};

        my $value;
        if ( $option eq 'record' ) {
            $value = $record_ref->{ lc $field };
        }
        elsif ( $option eq 'fields' ) {
            $value = $record_ref->{ lc $field };
            next FIELD if !$value;
        }
        elsif ( $option eq 'clear' ) {

            # nothing here
        }
        else {
            warn "Should never get here!\n";
        }

        if ($value) {

            # Trim spaces and '\n' from the end
            $value = Tpda3::Utils->trim($value);

            # Should make $value = 0, than format as number ?
            my $decimals = $fld_cfg->{decimals};
            if ($decimals) {
                if ( $decimals > 0 ) {

                    # if decimals > 0, format as number
                    $value = sprintf( "%.${decimals}f", $value );
                }
            }
        }

        # Run appropriate sub according to control (entry widget) type
        my $sub_name = qq{control_write_$ctrltype};
        if ( $self->can($sub_name) ) {
            $self->$sub_name( $ctrl_ref, $field, $value );
        }
        else {
            print "WARN: No '$ctrltype' ctrl type for writing '$field'!\n";
        }

        # Restore state
        $ctrl_ref->{$field}[1]->configure( -state => $ctrl_state );
    }

    # $self->_log->trace("Write finished (restored controls states)");

    return;
}

=head2 control_tmatrix_write

Write data to TableMatrix widget

=cut

sub control_tmatrix_write {
    my ( $self, $records ) = @_;

    my $tm_object = $self->{_scrobj}->get_tm_controls('tm1');
    my $xtvar;
    if ($tm_object) {
        $xtvar = $tm_object->cget( -variable );
    }
    else {

        # Just ignore :)
        return;
    }

    my $row = 1;

    #- Scan and write to table

    foreach my $record ( @{$records} ) {
        foreach my $field ( keys %{ $self->_scrcfg->table->{columns} } ) {
            my $fld_cfg = $self->_scrcfg->table->{columns}{$field};

            my $value = $record->{$field};
            $value = q{} unless defined $value;    # Empty
            $value =~ s/[\n\t]//g;                 # Delete control chars

            my ( $col, $type, $width, $places ) =
              @$fld_cfg{'id','content','width','decimals'}; # hash slice

            if ( $type =~ /digit/ ) {
                $value = 0 unless $value;
                if ( defined $places ) {

                    # Daca SCALE >= 0, Formatez numarul
                    $value = sprintf( "%.${places}f", $value );
                }
                else {
                    $value = sprintf( "%.0f", $value );
                }
            }

            $xtvar->{"$row,$col"} = $value;

        }

        $row++;
    }

    # Refreshing the table...
    $tm_object->configure( -rows => $row );

    # TODO: make a more general sub
    # Execute sub defined in screen Workaround for a DBD::InterBase
    # problem related to big decimals?  The view doesn't compute
    # corectly the value and the VAT when accesed from perl but only
    # from flamerobin ...  Check if sub exists first
    # Fixed with patch from:
    # http://github.com/pilcrow/perl-dbd-interbase.git
    # if ( $self->{screen}->can('recalculare_factura') ) {
    #     $self->{screen}->recalculare_factura();
    # }

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

=head2 controls_state_set

Toggle all controls state from I<Screen>.

=cut

sub controls_state_set {
    my ( $self, $state ) = @_;

    $self->_log->trace("Screen controls state is '$state'");

    my $ctrl_ref = $self->{_scrobj}->get_controls();
    return unless scalar keys %{$ctrl_ref};

    my $control_states = $self->control_states($state);

    return unless defined $self->_scrcfg;

    foreach my $field ( keys %{ $self->{_scrcfg}->maintable->{columns} } ) {

        my $fld_cfg = $self->{_scrcfg}->maintable->{columns}{$field};

        # Skip for some control types
        # next if $fld_cfg->{ctrltype} = '';

        my $ctrl_state = $control_states->{state};
        print "ctrl_state is $ctrl_state\n";
        $ctrl_state = $fld_cfg->{state}
            if $ctrl_state eq 'from_config';

        my $bkground = $control_states->{background};
        my $bg_color = $bkground;
        $bg_color = $fld_cfg->{bgcolor}
            if $bkground eq 'from_config';
        $bg_color = $self->{_scrobj}->get_bgcolor()
            if $bkground eq 'disabled_bgcolor';

        # Special case for find mode and fields with 'findtype' set to none
        if ( $state eq 'find' ) {
            if ( $fld_cfg->{findtype} eq 'none' ) {
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

    if ( $value ) {
        $ctrl_ref->{$field}[1]->setSelected( $value, -type => 'value' );
    }
    else {
        ${ $ctrl_ref->{$field}[0] } = q{}; # Empty
    }

    return;
}

=head2 control_write_l

Write to a Tk::MatchingBE widget.  Warning: cant write an empty value,
must test with a key -> value pair like 'not set' => '?empty?'.

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

=head2 add_tmatrix_row

Table matrix methods.  Add TableMatrix row.

=cut

# sub add_tmatrix_row {
#     my ($self, $valori_ref) = @_;

#     my $xt = $self->{_scrobj}->get_tm_controls('tm1');

#     unless ( $self->_model->is_mode('add')
#                  || $self->_model->is_mode('edit') ) {
#         return;
#     }

#     $xt->configure( state => 'normal' );     # Stare normala

#     $xt->insertRows('end');
#     my $r = $xt->index( 'end', 'row' );

#     $xt->set( "$r,0", $r );     # Daca am parametru 2, introduc datele
#     my $c = 1;
#     if ( ref($valori_ref) eq 'ARRAY' ) {

#         # Inserez datele
#         foreach my $valoare ( @{$valori_ref} ) {
#             if ( defined $valoare ) {
#                 $xt->set( "$r,$c", $valoare );
#             }
#             $c++;
#         }
#     }

#     # Focus la randul nou inserat, coloana 1
#     $xt->focus;
#     $xt->activate("$r,1");
#     $xt->see("$r,1");

#     return;
# }

=head2 remove_tmatrix_row

Delete TableMatrix row

=cut

# sub remove_tmatrix_row {
#     my $self = shift;

#     my $xt = $self->{_scrobj}->get_tm_controls('tm1');

#     unless ( $self->_model->is_mode('add')
#                  || $self->_model->is_mode('edit') ) {
#         return;
#     }

#     $xt->configure( state => 'normal' );     # Stare normala

#     my $r;
#     eval {
#         $r = $xt->index( 'active', 'row' );

#         if ( $r >= 1 ) {
#             $xt->deleteRows( $r, 1 );
#         }
#         else {
#             # my $textstr = "Select a row, first";
#             # $self->{mw}->{dialog1}->configure( -text => $textstr );
#             # $self->{mw}->{dialog1}->Show();
#         }
#     };
#     if ($@) {
#         warn "Warning: $@";
#     }

#     $self->renum_tmatrix_row($xt);           # renumerotare randuri

#     # Calcul total desfasurator; check if sub exists first
#     # if ( $self->{tpda}->{screen_curr}->can('calcul_total_des_tm2') ) {
#     #     $self->{tpda}->{screen_curr}->calcul_total_des_tm2;
#     # }

#     return $r;
# }

=head2 renum_tmatrix_row

Renumber TableMatrix rows

=cut

# sub renum_tmatrix_row {
#     my ($self, $xt) = @_;

#     # print " renum\n";

#     my $r = $xt->index( 'end', 'row' );

#     # print "# randuri = $r\n";

#     if ( $r >= 1 ) {
#         foreach my $i ( 1 .. $r ) {
#             $xt->set( "$i,0", $i );    # !!!! ????  method causing leaks?
#         }
#     }

#     return;
# }

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
