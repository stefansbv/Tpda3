package Tpda3::Wx::Controller;

use strict;
use warnings;
use utf8;
use Carp;

use Wx q{:everything};
use Wx::Event qw(EVT_CLOSE EVT_CHOICE EVT_MENU EVT_TOOL EVT_TIMER
    EVT_TEXT_ENTER EVT_AUINOTEBOOK_PAGE_CHANGED
    EVT_LIST_ITEM_ACTIVATED);

use Scalar::Util qw(blessed);
use List::MoreUtils qw{uniq};
use Class::Unload;
use Log::Log4perl qw(get_logger :levels);
use Storable qw (store retrieve);
use Math::Symbolic;
use Hash::Merge qw(merge);

use Tpda3::Utils;
use Tpda3::Config;
use Tpda3::Model;
use Tpda3::Wx::App;
use Tpda3::Wx::View;
use Tpda3::Lookup;

use File::Basename;
use File::Spec::Functions qw(catfile);

=head1 NAME

Tpda3::Wx::Controller - The Controller

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.04';

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
        _rscrcls => undef,
        _rscrobj => undef,
        _dscrcls => undef,
        _dscrobj => undef,
        _tblkeys => undef,
        _scrdata => undef,
        _cfg     => Tpda3::Config->instance(),
        _log     => get_logger(),
    };

    bless $self, $class;

    $self->_log->trace('Controller new');

    $self->_control_states_init;

    $self->_set_event_handlers;

    $self->_set_menus_enable(0);    # disable find mode menus

    $self->_check_app_menus();      # disable if no screen

    return $self;
}

=head2 start

This will run before the main loop.  If no user and password than
start a timer. A event handler for the timer will show the login
dialog.

Else connect to the database.

=cut

sub start {
    my $self = shift;

    if ( !$self->_cfg->user or !$self->_cfg->pass ) {
        $self->{timer} = Wx::Timer->new( $self->_view, 1 );
        $self->{timer}->Start( 500, 1 );    # one shot
    }
    else {
        $self->_model->toggle_db_connect();
    }

    return;
}

=head2 start_delayed

Check if we have user and pass, if not, show dialog.

Connect to the database.

=cut

sub start_delayed {
    my $self = shift;

    $self->_log->trace('Starting ...');

    require Tpda3::Wx::Dialog::Login;
    $self->{dlg} = Tpda3::Wx::Dialog::Login->new();

    my $dialog = $self->{dlg}->login_dialog( $self->_view );
    if ( $dialog->ShowModal != &Wx::wxID_CANCEL ) {
        my ( $user, $pass ) = $dialog->get_login();
        $self->_cfg->user($user);
        $self->_cfg->pass($pass);
    }

    if ( $self->_cfg->user and $self->_cfg->pass ) {

        # Connect to database
        $self->_model->toggle_db_connect();
    }
    else {
        $self->_view->on_quit;
    }

    $self->{timer}->Destroy();
    $self->_log->trace('Started');

    return;
}

=head2 about

The About dialog

=cut

sub about {
    my $self = shift;

    Wx::MessageBox(
        "Tpda3 - v0.03\n(C) 2010-2012 Stefan Suciu\n\n"
            . " - WxPerl $Wx::VERSION\n" . " - "
            . Wx::wxVERSION_STRING,
        'About Tpda3',
        wxOK | wxICON_INFORMATION | wxCENTRE,
        $self->_view,
    );
}

=head2 _set_event_handlers

Setup event handlers for the interface.

=cut

sub _set_event_handlers {
    my $self = shift;

    $self->_log->trace('Setup event handlers');

    #- Frame

    # $self->{timer} = Wx::Timer->new( $self->_view, 1 );
    # $self->{timer}->Start(1000, 1); # one shot

    EVT_TIMER $self->_view, 1, sub { $self->start_delayed(); };

    # Deep recursion on subroutine "Tpda3::Wx::View::on_quit" ???
    # Wx::Event::EVT_CLOSE $self->_view, sub {
    #     $self->_view->on_quit;
    # };

    #- Base menu

    EVT_MENU $self->_view, wxID_ABOUT, sub {
        $self->about();
    };    # Change icons !!!

    EVT_MENU $self->_view, wxID_EXIT, sub {
        $self->_view->on_quit;
    };

    #-- Toggle mode find
    EVT_MENU $self->_view, 50011, sub {
        if ( !$self->_model->is_mode('add') ) {
            $self->toggle_mode_find();
        }
    };

    #-- Execute search
    EVT_MENU $self->_view, 50012, sub {
        if ( $self->_model->is_mode('find') ) {
            $self->record_find_execute;
        }
        else {
            print "WARN: Not in find mode\n";
        }
    };

    #-- Execute count
    EVT_MENU $self->_view, 50013, sub {
        if ( $self->_model->is_mode('find') ) {
            $self->record_find_count;
        }
        else {
            print "WARN: Not in find mode\n";
        }
    };

    #- Custom application menu from menu.yml

    my $appmenus = $self->_view->get_app_menus_list();
    foreach my $item ( @{$appmenus} ) {
        my $menu_id = $self->_view->get_menu_popup_item($item)->GetId;
        EVT_MENU $self->_view, $menu_id, sub {
            $self->screen_module_load($item);
            }
    }

    #- Toolbar

    #-- Attach to desktop - pin (save geometry to config file)
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_at')->GetId,
        sub {
        my $scr_name = $self->{_scrstr} || 'main';
        $self->_cfg->config_save_instance( $scr_name,
            $self->_view->w_geometry, );
        };

    #-- Find mode toggle
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_fm')->GetId,
        sub {

        # From add mode forbid find mode
        if ( !$self->_model->is_mode('add') ) {
            $self->toggle_mode_find();
        }
        };

    #-- Find execute
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_fe')->GetId,
        sub {
        if ( $self->_model->is_mode('find') ) {
            $self->record_find_execute;
        }
        else {
            print "WARN: Not in find mode\n";
        }
        };

    #-- Find count
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_fc')->GetId,
        sub {
        if ( $self->_model->is_mode('find') ) {
            $self->record_find_count;
        }
        else {
            print "WARN: Not in find mode\n";
        }
        };

    #-- Reload
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_rr')->GetId,
        sub {
        if ( $self->_model->is_mode('edit') ) {
            $self->record_reload();
        }
        else {
            print "WARN: Not in edit mode\n";
        }
        };

    #-- Add mode
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_ad')->GetId,
        sub {
        $self->toggle_mode_add();
        };

    #-- Quit
    EVT_TOOL $self->_view, $self->_view->get_toolbar_btn('tb_qt')->GetId,
        sub {
        $self->_view->on_quit;
        };

    #-- Make more key bindings (alternative to the menu entries)

    # $self->_view->SetAcceleratorTable(
    #     Wx::AcceleratorTable->new(
    #         [ wxACCEL_NORMAL, WXK_F7, 50011 ],
    #         [ wxACCEL_NORMAL, WXK_F8, 50012 ],
    #     )
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

    $self->_log->trace('Setup event handler on NoteBook');

    #- NoteBook events

    my $nb = $self->_view->get_notebook();

    EVT_AUINOTEBOOK_PAGE_CHANGED $self->_view, $nb->GetId, sub {
        my $current_page = $nb->GetSelection();
        if ( $current_page == 1 ) {    # 'lst'
            $self->set_app_mode('sele');
        }
        else {
            if ( $self->record_load_new ) {
                $self->set_app_mode('edit');
            }
            else {
                $self->set_app_mode('idle');
            }
        }
    };

    #-- Enter on list item activates record page
    EVT_LIST_ITEM_ACTIVATED $self->_view, $self->_view->get_listcontrol, sub {
        $self->_view->get_notebook->SetSelection(0);    # 'rec'
    };

    return;
}

=head2 _set_event_handler_screen

Setup event handlers for screen controls.

TODO: Should setup event handlers only for widgets that actually exists
in the screen, regardless of the screen type.

=cut

sub _set_event_handler_screen {
    my $self = shift;

    $self->_log->trace('Setup event handler for screen');

    #- screen ToolBar

    # #-- Add row button
    # $self->_screen->get_toolbar_btn('tb2ad')->bind(
    #     '<ButtonRelease-1>' => sub {
    #         $self->add_tmatrix_row();
    #     }
    # );

    # #-- Remove row button
    # $self->_screen->get_toolbar_btn('tb2rm')->bind(
    #     '<ButtonRelease-1>' => sub {
    #         $self->remove_tmatrix_row();
    #     }
    # );

    return;
}

=head2 _set_menus_enable

Disable some menus at start.

=cut

sub _set_menus_enable {
    my ( $self, $enable ) = @_;

    my $mn = $self->_view->get_menubar();

    foreach my $mnu (qw(mn_fm mn_fe mn_fc)) {
        my $mn_id = $self->_view->get_menu_popup_item($mnu)->GetId;
        $mn->Enable( $mn_id, $enable );
    }
}

=head2 _check_app_menus

Check if screen modules from the menu exists and are loadable.
Disable those which fail the test.

=cut

sub _check_app_menus {
    my $self = shift;

    my $menu = $self->_view->get_menubar();

    my $appmenus = $self->_view->get_app_menus_list();
    foreach my $menu_item ( @{$appmenus} ) {
        my $menu_id = $self->_view->get_menu_popup_item($menu_item)->GetId;
        my ( $class, $module_file ) = $self->screen_module_class($menu_item);
        eval { require $module_file };
        if ($@) {
            $menu->Enable( $menu_id, 0 );
            $self->_log->trace("WW: Can't load '$module_file'");
            print "WW: Can't load '$module_file'\n";
        }
    }

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
    my ( $self, $page ) = @_;

    my $dict     = Tpda3::Lookup->new;
    my $ctrl_ref = $self->scrobj($page)->get_controls();
    my $bindings = $self->scrcfg('rec')->bindings;

    $self->_log->trace('Setup binding for configured widgets');

    foreach my $bind_name ( keys %{$bindings} ) {

        # Skip if just an empty tag
        next unless $bind_name;

        # If 'search' is a hashref, get the first key, else the value
        my $search
            = ref $bindings->{$bind_name}{search}
            ? ( keys %{ $bindings->{$bind_name}{search} } )[0]
            : $bindings->{$bind_name}{search};

        # If 'search' is a hashref, get the first keys name attribute
        my $column
            = ref $bindings->{$bind_name}{search}
            ? $bindings->{$bind_name}{search}{$search}{name}
            : $search;

        $self->_log->trace("Setup binding for '$bind_name'");

        # Compose the parameter for the 'Search' dialog
        my $para = {
            table  => $bindings->{$bind_name}{table},
            search => $search,
        };

        # Add the search field to the columns list
        my $field_cfg = $self->scrcfg('rec')->main_table_column($column);
        my @cols;
        my $rec = {};
        $rec->{$search} = {
            width => $field_cfg->{width},
            label => $field_cfg->{label},
            order => $field_cfg->{order},
        };
        $rec->{$search}{name} = $column if $column;    # add name attribute

        push @cols, $rec;

        # Detect the configuration style and add the 'fields' to the
        # columns list
        my $flds;
    SWITCH: for ( ref $bindings->{$bind_name}{field} ) {
            /array/i && do {
                $flds = $self->fields_cfg_array( $bindings->{$bind_name} );
                last SWITCH;
            };
            /hash/i && do {
                $flds = $self->fields_cfg_hash( $bindings->{$bind_name} );
                last SWITCH;
            };
            print "WW: Wrong bindings configuration!\n";
            return;
        }
        push @cols, @{$flds};

        $para->{columns} = [@cols];    # add columns info to parameters

        EVT_TEXT_ENTER $self->_view, $ctrl_ref->{$column}[1], sub {
            my $record = $dict->lookup( $self->_view, $para );
            $self->screen_write($record);
        };
    }

    return;
}

=head2 set_app_mode

Set application mode

=cut

sub set_app_mode {
    my ( $self, $mode ) = @_;

    $self->_model->set_mode($mode);

    $self->toggle_interface_controls;

    return unless ref $self->scrobj('rec');

    $self->toggle_screen_interface_controls;

    if ( my $method_name = $self->{method_for}{$mode} ) {
        $self->$method_name();
    }
    else {
        print "WW: '$mode' not implemented!\n";
    }

    return 1;    # to make ok from Test::More happy
                 # probably missing something :) TODO!
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

    $self->screen_write( undef, 'clear' );   # empty the main controls

    #    $self->control_tmatrix_write();
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
    my ( $self, ) = @_;

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

    $self->screen_write( undef, 'clear' );

    # $self->control_tmatrix_write();
    $self->controls_state_set('edit');

    return;
}

=head2 on_screen_mode_find

When in I<find> mode set status to I<normal> and clear all controls
content in the I<Screen> and change the background to light green.

=cut

sub on_screen_mode_find {
    my $self = shift;

    $self->screen_write( undef, 'clear' );   # Empty the controls
                                             # $self->control_tmatrix_write();
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
        off => {
            state      => 'disabled',
            background => 'disabled_bgcolor',
        },
        on => {
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

    $self->{method_for} = {
        add  => 'on_screen_mode_add',
        find => 'on_screen_mode_find',
        idle => 'on_screen_mode_idle',
        edit => 'on_screen_mode_edit',
        sele => 'on_screen_mode_sele',
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

=head2 screen_module_class

Return screen module class and file name.

=cut

sub screen_module_class {
    my ( $self, $screen_module ) = @_;

    my $app_module = $self->_cfg->application->{module};

    my $module_class = "Tpda3::Wx::App::${app_module}::${screen_module}";

    ( my $module_file = "$module_class.pm" ) =~ s{::}{/}g;

    return ( $module_class, $module_file );
}

=head2 screen_module_load

Load screen chosen from the menu.

=cut

sub screen_module_load {
    my ( $self, $module, $from_tools ) = @_;

    my $rscrstr = lc $module;

    # Destroy existing NoteBook widget
    $self->_view->destroy_notebook();

    # Unload current screen
    if ( $self->{_rscrcls} ) {
        Class::Unload->unload( $self->{_rscrcls} );
        if ( Class::Inspector->loaded( $self->{_rscrcls} ) ) {
            $self->_log->trace("Error unloading '$self->{_rscrcls}' screen");
        }

        # Unload current details screen
        if ( $self->{_dscrcls} ) {
            Class::Unload->unload( $self->{_dscrcls} );
            if ( Class::Inspector->loaded( $self->{_dscrcls} ) ) {
                $self->_log->error("Failed unloading '$self->{_dscrcls}' dscreen");
            }
            $self->{_dscrcls} = undef;
        }
    }

    # Make new NoteBook widget and setup callback
    $self->_view->create_notebook();
    # $self->_set_event_handler_nb();

    my ( $class, $module_file )
        = $self->screen_module_class( $module, $from_tools );
    eval { require $module_file };
    if ($@) {

        # TODO: Decide what is optimal to do here?
        print "EE: Can't load '$module_file'\n";
        return;
    }

    unless ( $class->can('run_screen') ) {
        my $msg = "EE: Screen '$class' can not 'run_screen'";
        print "$msg\n";
        $self->_log->error($msg);

        return;
    }

    # New screen instance
    $self->{_rscrobj} = $class->new($rscrstr);
    $self->_log->trace("New screen instance: $module");

    # # Details page
    # my $has_det = $self->scrcfg('rec')->has_screen_detail;
    # if ($has_det) {
    #     $self->_view->create_notebook_panel( 'det', 'Details' );
    #     $self->_set_event_handler_nb('det');
    # }

    # Show screen
    my $nb = $self->_view->get_notebook();
    $self->{_rscrobj}->run_screen($nb);

    # Store currently loaded screen class
    $self->{_rscrcls} = $class;

    # Load instance config
    # $self->_cfg->config_load_instance();

    # #-- Lookup bindings for Tk::Entry widgets
    # $self->setup_lookup_bindings_entry('rec');

    # #-- Lookup bindings for tables (TableMatrix)
    # $self->setup_bindings_table();

    # Set PK column name
    # $self->screen_set_pk_col();

    $self->set_app_mode('idle');

    # List header
    my $header_look = $self->scrcfg('rec')->list_header->{lookup};
    my $header_cols = $self->scrcfg('rec')->list_header->{column};
    my $fields      = $self->scrcfg('rec')->main_table_columns;
    if ($header_look and $header_cols) {
        $self->_view->make_list_header( $header_look, $header_cols, $fields );
    }
    else {
        $self->_view->nb_set_page_state( 'lst', 'disabled' );
    }

    #- Event handlers

    # foreach my $tm_ds ( keys %{ $self->scrobj('rec')->get_tm_controls() } ) {
    #     $self->set_event_handler_screen($tm_ds);
    # }

    $self->_set_menus_enable(1);

    $self->_view->set_status( '', 'ms' );

    $self->_model->unset_scrdata_rec();

    # Change application title
    # my $descr = $self->scrcfg('rec')->screen_description;
    # $self->_view->title(' Tpda3 - ' . $descr) if $descr;

    # Update window geometry
    $self->set_geometry();

    # Export message dictionary to Model
    # my $dict = $self->scrobj()->get_msg_strings();
    # $self->_model->message_dictionary($dict);

    # Load lists into JComboBox widgets (JBrowseEntry not supported)
    # $self->screen_init();

    return 1;    # to make ok from Test::More happy
                 # probably missing something :) TODO!
}

=head2 set_geometry

Set window geometry from instance config if exists or from defaults.

=cut

sub set_geometry {
    my $self = shift;


    my $scr_name
        = $self->scrcfg()
        ? $self->scrcfg()->screen_name
        : return;

    my $geom;
    if ( $self->_cfg->can('geometry') ) {
        my $go = $self->_cfg->geometry();
        if (exists $go->{$scr_name}) {
            $geom = $go->{$scr_name};
        }
    }
    unless ($geom) {
        $geom = $self->scrcfg('rec')->screen->{geometry};
    }

    $self->_view->set_geometry($geom);

    return;
}

=head2 screen_init

Load options in Listbox like widgets - JCombobox support only.

All JComboBox widgets must have a <lists_ds> record in config to
define where the data for the list come from:

Data source for list widgets (JCombobox)

 <lists_ds>
     <statuscode>
         table   = status
         code    = code
         name    = description
         default = none
     </statuscode>
 </lists_ds>

=cut

sub screen_init {
    my $self = shift;

    # Entry objects hash
    my $ctrl_ref = $self->scrobj()->get_controls();
    return unless scalar keys %{$ctrl_ref};

    foreach my $field ( keys %{ $self->scrcfg()->main_table_columns } ) {

        # Control config attributes
        my $fld_cfg  = $self->scrcfg()->main_table_column($field);
        my $ctrltype = $fld_cfg->{ctrltype};
        my $ctrlrw   = $fld_cfg->{rw};

        next unless $ctrl_ref->{$field}[0];    # Undefined widget variable

        my $para = $self->scrcfg()->{lists_ds}{$field};

        next unless ref $para eq 'HASH';       # undefined, skip

        # Query table and return data to fill the lists
        my $cod_a_ref = $self->{_model}->get_codes( $field, $para, $ctrltype );

        if ( $ctrltype eq 'm' ) {

            # JComboBox
            if ( $ctrl_ref->{$field}[1] ) {
                $ctrl_ref->{$field}[1]->removeAllItems();
                $ctrl_ref->{$field}[1]->configure( -choices => $cod_a_ref );
            }
        }
        elsif ( $ctrltype eq 'l' ) {

            # MatchingBE
            if ( $ctrl_ref->{$field}[1] ) {
                $ctrl_ref->{$field}[1]->configure(
                    -labels_and_values => $cod_a_ref,
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

    my ( $toolbars, $attribs ) = $self->{_view}->toolbar_names();

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

    # # Get ToolBar button atributes
    # my $attribs  = $self->_cfg->toolbar2;
    # my $toolbars = Tpda3::Utils->sort_hash_by_id($attribs);

    # my $mode = $self->_model->get_appmode;

    # foreach my $name ( @{$toolbars} ) {
    #     my $state = $attribs->{$name}{state}{$mode};
    #     $self->_screen->enable_tool( $name, $state );
    # }

    my $page = $self->_view->get_nb_current_page();
    my $mode = $self->_model->get_appmode;

    return if $page eq 'lst';

    #- Toolbar

    my ( $toolbars, $attribs ) = $self->scrobj()->toolbar_names();

    foreach my $name ( @{$toolbars} ) {
        my $status = $attribs->{$name}{state}{$page}{$mode};

        #- Set status for toolbar buttons

        $self->_view->enable_tool( $name, $status );
    }

    return;
}

=head2 record_load_new

Load a new record.

The (primary) key field value is col0 from the selected item in the
list control on the I<List> page.

=cut

sub record_load_new {
    my $self = shift;

    my $pk_id = $self->_view->list_read_selected();
    if ( !defined $pk_id ) {
        $self->_view->set_status( 'Nothing selected', 'ms' );
        return;
    }

    my $ret = $self->record_load($pk_id);

    return $ret;
}

=head2 record_reload

Reload the curent record.

Reads the contents of the (primary) key field, retrieves the record from
the database table and loads the record data in the controls.

The control that holds the key record has to be readonly, so the user
can't delete it's content.

=cut

sub record_reload {
    my $self = shift;

    my $page = $self->_view->get_nb_current_page();

    # Save PK-value
    my $pk_val = $self->screen_get_pk_val;    # get old pk-val

    $self->record_clear;

    # Restore PK-value
    $self->screen_set_pk_val($pk_val);

    # Set parameters for record load (pk, fk)
    $self->get_selected_and_set_fk_val if $page eq 'det';

    $self->record_load();

    $self->toggle_detail_tab;

    $self->_view->set_status( "Reloaded", 'ms', 'blue' );

    $self->_model->set_scrdata_rec(0);    # false = loaded,  true = modified,
                                          # undef = unloaded

    return;
}

=head2 record_load

Load the selected record in screen

=cut

sub record_load {
    my ( $self, $pk_id ) = @_;

    # Table metadata
    my $table_hr  = $self->scrcfg('rec')->maintable;
    my $fields_hr = $table_hr->{columns};
    my $pk_col    = $table_hr->{pkcol}{name};

    # Construct where, add findtype info
    my $params = {};
    $params->{table} = $table_hr->{view};    # use view instead of table
    $params->{where}{$pk_col} = [ $pk_id, $fields_hr->{$pk_col}{findtype} ];
    $params->{pkcol} = $pk_col;

    my $record = $self->_model->query_record($params);

    $self->screen_write($record);

    # my $screen_type = $self->scrcfg('rec')->{screen}{type};
    # if ($screen_type eq 'tablematrix') {

    #     # Table metadata
    #     my $table_hr  = $self->scrcfg('rec')->table;
    #     my $fields_hr = $table_hr->{columns};

    #     # Construct where, add findtype info
    #     $params->{table} = $table_hr->{view};
    #     $params->{fkcol} = $table_hr->{fkcol}{name};

    #     my $records = $self->_model->query_record_batch($params);

    #     $self->control_tmatrix_write($records);
    # }

    return 1;    # to make ok from Test::More happy
                 # probably missing something :) TODO!
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
    my $main_table = $self->scrcfg('rec')->main_table;
    my $columns    = $self->scrcfg('rec')->main_table_columns;

    my $params = {};

    # Columns data (from list header)
    $params->{columns} = $self->list_column_names();

    # Add findtype info to screen data
    while ( my ( $field, $value ) = each( %{ $self->{_scrdata} } ) ) {
        chomp $value;
        my $findtype = $columns->{$field}{findtype};

        # Create a where clause like this:
        #  field1 IS NOT NULL and field2 IS NULL
        # for entry values equal to '%' or '!'
        $findtype = q{notnull} if $value eq q{%};
        $findtype = q{isnull}  if $value eq q{!};

        $params->{where}{$field} = [ $value, $findtype ];
    }

    # Table data
    $params->{table} = $main_table->{view};        # use view instead of table
    $params->{pkcol} = $main_table->{pkcol}{name};

    my $ary_ref = $self->_model->query_records_find($params);

    $self->_view->list_init();
    my $record_count = $self->_view->list_populate($ary_ref);
    if ( $record_count > 0 ) {
        $self->_view->list_raise();
    }

    # Set mode to sele if found
    if ( $record_count > 0 ) {
        $self->set_app_mode('sele');
    }

    return;
}

=head2 record_find_count

Execute count.

Same as for I<record_find_execute>.

=cut

sub record_find_count {
    my $self = shift;

    $self->screen_read();

    # Table configs
    my $columns = $self->scrcfg('rec')->main_table_columns;

    my $params = {};

    # Add findtype info to screen data
    while ( my ( $field, $value ) = each( %{ $self->{_scrdata} } ) ) {
        chomp $value;
        my $findtype = $columns->{$field}{findtype};

        # Create a where clause like this:
        #  field1 IS NOT NULL and field2 IS NULL
        # for entry values equal to '%' or '!'
        $findtype = q{notnull} if $value eq q{%};
        $findtype = q{isnull}  if $value eq q{!};

        $params->{where}{$field} = [ $value, $findtype ];
    }

    # Table data
    $params->{table} = $self->scrcfg('rec')->main_table_view;
    $params->{pkcol} = $self->scrcfg('rec')->main_table_pkcol;

    $self->_model->query_records_count($params);

    return;
}

# sub record_find_execute {
#     my $self = shift;

#     $self->screen_read();

#     # Table configs
#     my $table_hr  = $self->scrcfg('rec')->maintable;
#     my $fields_hr = $self->scrcfg('rec')->maintable->{columns};

#     my $params = {};

#     # Columns data (for found list)
#     $params->{columns} = $self->scrcfg('rec')->found_cols->{col};

#     # Add findtype info to screen data
#     while ( my ( $field, $value ) = each( %{ $self->{scrdata} } ) ) {
#         $params->{where}{$field} = [ $value, $fields_hr->{$field}{findtype} ];
#     }

#     # Table data
#     $params->{table} = $table_hr->{view};          # use view instead of table
#     $params->{pkcol} = $table_hr->{pkcol}{name};

#     $self->_view->list_init();
#     my $record_count = $self->_view->list_populate($params);

#     if ( $record_count > 0 ) {
#         $self->set_app_mode('sele');
#         $self->_view->list_item_select_last();
#         $self->_view->get_notebook->SetSelection(1);    # 'lst'
#     }

#     return;
# }

# =head2 record_find_count

# Execute find: count

# =cut

# sub record_find_count {
#     my $self = shift;

#     $self->screen_read();

#     # Table configs
#     my $table_hr  = $self->scrcfg('rec')->maintable;
#     my $fields_hr = $self->scrcfg('rec')->maintable->{columns};

#     my $params = {};

#     # Add findtype info to screen data
#     while ( my ( $field, $value ) = each( %{ $self->{scrdata} } ) ) {
#         $params->{where}{$field} = [ $value, $fields_hr->{$field}{findtype} ];
#     }

#     # Table data
#     $params->{table} = $table_hr->{view};          # use view instead of table
#     $params->{pkcol} = $table_hr->{pkcol}{name};

#     $self->_model->query_records_count($params);

#     return;
# }

=head2 screen_read

Read screen controls (widgets) and save in a Perl data stucture.

=cut

sub screen_read {
    my ($self, $all) = @_;

    # Initialize
    $self->{_scrdata} = {};

    my $scrobj = $self->scrobj;    # current screen object
    my $scrcfg = $self->scrcfg;    # current screen config

    my $ctrl_ref = $scrobj->get_controls();

    return unless scalar keys %{$ctrl_ref};

    # Scan read from controls
    foreach my $field ( keys %{ $scrcfg->main_table_columns() } ) {
        my $fld_cfg = $scrcfg->main_table_column($field);

        # Control config attributes
        my $ctrltype = $fld_cfg->{ctrltype};
        my $ctrlrw   = $fld_cfg->{rw};

        if ( !$all ) {
            unless ( $self->_model->is_mode('find') ) {
                next if ( $ctrlrw eq 'r' ) or ( $ctrlrw eq 'ro' );
            }
        }

        # Call the appropriate method according to control (widget) type
        my $sub_name = "control_read_$ctrltype";
        if ( $self->can($sub_name) ) {
            unless ( $ctrl_ref->{$field}[1] ) {
                print "EE: Undefined field '$field', check configuration!\n";
                next;
            }
            $self->$sub_name($field);
        }
        else {
            print "EE: No '$ctrltype' ctrl type for reading '$field'!\n";
        }
    }

    return;
}

=head2 control_read_e

Read contents of a Wx::TextCtrl control.

=cut

sub control_read_e {
    my ( $self, $field ) = @_;

    my $control = $self->scrobj()->get_controls($field)->[1];

    my $value = $control->GetValue();

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
        $value =~ s/\n$//mg;    # m=multiline

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

Read contents of a Wx::ComboBox control.

=cut

sub control_read_m {
    my ( $self, $ctrl_ref, $field ) = @_;

    unless ( $ctrl_ref->{$field}[1] ) {
        warn "Undefined: [m] $field\n";
        return;
    }

    my $value = ${ $ctrl_ref->{$field}[0] };    # Value from variable

    # Add value if not empty
    if ( $value =~ /\S+/ ) {

        # Delete '\n' from end
        $value =~ s/\n$//mg;                    # m=multiline

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
        $value =~ s/\n$//mg;    # m=multiline

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
    my ( $self, $record ) = @_;

    #- Use current page
    my $page = $self->_view->get_nb_current_page();

    return if $page eq 'lst';

    my $ctrl_ref = $self->scrobj($page)->get_controls();
    return unless scalar keys %{$ctrl_ref};    # no controls?

    my $cfg_ref = $self->scrcfg($page);

    # my $cfgdeps = $self->scrcfg($page)->dependencies;

    foreach my $field ( keys %{ $cfg_ref->main_table_columns } ) {

        # Skip field if not in record or not dependent
        next
            unless ( exists $record->{$field}
                         # or $self->is_dependent( $field, $cfgdeps )
                 );

        my $fldcfg = $cfg_ref->main_table_column($field);

        my $value = $record->{$field}
            || ( $self->_model->is_mode('add') ? $fldcfg->{default} : undef );

        # # Process dependencies
        my $state;
        # if (exists $cfgdeps->{$field} ) {
        #     $state = $self->dependencies($field, $cfgdeps, $record);
        # }

        if ($value) {

            # Trim spaces and '\n' from the end
            $value = Tpda3::Utils->trim($value);

            # Number
            if ( $fldcfg->{validation} eq 'numeric' ) {
                $self->format_as_number( $value, $fldcfg->{places} );
            }
        }

        $self->ctrl_write_to($field, $value, $state);
    }

#     my ( $self, $record_ref, $option ) = @_;

#     $option ||= 'record';    # default option record

#     # $self->_log->trace("Write '$option' screen controls");

#     my $ctrl_ref = $self->scrobj($page)->get_controls();

#     return unless scalar keys %{$ctrl_ref};    # no controls?

# FIELD:
#     foreach my $field ( keys %{ $self->scrcfg('rec')->maintable->{columns} } ) {

#         my $fld_cfg = $self->scrcfg('rec')->maintable->{columns}{$field};

#         # Save control state
#         my $ctrl_state = $ctrl_ref->{$field}[1]->IsEditable();
#         $ctrl_ref->{$field}[1]->SetEditable(1);

#         # Control config attributes
#         my $ctrltype = $fld_cfg->{ctrltype};

#         my $value;
#         if ( $option eq 'record' ) {
#             $value = $record_ref->{ lc $field };
#         }
#         elsif ( $option eq 'fields' ) {
#             $value = $record_ref->{ lc $field };
#             next FIELD if !$value;
#         }
#         elsif ( $option eq 'clear' ) {

#             # nothing here
#         }
#         else {
#             warn "Should never get here!\n";
#         }

#         if ($value) {

#             # Trim spaces and '\n' from the end
#             $value = Tpda3::Utils->trim($value);

#             # Should make $value = 0, than format as number ?
#             my $decimals = $fld_cfg->{decimals};
#             if ($decimals) {
#                 if ( $decimals > 0 ) {

#                     # if decimals > 0, format as number
#                     $value = sprintf( "%.${decimals}f", $value );
#                 }
#             }
#         }

#         # Run appropriate sub according to control (entry widget) type
#         my $sub_name = qq{control_write_$ctrltype};
#         if ( $self->can($sub_name) ) {
#             $self->$sub_name( $ctrl_ref, $field, $value );
#         }
#         else {
#             print "WARN: No '$ctrltype' ctrl type for writing '$field'!\n";
#         }

#         # Restore state
#         $ctrl_ref->{$field}[1]->SetEditable($ctrl_state);
#     }

#     # $self->_log->trace("Write finished (restored controls states)");

    return;
}

=head2 ctrl_write_to

Run the appropriate sub according to control (entry widget) type.

=cut

sub ctrl_write_to {
    my ($self, $field, $value, $state) = @_;

    my $ctrltype = $self->scrcfg()->main_table_column($field)->{ctrltype};

    my $sub_name = qq{control_write_$ctrltype};
    if ( $self->can($sub_name) ) {
        $self->$sub_name($field, $value, $state);
    }
    else {
        print "WW: No '$ctrltype' ctrl type for writing '$field'!\n";
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

    if ( $self->_model->is_mode('edit') ) {
        my $answer = $self->ask_to_save;    # if $self->_model->is_modified;
        if ( !defined $answer ) {
            $self->_view->get_toolbar_btn('tb_ad')->deselect;
            return;
        }
    }

    $self->_model->is_mode('add')
        ? $self->set_app_mode('idle')
        : $self->set_app_mode('add');

    $self->_view->set_status( '', 'ms' );    # clear messages

    return;
}

=head2 controls_state_set

Toggle all controls state from I<Screen>.

=cut

sub controls_state_set {
    my ( $self, $state ) = @_;

    $self->_log->trace("Screen 'rec' controls state is '$state'");

    my $page = $self->_view->get_nb_current_page();
    my $bg   = $self->scrobj($page)->get_bgcolor();

    my $ctrl_ref = $self->scrobj($page)->get_controls();
    return unless scalar keys %{$ctrl_ref};

    my $control_states = $self->control_states($state);

    return unless defined $self->scrcfg($page);

    foreach my $field ( keys %{ $self->scrcfg($page)->main_table_columns } ) {
        my $fld_cfg = $self->scrcfg($page)->main_table_column($field);

        my $ctrl_state = $control_states->{state};
        $ctrl_state = $fld_cfg->{state}
            if $ctrl_state eq 'from_config';

        my $bkground = $control_states->{background};
        my $bg_color = $bkground;
        $bg_color = $fld_cfg->{bgcolor}
            if $bkground eq 'from_config';
        $bg_color = $bg
            if $bkground eq 'disabled_bgcolor';

        # Special case for find mode and fields with 'findtype' set to none
        if ( $state eq 'find' ) {
            if ( $fld_cfg->{findtype} eq 'none' ) {
                $ctrl_state = 'disabled';
                $bg_color   = $self->scrobj($page)->get_bgcolor();
            }
        }

        # Allow 'bg' as bgcolor config attribute value for controls
        $bg_color = $bg if $bg_color =~ m{bg|bground|background};

        # Configure controls
        eval {
            my $state = $ctrl_state eq 'normal' ? 1 : 0;
            $ctrl_ref->{$field}[1]->SetEditable($state);
            $ctrl_ref->{$field}[1]
                ->SetBackgroundColour( Wx::Colour->new($bg_color) )
                    if $bg_color;
        };
        print "WW: '$field': $@\n" if $@;
    }

    return;
}

# =head2 controls_state_set

# Toggle all controls state from I<Screen>.

# =cut

# sub controls_state_set {
#     my ( $self, $state ) = @_;

#     $self->_log->trace("Screen controls state is '$state'");

#     my $ctrl_ref = $self->scrobj($page)->get_controls();
#     return unless scalar keys %{$ctrl_ref};

#     my $control_states = $self->control_states($state);

#     return unless defined $self->scrcfg('rec');

#     foreach my $field ( keys %{ $self->scrcfg('rec')->maintable->{columns} } ) {

#         my $fld_cfg = $self->scrcfg('rec')->maintable->{columns}{$field};

#         my $ctrl_state = $control_states->{state};
#         $ctrl_state = $fld_cfg->{state}
#             if $ctrl_state eq 'from_config';

#         my $bkground = $control_states->{background};
#         my $bg_color = $bkground;
#         $bg_color = $fld_cfg->{bgcolor}
#             if $bkground eq 'from_config';
#         $bg_color = $self->scrobj($page)->get_bgcolor()
#             if $bkground eq 'disabled_bgcolor';

#         # Special case for find mode and fields with 'findtype' set to none
#         if ( $state eq 'find' ) {
#             if ( $fld_cfg->{findtype} eq 'none' ) {
#                 $ctrl_state = 0;                               # 'disabled'
#                 $bg_color   = $self->scrobj($page)->get_bgcolor();
#             }
#         }

#         # Configure controls
#         $ctrl_state = $ctrl_state eq 'normal' ? 1 : 0;
#         $ctrl_ref->{$field}[1]->SetEditable($ctrl_state);
#         $ctrl_ref->{$field}[1]
#             ->SetBackgroundColour( Wx::Colour->new($bg_color) )
#             if $bg_color;
#     }

#     return;
# }

=head2 control_write_e

Write to a Tk::Entry widget.  If I<$value> not true, than only delete.

=cut

sub control_write_e {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    $value = q{} unless defined $value;    # Empty

    # Tip Entry 'e'
    $ctrl_ref->{$field}[1]->Clear;
    $ctrl_ref->{$field}[1]->SetValue($value) if $value;

    return;
}

=head2 control_write_t

Write to a Wx::StyledTextCtrl.  If I<$value> not true, than only delete.

=cut

sub control_write_t {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    $value = q{} unless defined $value;    # Empty

    # Tip TextEntry 't'
    $ctrl_ref->{$field}[1]->ClearAll;
    $ctrl_ref->{$field}[1]->AppendText($value);
    $ctrl_ref->{$field}[1]->AppendText("\n");

    return;
}

=head2 control_write_d

Write to a Tk::DateEntry widget.  If I<$value> not true, than only delete.

=cut

sub control_write_d {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    $value = q{} unless defined $value;    # Empty

    # Date should come from database in ISO format
    my ( $y, $m, $d ) = Tpda3::Utils->dateentry_parse_date( 'iso', $value );

    # Get configured date style and format accordingly
    my $dstyle = 'iso';    #$self->{conf}->get_misc_config('datestyle');
    if ( $dstyle and $value ) {
        $value = Tpda3::Utils->dateentry_format_date( $dstyle, $y, $m, $d );
    }
    else {

        # default to ISO
    }

    ${ $ctrl_ref->{$field}[0] } = $value;

    return;
}

=head2 control_write_m

Write to a Wx::ComboBox widget.  If I<$value> not true, than only delete.

=cut

sub control_write_m {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    if ($value) {
        $ctrl_ref->{$field}[1]->setSelected( $value, -type => 'value' );
    }
    else {
        ${ $ctrl_ref->{$field}[0] } = q{};    # Empty
    }

    return;
}

=head2 control_write_l

Write to a Tk::MatchingBE widget.  Warning: cant write an empty value,
must test with a key -> value pair like 'not set' => '?empty?'.

=cut

sub control_write_l {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    return unless defined $value;    # Empty

    $ctrl_ref->{$field}[1]->set_selected_value($value);

    return;
}

=head2 control_states

Return settings for controls, according to the state of the application.

=cut

sub control_states {
    my ( $self, $state ) = @_;

    return $self->{control_states}{$state};
}

=head2 add_tmatrix_row

Table matrix methods.  Add TableMatrix row.

=cut

# sub add_tmatrix_row {
#     my ($self, $valori_ref) = @_;

#     my $xt = $self->scrobj($page)->get_tm_controls('tm1');

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

#     my $xt = $self->scrobj($page)->get_tm_controls('tm1');

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


=head2 screen_get_pk_col

Return primary key column name for the current screen.

=cut

sub screen_get_pk_col {
    my $self = shift;

    return $self->scrcfg('rec')->main_table_pkcol();
}

=head2 screen_set_pk_col

Store primary key column name for the current screen.

=cut

sub screen_set_pk_col {
    my $self = shift;

    my $pk_col = $self->screen_get_pk_col;

    if ($pk_col) {
        $self->{_tblkeys}{$pk_col} = undef;
    }
    else {
        croak "ERR: Unknown PK column name!\n";
    }

    return;
}

=head2 screen_set_pk_val

Store primary key column value for the current screen.

=cut

sub screen_set_pk_val {
    my ( $self, $pk_val ) = @_;

    my $pk_col = $self->screen_get_pk_col;

    if ($pk_col) {
        $self->{_tblkeys}{$pk_col} = $pk_val;
    }
    else {
        croak "ERR: Unknown PK column name!\n";
    }

    return;
}

=head2 screen_get_pk_val

Return primary key column value for the current screen.

=cut

sub screen_get_pk_val {
    my $self = shift;

    my $pk_col = $self->screen_get_pk_col;

    return $self->{_tblkeys}{$pk_col};
}

=head2 screen_get_fk_col

Return foreign key column name for the current screen.

=cut

sub screen_get_fk_col {
    my ( $self, $page ) = @_;

    $page ||= $self->_view->get_nb_current_page();

    return $self->scrcfg($page)->main_table_fkcol();
}

=head2 screen_set_fk_col

Store foreign key column name for the current screen.

=cut

sub screen_set_fk_col {
    my $self = shift;

    my $fk_col = $self->screen_get_fk_col;

    if ($fk_col) {
        $self->{_tblkeys}{$fk_col} = undef;
    }

    return;
}

=head2 screen_set_fk_val

Store foreign key column value for the current screen.

=cut

sub screen_set_fk_val {
    my ( $self, $fk_val ) = @_;

    my $fk_col = $self->screen_get_fk_col;

    if ($fk_col) {
        $self->{_tblkeys}{$fk_col} = $fk_val;
    }

    return;
}

=head2 screen_get_fk_val

Return foreign key column value for the current screen.

=cut

sub screen_get_fk_val {
    my $self = shift;

    my $fk_col = $self->screen_get_fk_col;

    return unless $fk_col;

    return $self->{_tblkeys}{$fk_col};
}


=head2 list_column_names

Return the list column names.

=cut

sub list_column_names {
    my $self = shift;

    my $header_look = $self->scrcfg('rec')->list_header->{lookup};
    my $header_cols = $self->scrcfg('rec')->list_header->{column};

    my $columns = [];
    push @{$columns}, @{$header_look};
    push @{$columns}, @{$header_cols};

    return $columns;
}

=head2 scrcfg

Return screen configuration object for I<page>, or for the current
page.

=cut

sub scrcfg {
    my ( $self, $page ) = @_;

    $page ||= $self->_view->get_nb_current_page();

    return unless $page;

    if ( $page eq 'lst' ) {
        warn "Wrong page (scrcfg): $page!\n";

        return;
    }

    return $self->scrobj($page)->{scrcfg};
}

=head2 scrobj

Return current screen object reference, or the object reference from
the required page.

=cut

sub scrobj {
    my ( $self, $page ) = @_;

    $page ||= $self->_view->get_nb_current_page();

    return $self->{_rscrobj} if $page eq 'rec';

    return $self->{_dscrobj} if $page eq 'det';

    warn "Wrong page (scrobj): $page!\n";

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::Controller
