package Tpda3::Tk::Controller;

use strict;
use warnings;
use Carp;

use Tk;
use Class::Unload;
use Log::Log4perl qw(get_logger :levels);
use Storable qw (store retrieve);

use Tpda3::Utils;
use Tpda3::Config;
use Tpda3::Config::Screen;
use Tpda3::Model;
use Tpda3::Tk::View;
use Tpda3::Tk::Dialog::Login;
use Tpda3::Lookup;

use File::Spec::Functions qw(catfile);

=head1 NAME

Tpda3::Tk::Controller - The Controller

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

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
    my $class = shift;

    my $model = Tpda3::Model->new();

    my $view = Tpda3::Tk::View->new(
        $model,
    );

    my $self = {
        _model   => $model,
        _app     => $view,                   # an alias ...
        _view    => $view,
        _scrcls  => undef,
        _scrobj  => undef,
        _scrcfg  => undef,
        _scrstr  => undef,
        _cfg     => Tpda3::Config->instance(),
        _log     => get_logger(),
    };

    bless $self, $class;

    my $loglevel_old = $self->_log->level();

    $self->_log->trace('Controller new');

    $self->_control_states_init();

    $self->_set_event_handlers();

    $self->_set_menus_enable('disabled');    # disable find mode menus

    $self->_check_app_menus();               # disable if no screen

    # Restore default log level
    $self->_log->level($loglevel_old);

    return $self;
}

=head2 start

Check if we have user and pass, if not, show dialog.  Connect do
database.

=cut

sub start {
    my $self = shift;

    $self->_log->trace('starting ...');

    if ( !$self->_cfg->user or !$self->_cfg->pass ) {
        my $pd = Tpda3::Tk::Dialog::Login->new;
        $pd->login( $self->_view );
    }

    # Check again ...
    if ( $self->_cfg->user and $self->_cfg->pass ) {

        # Connect to database
        $self->_model->toggle_db_connect();
    }
    else {
        $self->_view->on_quit;
    }

    $self->_log->trace('... started');

    return;
}

sub about {
    my $self = shift;

    my $gui = $self->_view;

    # Create a dialog.
    my $dbox = $gui->DialogBox(
        -title   => 'Despre ... ',
        -buttons => ['Inchide'],
    );

    # Windows has the annoying habit of setting the background color
    # for the Text widget differently from the rest of the window.  So
    # get the dialog box background color for later use.
    my $bg = $dbox->cget('-background');

    # Insert a text widget to display the information.
    my $text = $dbox->add(
        'Text',
        -height     => 8,
        -width      => 35,
        -background => $bg
    );

    # Define some fonts.
    my $textfont = $text->cget('-font')->Clone( -family => 'Helvetica' );
    my $italicfont = $textfont->Clone( -slant => 'italic' );
    $text->tag(
        'configure', 'italic',
        -font    => $italicfont,
        -justify => 'center'
    );
    $text->tag(
        'configure', 'normal',
        -font    => $textfont,
        -justify => 'center'
    );

    my $PROGRAM_NAME = 'Tiny Perl Database Application 3';
    my $PROGRAM_VER  = $Tpda3::VERSION;

    # Add the about text.
    $text->insert( 'end', "\n" );
    $text->insert( 'end', $PROGRAM_NAME . "\n", 'normal' );
    $text->insert( 'end', "Version " . $PROGRAM_VER . "\n", 'normal' );
    $text->insert( 'end', "Author: Stefan Suciu\n", 'normal' );
    $text->insert( 'end', "Copyright 2010-2011\n", 'normal' );
    $text->insert( 'end', "GNU General Public License (GPL)\n", 'normal' );
    $text->insert( 'end', "stefansbv at users . sourceforge . net",
        'italic' );
    $text->configure( -state => 'disabled' );
    $text->pack(
        -expand => 1,
        -fill   => 'both'
    );
    $dbox->Show();
}

=head2 _set_event_handlers

Setup event handlers for the interface.

=cut

sub _set_event_handlers {
    my $self = shift;

    $self->_log->trace('Setup event handlers');

    #- Base menu

    #-- Exit
    $self->_view->get_menu_popup_item('mn_qt')->configure(
        -command => sub {
            $self->_view->on_quit;
        }
    );

    #-- About
    $self->_view->get_menu_popup_item('mn_ab')->configure(
        -command => sub {
            $self->about;
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

    #- Custom application menu from menu.yml

    my $appmenus = $self->_view->get_app_menus_list();
    foreach my $item ( @{$appmenus} ) {
        $self->_view->get_menu_popup_item($item)->configure(
            -command => sub {
                $self->screen_module_load($item);
            }
        );
    }

    #- Toolbar

    #-- Attach to desktop - pin (save geometry to config file)
    $self->_view->get_toolbar_btn('tb_at')->bind(
        '<ButtonRelease-1>' => sub {
            my $scr_name = $self->{_scrstr} || 'main';
            $self->_cfg
                ->config_save_instance( $scr_name, $self->_view->w_geometry() );
        }
    );

    #-- Find mode
    $self->_view->get_toolbar_btn('tb_fm')->bind(
        '<ButtonRelease-1>' => sub {
            # From add mode forbid find mode
            $self->toggle_mode_find() if !$self->_model->is_mode('add');
        }
    );

    #-- Find execute
    $self->_view->get_toolbar_btn('tb_fe')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('find')
              ? $self->record_find_execute
              : $self->_view->set_status( 'Not find mode','ms','orange' );
        }
    );

    #-- Find count
    $self->_view->get_toolbar_btn('tb_fc')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('find')
              ? $self->record_find_count
              : $self->_view->set_status( 'Not find mode','ms','orange' );
        }
    );

    #-- Print (preview) default report button
    $self->_view->get_toolbar_btn('tb_pr')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('edit')
              ? $self->screen_report_print()
              : $self->_view->set_status( 'Not edit mode','ms','orange' );
        }
    );

    #-- Take note
    $self->_view->get_toolbar_btn('tb_tn')->bind(
        '<ButtonRelease-1>' => sub {
            ( $self->_model->is_mode('edit') or $self->_model->is_mode('add') )
              ? $self->take_note()
              : $self->_view->set_status( 'Not add|edit mode','ms','orange' );
        }
    );

    #-- Restore note
    $self->_view->get_toolbar_btn('tb_tr')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('add')
              ? $self->restore_note()
              : $self->_view->set_status( 'Not add mode','ms','orange' );
        }
    );

    #-- Clear screen
    $self->_view->get_toolbar_btn('tb_cl')->bind(
        '<ButtonRelease-1>' => sub {
            ( $self->_model->is_mode('edit') or $self->_model->is_mode('add') )
              ? $self->screen_clear()
              : $self->_view->set_status( 'Not add|edit mode','ms','orange' );
        }
    );

    #-- Reload
    $self->_view->get_toolbar_btn('tb_rr')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('edit')
              ? $self->record_reload()
              : $self->_view->set_status( 'Not edit mode','ms','orange' );
        }
    );

    #-- Add mode
    $self->_view->get_toolbar_btn('tb_ad')->bind(
        '<ButtonRelease-1>' => sub {
            $self->toggle_mode_add();
        }
    );

    #-- Save record
    $self->_view->get_toolbar_btn('tb_sv')->bind(
        '<ButtonRelease-1>' => sub {
            $self->save_record();
        }
    );

    #-- Quit
    $self->_view->get_toolbar_btn('tb_qt')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_view->on_quit;
        }
    );

    #-- Make some key bindings

    $self->_view->bind( '<Control-q>' => sub { $self->_view->on_quit } );
    $self->_view->bind(
        '<F5>' => sub {
            $self->_model->is_mode('edit')
              ? $self->record_reload()
              : $self->_view->set_status( 'Not edit mode','ms','orange' );
        }
    );
    $self->_view->bind(
        '<F7>' => sub {
            # From add mode forbid find mode
            $self->toggle_mode_find() if !$self->_model->is_mode('add');
        }
    );
    $self->_view->bind(
        '<F8>' => sub {
            $self->_model->is_mode('find')
              ? $self->record_find_execute
              : $self->_view->set_status( 'Not find mode','ms','orange' );
        }
    );
    $self->_view->bind(
        '<F9>' => sub {
            $self->_model->is_mode('find')
              ? $self->record_find_count
              : $self->_view->set_status( 'Not find mode','ms','orange' );
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

    $self->_log->trace("Setup event handler on NoteBook for '$page'");

    #- NoteBook events

    my $nb = $self->_view->get_notebook();

    $nb->pageconfigure(
        $page,
        -raisecmd => sub {
            if ($page eq 'lst') {
                $self->set_app_mode('sele');
                $self->_view->get_recordlist->focus;
            }
            else {
                if ( $self->record_load_new ) {
                    $self->set_app_mode('edit');
                }
                else {
                    $self->set_app_mode('idle');
                }
            }
        },
    );

    #- Enter on list item activates record page
    $self->_view->get_recordlist()->bind(
        '<Return>',
        sub {
            $self->_view->get_notebook->raise('rec');
            Tk->break;
        }
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
    $self->_screen->get_toolbar_btn('tb2ad')->bind(
        '<ButtonRelease-1>' => sub {
            $self->add_tmatrix_row();
        }
    );

    #-- Remove row button
    $self->_screen->get_toolbar_btn('tb2rm')->bind(
        '<ButtonRelease-1>' => sub {
            $self->remove_tmatrix_row();
        }
    );

    return;
}

=head2 _set_menus_enable

Disable some menus at start.

=cut

sub _set_menus_enable {
    my ($self, $state) = @_;

    foreach my $mnu (qw(mn_fm mn_fe mn_fc)) {
        $self->_view->get_menu_popup_item($mnu)->configure(
            -state => $state,
        );
    }
}

=head2 _check_app_menus

Check if screen modules from the menu exists and are loadable.
Disable those which fail the test.

=cut

sub _check_app_menus {
    my $self = shift;

    my $menu = $self->_view->get_menu_popup_item('menu_user');

    my $appmenus = $self->_view->get_app_menus_list();
    foreach my $menu_item ( @{$appmenus} ) {
        my ($class, $module_file) = $self->screen_module_class($menu_item);
        eval {require $module_file };
        if ($@) {
            $menu->entryconfigure($menu_item, -state => 'disabled');
        }
    }

    return;
}

=head2 setup_lookup_bindings

Creates widget bindings that use the L<Tpda3::Tk::Dialog::Search>
module to look-up value key translations from a table and put them in
one or more widgets.

The simplest configuration, with one lookup field and one return
field, looks like this:

 <bindings>
   <customer>
     table               = customers
     lookup              = customername
     field               = customernumber
   </customer>
 </bindings>

This configuration allows to lookup for a I<customernumber> in the
I<customers> table when knowing the I<customername>.  The
I<customername> and I<customernumber> fields must be defined in the
current table, with properties like width, label and order. this are
also the names of the widgets in the screen I<Orders>.  Multiple
I<field> items can be added to the configuration, to return more than
one value, and write its contents to the screen.

When the field names are different than the control names we need to
map the name of the fields with the name of the controls and the
configuration will be a little more complicated:

 <bindings>
   # Localitate domiciliu stabil
   <loc_ds>
     table               = localitati
    <lookup localitate>
      name               = loc_ds
    </lookup>
    <field id_judet>
      name               = id_jud_ds
    </field>
    <field cod_p>
      name               = cod_p_ds
    </field>
    <field id_loc>
      name               = id_loc_ds
    </field>
   </loc_ds>
 </bindings>

=cut

sub setup_lookup_bindings_entry {
    my $self = shift;

    my $dict     = Tpda3::Lookup->new;
    my $ctrl_ref = $self->_screen->get_controls();

    my $bindings = $self->_scrcfg->bindings;

    $self->_log->info("Setup binding for configured widgets");

    foreach my $bind_name ( keys %{$bindings} ) {

        # Skip if just an empty tag
        next unless $bind_name;

        # If 'search' is a hashref, get the first key, else the value
        my $search = ref $bindings->{$bind_name}{search}
                   ? (keys %{ $bindings->{$bind_name}{search} })[0]
                   : $bindings->{$bind_name}{search};

        # If 'search' is a hashref, get the first keys name attribute
        my $column = ref $bindings->{$bind_name}{search}
                   ? $bindings->{$bind_name}{search}{$search}{name}
                   : $search ;

        $self->_log->trace("Setup binding for '$bind_name'");

        # Compose the parameter for the 'Search' dialog
        my $para = {
            table  => $bindings->{$bind_name}{table},
            search => $search,
        };

        # Add the search field to the columns list
        my $field_cfg = $self->_scrcfg->maintable->{columns}{$column};
        my @cols;
        my $rec = {};
        $rec->{$search} = {
            width => $field_cfg->{width},
            label => $field_cfg->{label},
            order => $field_cfg->{order},
        };
        $rec->{$search}{name} = $column if $column; # add name attribute

        push @cols, $rec;

        # Detect the configuration style and add the 'fields' to the
        # columns list
        my $flds;
      SWITCH: for ( ref $bindings->{$bind_name}{field} ) {
            /^$/     && do {
                $flds =
                  $self->fields_cfg_one( 'maintable', $bindings->{$bind_name} );
                last SWITCH;
            };
            /array/i && do {
                $flds =
                  $self->fields_cfg_many( 'maintable', $bindings->{$bind_name} );
                last SWITCH;
            };
            /hash/i  && do {
                $flds =
                  $self->fields_cfg_named( 'maintable', $bindings->{$bind_name} );
                last SWITCH;
            };
            print "WW: Bindigs configuration style not recognised!\n";
            return;
        }
        push @cols, @{$flds};

        $para->{columns} = [@cols];    # add columns info to parameters

        my $filter;
        $ctrl_ref->{$column}[1]->bind(
            '<Return>' => sub {
                my $record = $dict->lookup( $self->_view, $para, $filter );
                $self->screen_write( $record, 'fields' );
            }
        );
    }

    return;
}

=head2 setup_bindings_table

Creates column bindings for table widgets created with
L<Tk::TableMatrix> using the information from the I<tablebindings>
section of the screen configuration.

This is a configuration example from the L<Orders> screen:

 <tablebindings tm1>
   <lookup>
     <products>
       bindcol           = 1
       table             = products
       search            = productname
       field             = productcode
     </products>
   </lookup>
   <method>
     <article>
       bindcol           = 4
       subname           = calculate_article
     </article>
   </method>
 </tablebindings>

First it creates a dispatch table:

 my $dispatch = {
     colsub1 => \&lookup,
     colsub4 => \&method,
 };

Then creates a class binding for I<method_for> subroutine to override
the default return binding.  I<method_for> than uses the dispatch
table to execute the appropriate function when the return key is
pressed inside a cell.

There are two functions defined, I<lookup> and I<method>.  The first
activates the L<Tpda3::Tk::Dialog::Search> module, to look-up value
key translations from a database table and fill the configured cells
with the results.  The second can call a method in the current screen.

=cut

sub setup_bindings_table {
    my $self = shift;

    foreach my $tm_ds ( keys %{ $self->_screen->get_tm_controls() } ) {

        my $bindings = $self->_scrcfg->tablebindings->{$tm_ds};

        my $dispatch = {};
        foreach my $bind_type ( keys %{$bindings} ) {
            next unless $bind_type;            # skip if just an empty tag

            my $bnd = $bindings->{$bind_type};
            if ($bind_type eq 'lookup') {
                foreach my $bind_name ( keys %{$bnd} ) {
                    next unless $bind_name;    # skip if just an empty tag
                    my $lk_bind = $bnd->{$bind_name};
                    my $lookups = $self->add_dispatch_for_lookup($lk_bind);
                    @{$dispatch}{ keys %{$lookups} } = values %{$lookups};
                }
            }
            elsif ($bind_type eq 'method') {
                foreach my $bind_name ( keys %{$bnd} ) {
                    next unless $bind_name;    # skip if just an empty tag
                    my $mt_bind = $bnd->{$bind_name};
                    my $methods = $self->add_dispatch_for_method($mt_bind);
                    @{$dispatch}{ keys %{$methods} } = values %{$methods};
                }
            }
            else {
                print "WW: Binding type '$bind_type' not implemented\n";
                return;
            }
        }

        # Bindings:
        my $tm = $self->_screen->get_tm_controls($tm_ds);
        $tm->bind(
            'Tk::TableMatrix',
            '<Return>',
            sub {
                my $r  = $tm->index( 'active', 'row' );
                my $c  = $tm->index( 'active', 'col' );
                # Table refresh
                $tm->activate('origin');
                $tm->activate("$r,$c");
                $tm->reread();

                my $ci = $tm->cget( -cols ) - 1; # max col index
                my $sc = $self->method_for( $dispatch, $bindings, $r,$c, $tm_ds );
                my $ac = $c;
                $sc ||= 1;          # skip cols
                $ac += $sc;         # new active col
                $tm->activate( "$r,$ac" );
                $tm->see('active');
                Tk->break;
            }
        );
    }

    return;
}

=head2 add_dispatch_for_lookup

Return an entry in the dispatch table for a I<lookup> type binding.

=cut

sub add_dispatch_for_lookup {
    my ($self, $bnd) = @_;

    my $bindcol = 'colsub' . $bnd->{bindcol};

    return { $bindcol => \&lookup };
}

=head2 add_dispatch_for_method

Return an entry in the dispatch table for a I<method> type binding.

=cut

sub add_dispatch_for_method {
    my ( $self, $bnd ) = @_;

    my $bindcol = 'colsub' . $bnd->{bindcol};

    return { $bindcol => \&method };
}

=head2 method_for

This is bound to the Return key, and executes a function as defined in
the configuration, using a dispatch table.

=cut

sub method_for {
    my ($self, $dispatch, $bindings, $r, $c, $tm_ds) = @_;

    my $skip_cols;
    my $proc = "colsub$c";
    if ( exists $dispatch->{$proc} ) {
        $skip_cols = $dispatch->{$proc}->($self, $bindings, $r, $c, $tm_ds);
    }

    return $skip_cols;
}

=head2 lookup

Activates the L<Tpda3::Tk::Dialog::Search> module, to look-up value
key translations from a database table and fill the configured cells
with the results.

=cut

sub lookup {
    my ($self, $bnd, $r, $c, $tm_ds) = @_;

    my $lk_para = $self->get_lookup_setings($bnd, $r, $c, $tm_ds);

    # Check and set filter
    my $filter;
    if ( $lk_para->{filter} ) {
        my $fld = $lk_para->{filter};
        my $col = $self->_scrcfg->deptable->{$tm_ds}{columns}{$fld}{id};
        $filter = $self->control_tmatrix_read_cell($r, $col);
    }

    my $dict   = Tpda3::Lookup->new;
    my $record = $dict->lookup( $self->_view, $lk_para, $filter );

    $self->control_tmatrix_write_row( $r, $c, $record, $tm_ds );

    my $skip_cols = scalar @{ $lk_para->{columns} }; # skip ahead cols number

    return $skip_cols;
}

=head2 method

Call a method from the Screen module on I<Return> key.

=cut

sub method {
    my ($self, $bnd, $r, $c) = @_;

    # Filter on bindcol = $c
    my @names = grep { $bnd->{method}{$_}{bindcol} == $c }
                keys %{ $bnd->{method} };
    my $bindings = $bnd->{method}{ $names[0] };

    my $method = $bindings->{subname};
    if ( $self->{_scrobj}->can($method) ) {
        $self->{_scrobj}->$method($r);
        #$self->{_scrobj}->calculate_order_line($r);
    }
    else {
        print "WW: '$method' not implemented!\n";
    }

    return 1;                   # skip_cols
}

=head2 get_lookup_setings

Return the data structure used by the L<Tpda3::Tk::Dialog::Search>
module.  Uses the I<tablebindings> section of the screen configuration
and the related field attributes from the I<deptable> section.

=over

=item I<search>  - field name to be searched for a substring

=item I<columns> - columns to be displayed in the list, with attributes

=item I<table>   - name of the look-up table

=back

An example data structure, for the Orders screen:

 {
    'search'  => 'productname',
    'columns' => [
        {
            'productname' => {
                'width' => 36,
                'order' => 'A',
                'name'  => 'productname',
                'label' => 'Product',
            }
        },
        {
            'productcode' => {
                'width' => 15,
                'order' => 'A',
                'label' => 'Code',
            }
        },
    ],
    'table' => 'products',
 }

=cut

sub get_lookup_setings {
    my ($self, $bnd, $r, $c, $tm_ds) = @_;

    # Filter on bindcol = $c
    my @names = grep { $bnd->{lookup}{$_}{bindcol} == $c }
                keys %{ $bnd->{lookup} };
    my $bindings = $bnd->{lookup}{ $names[0] };

    # If 'search' is a hashref, get the first key, else the value
    my $search = ref $bindings->{search}
               ? (keys %{ $bindings->{search} })[0]
               : $bindings->{search};

    # If 'search' is a hashref, get the first keys name attribute
    my $column = ref $bindings->{search}
               ? $bindings->{search}{$search}{name}
               : $search;

    # If 'filter'
    my $filter = $bindings->{filter}
               ? $bindings->{filter}
               : q{};
    # print "WW: Filter setting = $filter \n";

    $self->_log->trace("Setup binding for $search:$column");

    # Compose the parameter for the 'Search' dialog
    my $lk_para = {
        table  => $bindings->{table},
        filter => $filter,
        search => $search,
    };

    # Add the search field to the columns list
    my $field_cfg = $self->_scrcfg->deptable->{$tm_ds}{columns}{$column};
    my @cols;
    my $rec = {};
    $rec->{$search} = {
        width => $field_cfg->{width},
        label => $field_cfg->{label},
        order => $field_cfg->{order},
    };
    $rec->{$search}{name} = $column if $column; # add name attribute

    push @cols, $rec;

    # Detect the configuration style and add the 'fields' to the
    # columns list
    my $flds;
  SWITCH: for ( ref $bindings->{field} ) {
        /^$/     && do {
            $flds = $self->fields_cfg_one('deptable', $bindings, $tm_ds);
            last SWITCH;
        };
        /array/i && do {
            $flds = $self->fields_cfg_many('deptable', $bindings, $tm_ds);
            last SWITCH;
        };
        /hash/i  && do {
            $flds = $self->fields_cfg_named('deptable', $bindings, $tm_ds);
            last SWITCH;
        };
        print "WW: Bindigs configuration style?\n";
        return;
    }
    push @cols, @{$flds};

    $lk_para->{columns} = [@cols];    # add columns info to parameters

    return $lk_para;
}

=head2 fields_cfg_one

Just one field atribute.

=cut

sub fields_cfg_one {
    my ( $self, $table, $bindings, $tm_ds ) = @_;

    # One field, no array
    my @cols;
    my $fld = $bindings->{field};
    my $field_cfg;
    if ($tm_ds) {
        $field_cfg = $self->_scrcfg->{$table}{$tm_ds}{columns}{$fld};
    }
    else {
        $field_cfg = $self->_scrcfg->{$table}{columns}{$fld};
    }
    my $rec = {};
    $rec->{$fld} = {
        width => $field_cfg->{width},
        label => $field_cfg->{label},
        order => $field_cfg->{order},
    };
    push @cols, $rec;

    return \@cols;
}

=head2 fields_cfg_many

Multiple return fields.

=cut

sub fields_cfg_many {
    my ( $self, $table, $bindings, $tm_ds ) = @_;

    my @cols;

    # Multiple fields returned as array
    foreach my $fld ( @{ $bindings->{field} } ) {
        my $field_cfg;
        if ($tm_ds) {
            $field_cfg = $self->_scrcfg->{$table}{$tm_ds}{columns}{$fld};
        }
        else {
            $field_cfg = $self->_scrcfg->{$table}{columns}{$fld};
        }
        my $rec = {};
        $rec->{$fld} = {
            width => $field_cfg->{width},
            label => $field_cfg->{label},
            order => $field_cfg->{order},
        };
        push @cols, $rec;
    }

    return \@cols;
}

=head2 fields_cfg_named

Multiple return fields and widget name different from field name.

=cut

sub fields_cfg_named {
    my ( $self, $table, $bindings, $tm_ds ) = @_;

    my @cols;
    # Multiple fields returned as array
    foreach my $fld ( keys %{ $bindings->{field} } ) {
        my $name = $bindings->{field}{$fld}{name};
        my $field_cfg;
        if ($tm_ds) {
            $field_cfg = $self->_scrcfg->{$table}{$tm_ds}{columns}{$fld};
        }
        else {
            $field_cfg = $self->_scrcfg->{$table}{columns}{$fld};
        }
        my $rec = {};
        $rec->{$fld} = {
            width => $field_cfg->{width},
            label => $field_cfg->{label},
            order => $field_cfg->{order},
            name  => $name,
        };
        push @cols, $rec;
    }

    return \@cols;
}

=head2 set_app_mode

Set application mode

=cut

sub set_app_mode {
    my ($self, $mode) = @_;

    $self->_model->set_mode($mode);

    $self->toggle_interface_controls;

    return unless ref $self->_screen;

    # TODO: Should this be called on all screens?
    $self->toggle_screen_interface_controls;

    if ( my $method_name = $self->{method_for}->{$mode} ) {
        $self->$method_name();
    }
    else {
        print "WW: '$mode' not implemented!\n";
    }

    return 1;                       # to make ok from Test::More happy
                                    # probably missing something :) TODO!
}

=head2 is_record

Return true if a record is loaded in screen.

=cut

sub is_record {
    my $self = shift;

    # Check screen
    $self->screen_read();

    my $is_record = scalar keys %{ $self->{scrdata} };

    # my $yesno = $is_record ? "Yes" : "No";
    # print "Has records? $yesno!\n";

    return $is_record;
}

=head2 on_screen_mode_idle

when in I<idle> mode set status to I<normal> and clear all controls
content in the I<Screen> than set status of controls to I<disabled>.

=cut

sub on_screen_mode_idle {
    my $self = shift;

    # Empty the main controls and TM, if any

    $self->screen_write(undef, 'clear');

    foreach my $tm_ds ( keys %{ $self->_screen->get_tm_controls() } ) {
        $self->control_tmatrix_write(undef, $tm_ds);
    }

    $self->controls_state_set('off');

    return;
}

=head2 on_screen_mode_add

When in I<add> mode set status to I<normal> and clear all controls
content in the I<Screen> and change the background to the default
color as specified in the configuration.

=cut

sub on_screen_mode_add {
    my ($self, ) = @_;

    # Empty the main controls and TM, if any

    $self->screen_write(undef, 'clear');

    foreach my $tm_ds ( keys %{ $self->_screen->get_tm_controls() } ) {
        $self->control_tmatrix_write(undef, $tm_ds);
    }

    $self->controls_state_set('edit');

    return;
}

=head2 on_screen_mode_find

When in I<find> mode set status to I<normal> and clear all controls
content in the I<Screen> and change the background to light green.

=cut

sub on_screen_mode_find {
    my $self = shift;

    # Empty the main controls and TM, if any

    $self->screen_write(undef, 'clear');

    foreach my $tm_ds ( keys %{ $self->_screen->get_tm_controls() } ) {
        $self->control_tmatrix_write(undef, $tm_ds);
    }

    $self->controls_state_set('find');

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

=head2 screen_module_class

Return screen module class and file name.

=cut

sub screen_module_class {
    my ($self, $module) = @_;

    my $app_name  = $self->_cfg->application->{module};

    my $module_class = "Tpda3::Tk::App::${app_name}::${module}";

    (my $module_file = "$module_class.pm") =~ s{::}{/}g;

    return ($module_class, $module_file);
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

    my ($class, $module_file) = $self->screen_module_class($module);
    eval {require $module_file };
    if ($@) {
        # TODO: Decide what is optimal to do here?
        print "WW: Can't load '$module_file'\n";
        return;
    }

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
    $self->{_scrobj}->run_screen( $nb, $self->{_scrcfg} );

    my $screen_type = $self->_scrcfg->screen->{type};

    # Load instance config
    $self->_cfg->config_load_instance();

    # Update window geometry from instance config if exists or from
    # defaults
    my $geom;
    if ( $self->_cfg->can('geometry') ) {
        $geom = $self->_cfg->geometry->{ $self->{_scrstr} };
        unless ($geom) {
            $geom = $self->_scrcfg->screen->{geometry};
        }
    }
    else {
        $geom = $self->_scrcfg->screen->{geometry};
    }
    $self->_view->set_geometry($geom);

    # Event handlers
    $self->_set_event_handler_screen() if $screen_type eq 'tablematrix';
    #-- Lookup bindings for Tk::Entry widgets
    $self->setup_lookup_bindings_entry();
    #-- Lookup bindings for tables (TableMatrix)
    $self->setup_bindings_table();

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

    # TableMatrix header(s), if any
    foreach my $tm_ds ( keys %{ $self->_screen->get_tm_controls() } ) {
        my $tm_object = $self->_screen->get_tm_controls($tm_ds);
        my $tm_fields = $self->_scrcfg->deptable->{$tm_ds}{columns};
        $self->_view->make_tablematrix_header( $tm_object, $tm_fields );
    }

    # Load lists into JBrowseEntry or JComboBox widgets
    $self->screen_init();

    $self->_set_menus_enable('normal');

    $self->_view->set_status('','ms');

    return 1;                       # to make ok from Test::More happy
                                    # probably missing something :) TODO!
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
    my $ctrl_ref = $self->_screen->get_controls();
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
        my $cod_a_ref = $self->{_model}->get_codes($field, $para);

        if ( $ctrltype eq 'm' ) {

            # JComboBox
            # if ( $ctrl_ref->{$field}[1] ) {
            #     $ctrl_ref->{$field}[1]->removeAllItems();
            #     while ( my ( $code, $label ) = each( %{$cod_h_ref} ) ) {
            #         $ctrl_ref->{$field}[1]
            #             ->insertItemAt( 'end', $label, -value => $code );
            #     }
            # }
            if ( $ctrl_ref->{$field}[1] ) {
                $ctrl_ref->{$field}[1]->removeAllItems();
                $ctrl_ref->{$field}[1]->configure(-choices => $cod_a_ref);
            }
        }
        elsif ( $ctrltype eq 'l' ) {

            # my @lvpairs;
            # while ( my ( $code, $label ) = each( %{$cod_h_ref} ) ) {
            #     push( @lvpairs,{ value => $code, label => $label });
            # }

            # # MatchingBE
            # if ( $ctrl_ref->{$field}[1] ) {
            #     $ctrl_ref->{$field}[1]->configure(
            #         -labels_and_values => \@lvpairs,
            #     );
            # }
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

        # Take note button
        if ( $name eq 'tb_tn' and $self->{_scrstr} ) {
            $status = 'normal'   if $self->_model->is_mode('add');
            $status = 'disabled' if !$self->is_record();
        }

        # Restore note
        if ( $name eq 'tb_tr' and $self->{_scrstr} ) {
            my $data_file = $self->note_file_name();
            $status = $self->_model->is_mode('add')
                    ? 'normal'
                    : 'disabled';
            $status = 'disabled' if !-f $data_file;
        }

        # Print preview
        # Activate only if default report configured for screen

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
        $self->_screen->enable_tool($name, $state);
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
    if ( ! defined $pk_id ) {
        $self->_view->set_status('Nothing selected','ms','orange');
        return;
    }

    my $ret = $self->record_load($pk_id);

    if ($ret) {
        $self->_view->set_status('Record loaded','ms','blue');
        $self->_model->set_modified(q{});    # empty
    }

    return $ret;
}

=head2 screen_clear

Clear the screen: empty all controls.

=cut

sub screen_clear {
    my $self = shift;

    return unless ref $self->_screen;

    $self->screen_write(undef, 'clear');      # Empty the main controls

    if ($self->_model->is_mode('edit')) {
        $self->set_app_mode('idle');
    }

    $self->_view->set_status( 'Cleared','ms','orange' );

    return;
}

=head2 record_find_execute

Execute search.

In the screen configuration file, there is an attribute named
I<findtype>, defined for every field of the table associated with the
screen and used to control the behavior of count and search.

All controls from the screen with I<findtype> configured other than
I<none>, are read. The values are used to create a perl data structure
used by the SQL::Alstract module to build a SQL WHERE clause.

The accepted values for I<findtype> are:

=over

=item contains - like

=item allstr   - field = value

=item date     - Used for date widgets, see below

=item none     - Counting and searching for the field is disabled

=back

A special form is used for the date fields, to allow to search by year
and month.

=over

=item year       - yyyy

=item year-month - yyyy<sep>mm or yyyy<sep>m or mm<sep>yyyy or m<sep>yyyy

The separator <sep> can be a point (.), a dash (-) or a slash (/).

=item date       - full date string

=back

A I<special_ops> sub is used to teach SQL::Abstract to create the
required SQL WHERE clause.

EXAMPLES:

If the user enters a year like '2009' (four digits) in a date field
than the generated WHERE Clause will look like this:

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
    my $maintable  = $self->_scrcfg->maintable;
    my $columns = $self->_scrcfg->maintable->{columns};

    my $params = {};

    # Columns data (for found list)
    $params->{columns} = $self->_scrcfg->found_cols->{col};

    # Add findtype info to screen data
    while ( my ( $field, $value ) = each( %{$self->{scrdata} } ) ) {
        my $findtype = $columns->{$field}{findtype};
        $findtype = q{contains} if $value eq q{%}; # allow search by
                                                   # field contents
        $params->{where}{$field} = [ $value, $findtype ];
    }

    # Table data
    $params->{table} = $maintable->{view};   # use view instead of table
    $params->{pkcol} = $maintable->{pkcol}{name};

    $self->_view->list_init();
    my $record_count = $self->_view->list_populate($params);

    # Set mode to sele if found
    if ($record_count > 0) {
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
    my $maintable  = $self->_scrcfg->maintable;
    my $columns = $self->_scrcfg->maintable->{columns};

    my $params = {};

    # Add findtype info to screen data
    while ( my ( $field, $value ) = each( %{$self->{scrdata} } ) ) {
        my $findtype = $columns->{$field}{findtype};
        $findtype = q{contains} if $value eq q{%}; # allow count by
                                                   # field contents
        $params->{where}{$field} = [ $value, $findtype ];
    }

    # Table data
    $params->{table} = $maintable->{view};   # use view instead of table
    $params->{pkcol} = $maintable->{pkcol}{name};

    $self->_model->query_records_count($params);

    return;
}

=head2 screen_report_print

Printing report configured as default with Report Manager.

=cut

sub screen_report_print {
    my $self = shift;

    return unless ref $self->_screen;

    # my $script = $self->{tpda}{conf}->get_screen_conf_raport('script');
    # my $report = $self->{tpda}{conf}->get_screen_conf_raport('content');
    # print "report ($script) = $report\n";

    # # ID (name, width)
    # my $pk_href = $self->{tpda}{conf}->get_screen_conf_table('pk_col');
    # my $pk_col_name = $pk_href->{name};
    # my $eobj = $self->_screen->get_eobj_rec();
    # my $id_val = $eobj->{$pk_col_name}[3]->get;
    # # print "$pk_col_name = $id_val\n";

    # if ($id_val) {
    #     # Default paramneter ID
    #     $param = "$pk_col_name=$id_val";
    # } else {
    #     # Atentie
    #     my $textstr = "Load a record first";
    #     $self->{mw}{dialog1}->configure( -text => $textstr );
    #     $self->{mw}{dialog1}->Show();
    #     return;
    # }

    # Configurari
    my $repxp   = $self->_cfg->cfextapps->{repmanexe};
    my $reppath = $self->_cfg->cfextapps->{reportspath};

    # $report_name =
    #     $self->{tpda}{cfg_ref}{conf_dir} .'/'. $reppath .'/'. $report;

    # # Metaviewxp
    # if (defined($param) and defined($param2) and defined($param3)) {
    #     # print "3 parameters!\n";
    #     $cmd = "$repxp -preview -param$param -param$param2 -param$param3 $report_name";
    # } elsif (defined($param) and defined($param2)) {
    #     # print "2 parameters!\n";
    #     $cmd = "$repxp -preview -param$param -param$param2 $report_name";
    # } elsif (defined($param)) {
    #     # print "1 parameter!\n";
    #     $cmd = "$repxp -preview -param$param $report_name";
    # } else {
    #     # print "0 parameters?\n";
    #     return;
    # }

    # # print $cmd."\n";
    # if (system($cmd)) {
    #     print "Raportare esuata\n";
    # }

    return;
}

=head2 screen_read

Read screen controls (widgets) and save in a Perl data stucture.

=cut

sub screen_read {
     my ($self, $all) = @_;

     # Initialize
     $self->{scrdata} = {};

     my $ctrl_ref = $self->_screen->get_controls();
     return unless scalar keys %{$ctrl_ref};

     # Scan and write to controls
   FIELD:
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
                 # print " skiping RO field '$field'\n";
                 next;
             }
         }

         # Run appropriate sub according to control (entry widget) type
         my $sub_name = "control_read_$ctrltype";
         if ( $self->can($sub_name) ) {
             unless ( $ctrl_ref->{$field}[1] ) {
                 print "WW: Undefined field '$field', check configuration!\n";
                 next FIELD;
             }
             $self->$sub_name( $ctrl_ref, $field );
         }
         else {
             print "WW: No '$ctrltype' ctrl type for reading '$field'!\n";
         }
     }

     return;
}

=head2 control_read_e

Read contents of a Tk::Entry control.

=cut

sub control_read_e {
    my ( $self, $ctrl_ref, $field ) = @_;

    my $value = $ctrl_ref->{$field}[1]->get;

    # Add value if not empty
    if ( $value =~ /\S+/ ) {

        # Clean '\n' from end
        $value =~ s/\n$//mg;    # m=multiline

        $self->{scrdata}{$field} = $value;
        # print "Screen (e): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{scrdata}{$field} = undef;
            # print "Screen (e): $field = undef\n";
        }
    }

    return;
}

=head2 control_read_t

Read contents of a Tk::Text control.

=cut

sub control_read_t {
    my ( $self, $ctrl_ref, $field ) = @_;

    my $value = $ctrl_ref->{$field}[1]->get( '0.0', 'end' );

    # Add value if not empty
    if ( $value =~ /\S+/ ) {

        # Clean '\n' from end
        $value =~ s/\n$//mg;    # m=multiline

        $self->{scrdata}{$field} = $value;
        # print "Screen (t): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{scrdata}{$field} = undef;
            # print "Screen (t): $field = undef\n";
        }
    }

    return;
}

=head2 control_read_d

Read contents of a Tk::DateEntry control.

=cut

sub control_read_d {
    my ( $self, $ctrl_ref, $field ) = @_;

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
        # print "Screen (d): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{scrdata}{$field} = undef;
            # print "Screen (d): $field = undef\n";
        }
    }

    return;
}

=head2 control_read_m

Read contents of a Tk::JComboBox control.

=cut

sub control_read_m {
    my ( $self, $ctrl_ref, $field ) = @_;

    my $value = ${ $ctrl_ref->{$field}[0] }; # Value from variable

    # Add value if not empty
    if ( $value =~ /\S+/ ) {

        # Delete '\n' from end
        $value =~ s/\n$//mg;        # m=multiline

        $self->{scrdata}{$field} = $value;
        # print "Screen (m): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{scrdata}{$field} = undef;
            # print "Screen (m): $field = undef\n";
        }
    }

    return;
}

=head2 control_read_l

Read contents of a Tk::MatchingBE control.

=cut

sub control_read_l {
    my ( $self, $ctrl_ref, $field ) = @_;

    my $value = $ctrl_ref->{$field}[1]->get_selected_value() || q{};

    # Add value if not empty
    if ( $value =~ /\S+/ ) {

        # Delete '\n' from end
        $value =~ s/\n$//mg;        # m=multiline

        $self->{scrdata}{$field} = $value;
        # print "Screen (l): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{scrdata}{$field} = undef;
            # print "Screen (l): $field = undef\n";
        }
    }

    return;
}

=head2 control_read_c

Read state of a Checkbox.

=cut

sub control_read_c {
    my ( $self, $ctrl_ref, $field ) = @_;

    my $value = ${ $ctrl_ref->{$field}[0] };

    if ( $value == 1 ) {
        $self->{scrdata}{$field} = $value;
        # print "Screen (c): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{scrdata}{$field} = $value;
            # print "Screen (c): $field = undef\n";
        }
    }

    return;
}

=head2 control_read_r

Read RadiobuttonGroup.

=cut

sub control_read_r {
    my ( $self, $ctrl_ref, $field ) = @_;

    my $value = ${ $ctrl_ref->{$field}[0] };
    $value = q{} if !defined $value; # empty string

    # Add value if not empty
    if ( $value =~ /\S+/ ) {
        $self->{scrdata}{$field} = $value;
        # print "Screen (r): $field = $value\n";
    }
    else {
        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{scrdata}{"$field:r"} = undef;
            # print "Screen (r): $field = undef\n";
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

    my $ctrl_ref = $self->_screen->get_controls();

    return unless scalar keys %{$ctrl_ref};  # no controls?

  FIELD:
    foreach my $field ( keys %{ $self->_scrcfg->maintable->{columns} } ) {

        my $fld_cfg = $self->_scrcfg->maintable->{columns}{$field};

        my $ctrl_state;
        eval {
            $ctrl_state = $ctrl_ref->{$field}[1]->cget( -state );
        };
        if ($@) {
            print "WW: Undefined field '$field', check configuration!\n";
            next FIELD;
        }
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
            my $places = $fld_cfg->{places};
            if ($places) {
                if ( $places > 0 ) {

                    # if places > 0, format as number
                    $value = sprintf( "%.${places}f", $value );
                }
            }
        }

        # Run appropriate sub according to control (entry widget) type
        my $sub_name = qq{control_write_$ctrltype};
        if ( $self->can($sub_name) ) {
            $self->$sub_name( $ctrl_ref, $field, $value );
        }
        else {
            print "WW: No '$ctrltype' ctrl type for writing '$field'!\n";
        }

        # Restore state
        $ctrl_ref->{$field}[1]->configure( -state => $ctrl_state );
    }

    # $self->_log->trace("Write finished (restored controls states)");

    return;
}

=head2 control_tmatrix_read

Read data from a table matrix widget.

=cut

sub control_tmatrix_read {
    my ($self, $tm_ds) = @_;

    $tm_ds ||= q{tm1};           # default table matrix designator

    my $tm_object = $self->_screen->get_tm_controls($tm_ds);
    my $xtvar;
    if ($tm_object) {
        $xtvar = $tm_object->cget( -variable );
    }
    else {
        print "EE: Can't find '$tm_ds' table\n";
        return;
    }

    my $rows_no  = $tm_object->cget( -rows );
    my $cols_no  = $tm_object->cget( -cols );
    my $rows_idx = $rows_no - 1;
    my $cols_idx = $cols_no - 1;

    my $fields_cfg = $self->_scrcfg->deptable->{$tm_ds}{columns};
    my $cols_ref   = Tpda3::Utils->sort_hash_by_id($fields_cfg);

    # Read table data and create an AoH
    my @tabledata;

    # The first row is the header
    for my $row ( 1 .. $rows_idx ) {

        my $rowdata = {};
        for my $col ( 0 .. $cols_idx ) {

            my $cell_value = $tm_object->get("$row,$col");
            my $col_name = $cols_ref->[$col];

            my $fld_cfg = $fields_cfg->{$col_name};
            my ($rw ) = @$fld_cfg{'rw'};     # hash slice

            next if $rw eq 'ro'; # skip ro cols

            # print "$row: $col_name => $cell_value\n";
            $rowdata->{$col_name} = $cell_value;
        }

        push @tabledata, $rowdata;
    }

    return \@tabledata;
}

sub control_tmatrix_read_cell {
    my ($self, $row, $col, $tm_ds) = @_;

    $tm_ds ||= q{tm1};           # default table matrix designator

    my $tm_object = $self->_screen->get_tm_controls($tm_ds);
    my $xtvar;
    if ($tm_object) {
        $xtvar = $tm_object->cget( -variable );
    }
    else {

        # Just ignore :)
        return;
    }

    my $fields_cfg = $self->_scrcfg->deptable->{$tm_ds}{columns};
    my $cols_ref   = Tpda3::Utils->sort_hash_by_id($fields_cfg);
    my $cell_value = $tm_object->get("$row,$col");
    my $col_name   = $cols_ref->[$col];

    return {$col_name => $cell_value};
}

=head2 control_tmatrix_write

Write data to TableMatrix widget

=cut

sub control_tmatrix_write {
    my ($self, $record_ref, $tm_ds) = @_;

    $tm_ds ||= q{tm1};           # default table matrix designator

    my $tm_object = $self->_screen->get_tm_controls($tm_ds);
    my $xtvar;
    if ($tm_object) {
        $xtvar = $tm_object->cget( -variable );
    }
    else {
        return;
    }

    my $row = 1;

    #- Scan and write to table

    foreach my $record ( @{$record_ref} ) {
        foreach my $field ( keys %{ $self->_scrcfg->deptable->{$tm_ds}{columns} } ) {
            my $fld_cfg = $self->_scrcfg->deptable->{$tm_ds}{columns}{$field};

            croak "$field field's config is EMPTY\n" unless %{$fld_cfg};

            my $value = $record->{$field};
            $value = q{} unless defined $value;    # empty
            $value =~ s/[\n\t]//g;                 # delete control chars

            my ( $col, $validtype, $width, $places ) =
              @$fld_cfg{'id','validation','width','places'}; # hash slice

            if ( $validtype eq 'numeric' ) {
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

sub control_tmatrix_write_row {
    my ($self, $row, $col, $record_ref, $tm_ds) = @_;

    return unless ref $record_ref;     # No results

    $tm_ds ||= q{tm1};           # default table matrix designator

    my $tm_object = $self->_screen->get_tm_controls($tm_ds);
    my $xtvar;
    if ($tm_object) {
        $xtvar = $tm_object->cget( -variable );
    }
    else {

        # Just ignore :)
        return;
    }

    my $nr_col = 0;
    foreach my $field ( keys %{$record_ref} ) {

        my $fld_cfg = $self->_scrcfg->deptable->{$tm_ds}{columns}{$field};
        my $value = $record_ref->{$field};

        my ( $col, $validtype, $width, $places ) =
            @$fld_cfg{'id','validation','width','places'}; # hash slice

        if ( $validtype =~ /digit/ ) {
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
        $nr_col++;
    }

    return $nr_col;
}

=head2 toggle_mode_find

Toggle find mode, ask to save record if modified.

=cut

sub toggle_mode_find {
    my $self = shift;

    $self->ask_to_save() if $self->_model->is_modified;

    $self->_model->is_mode('find')
        ? $self->set_app_mode('idle')
        : $self->set_app_mode('find');

    $self->_view->set_status( '','ms' ); # clear messages

    return;
}

=head2 toggle_mode_add

Toggle add mode, ask to save record if modified.

=cut

sub toggle_mode_add {
    my $self = shift;

    $self->ask_to_save() if $self->_model->is_modified;

    $self->_model->is_mode('add')
        ? $self->set_app_mode('idle')
        : $self->set_app_mode('add');

    $self->_view->set_status( '','ms' ); # clear messages

    return;
}

=head2 controls_state_set

Toggle all controls state from I<Screen>.

=cut

sub controls_state_set {
    my ( $self, $state ) = @_;

    $self->_log->trace("Screen controls state is '$state'");

    my $ctrl_ref = $self->_screen->get_controls();
    return unless scalar keys %{$ctrl_ref};

    my $control_states = $self->control_states($state);

    return unless defined $self->_scrcfg;

    foreach my $field ( keys %{ $self->{_scrcfg}->maintable->{columns} } ) {

        my $fld_cfg = $self->{_scrcfg}->maintable->{columns}{$field};

        # Skip for some control types
        # next if $fld_cfg->{ctrltype} = '';

        my $ctrl_state = $control_states->{state};
        $ctrl_state = $fld_cfg->{state}
            if $ctrl_state eq 'from_config';

        my $bkground = $control_states->{background};
        my $bg_color = $bkground;
        $bg_color = $fld_cfg->{bgcolor}
            if $bkground eq 'from_config';
        $bg_color = $self->_screen->get_bgcolor()
            if $bkground eq 'disabled_bgcolor';

        # Special case for find mode and fields with 'findtype' set to none
        if ( $state eq 'find' ) {
            if ( $fld_cfg->{findtype} eq 'none' ) {
                $ctrl_state = 'disabled';
                $bg_color   = $self->_screen->get_bgcolor();
            }
        }

        # Configure controls
        eval {
            $ctrl_ref->{$field}[1]->configure( -state => $ctrl_state, );
            $ctrl_ref->{$field}[1]->configure( -background => $bg_color, );
        };
        if ($@) {
            # print "Problems with '$field'\n";
        }
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

=head2 control_write_c

Write to a Tk::Checkbox widget.

=cut

sub control_write_c {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    $value = 0 unless $value;
    if ( $value == 1 ) {
       $ctrl_ref->{$field}[1]->select;
    }
    else {
        $ctrl_ref->{$field}[1]->deselect;
    }

    # # Execute sub defined in screen bound to checkbox
    # # Sub name must be: 'sw_' + 'field_name'
    # # Check if sub exists is defined first
    # my $sub_name = "sw_$field";
    # if ( $self->{scrobj}->can($sub_name) ) {
    #     $self->{scrobj}->$sub_name;
    # }
}

=head2 control_write_r

Write to a Tk::RadiobuttonGroup widget.

=cut

sub control_write_r {
    my ( $self, $ctrl_ref, $field, $value ) = @_;

    if ( $value ) {
        ${ $ctrl_ref->{$field}[0] } = $value;
    }
    else {
        ${ $ctrl_ref->{$field}[0] } = undef;
    }

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

sub add_tmatrix_row {
    my ($self, $valori_ref, $tm_ds) = @_;

    $tm_ds ||= q{tm1};           # default table matrix designator

    my $xt = $self->_screen->get_tm_controls($tm_ds);

    unless ( $self->_model->is_mode('add')
                 || $self->_model->is_mode('edit') ) {
        return;
    }

    $xt->configure( state => 'normal' );     # Stare normala

    $xt->insertRows('end');
    my $r = $xt->index( 'end', 'row' );

    $xt->set( "$r,0", $r );     # Daca am parametru 2, introduc datele
    my $c = 1;
    if ( ref($valori_ref) eq 'ARRAY' ) {

        # Inserez datele
        foreach my $valoare ( @{$valori_ref} ) {
            if ( defined $valoare ) {
                $xt->set( "$r,$c", $valoare );
            }
            $c++;
        }
    }

    # Focus la randul nou inserat, coloana 1
    $xt->focus;
    $xt->activate("$r,1");
    $xt->see("$r,1");

    return;
}

=head2 remove_tmatrix_row

Delete TableMatrix row

=cut

sub remove_tmatrix_row {
    my ($self, $tm_ds) = @_;

    $tm_ds ||= q{tm1};           # default table matrix designator

    my $xt = $self->_screen->get_tm_controls($tm_ds);

    unless ( $self->_model->is_mode('add')
                 || $self->_model->is_mode('edit') ) {
        return;
    }

    $xt->configure( state => 'normal' );     # Stare normala

    my $r;
    eval {
        $r = $xt->index( 'active', 'row' );

        if ( $r >= 1 ) {
            $xt->deleteRows( $r, 1 );
        }
        else {
            $self->_view->set_status('Select a row','ms','orange');
        }
    };
    if ($@) {
        warn "Warning: $@";
    }

    $self->renum_tmatrix_row($xt);           # renumerotare randuri

    # Calcul total desfasurator; check if sub exists first
    # if ( $self->{tpda}->{screen_curr}->can('calcul_total_des_tm2') ) {
    #     $self->{tpda}->{screen_curr}->calcul_total_des_tm2;
    # }

    return $r;
}

=head2 renum_tmatrix_row

Renumber TableMatrix rows

=cut

sub renum_tmatrix_row {
    my ($self, $xt) = @_;

    my $r = $xt->index( 'end', 'row' );

    if ( $r >= 1 ) {
        foreach my $i ( 1 .. $r ) {
            $xt->set( "$i,0", $i );
        }
    }

    return;
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

    $self->screen_read();

    # Table metadata
    my $maintable   = $self->_scrcfg->maintable;
    my $pk_col_name = $maintable->{pkcol}{name};

    my $ctrl_ref = $self->_screen->get_controls();
    $self->control_read_e($ctrl_ref, $pk_col_name);

    my $pk_id = $self->{scrdata}{$pk_col_name};
    if ( ! defined $pk_id ) {
        $self->_view->set_status('Reload failed!','ms','red');
        return;
    }

    $self->screen_write(undef, 'clear'); # clear the controls
    $self->record_load($pk_id);

    $self->_view->set_status("Record reloaded",'ms','blue');

    return;
}

=head2 record_load

Load the selected record in the Screen.

=cut

sub record_load {
    my ($self, $pk_id) = @_;

    #-  Main table

    # Table metadata
    my $maintable   = $self->_scrcfg->maintable;
    my $columns     = $maintable->{columns};
    my $pk_col_name = $maintable->{pkcol}{name};

    # Construct where, add findtype info
    my $params = {};
    $params->{table} = $maintable->{view};   # use view instead of table
    $params->{where}{$pk_col_name} = [ $pk_id, 'allstr' ]; # column = value
    $params->{pkcol} = $pk_col_name;

    my $record = $self->_model->query_record($params);

    $self->screen_write($record);

    #- Dependent table(s), if any

    foreach my $tm_ds ( keys %{ $self->_screen->get_tm_controls() } ) {
        my $tm_params = {};

        # Table metadata
        my $deptable = $self->_scrcfg->deptable->{$tm_ds};
        my $columns  = $deptable->{columns};

        # Construct where, add findtype info
        $tm_params->{table} = $deptable->{view};
        $tm_params->{where}{$pk_col_name} = [ $pk_id, 'allstr' ];
        $tm_params->{fkcol} = $deptable->{fkcol}{name};
        $tm_params->{cols}  = Tpda3::Utils->sort_hash_by_id($columns);

        my $records = $self->_model->query_record_batch($tm_params);

        $self->control_tmatrix_write($records);
    }

    return 1;
}

=head2 ask_to_save

If in I<add> or I<edit> mode show dialog and ask to save or
cancel. Reset modified status.

=cut

sub ask_to_save {
    my $self = shift;

    if (   $self->_model->is_mode('edit')
        or $self->_model->is_mode('add') )
    {
        print "Save record?\n";
        $self->_model->set_modified(q{});       # empty
    }

    return;
}

=head2

Save record.

=cut

sub save_record {
    my $self = shift;

    my $record = $self->get_screen_data_as_record();

    if ( $self->_model->is_mode('add') ) {
        $self->save_record_insert($record);
    }
    elsif ( $self->_model->is_mode('edit') ) {
        $self->save_record_update($record);
    }
    else {
        $self->_view->set_status( 'Not in edit|add mode!', 'ms', 'darkred' );
        return;
    }

    # #- Dependent table(s), if any

    # foreach my $tm_ds ( keys %{ $self->_screen->get_tm_controls() } ) {

    #     # # Table metadata
    #     # my $deptable  = $self->_scrcfg->deptable->{$tm_ds};
    #     # my $columns = $deptable->{columns};

    #     # # Construct where, add findtype info
    #     # my $ctrl_ref = $self->_screen->get_controls();
    #     # $self->control_read_e($ctrl_ref, $pk_col_name);
    #     # my $pk_id = $self->{scrdata}{$pk_col_name};

    #     # my $tm_params = {};
    #     # $tm_params->{where}{$pk_col_name} = [ $pk_id, 'allstr' ];
    #     # $tm_params->{table} = $deptable->{name};
    #     # $tm_params->{pkcol} = { $pk_col_name => $pk_id };

    #     my $tabledata = $self->control_tmatrix_read($tm_ds);

    #     # Delete all articles and reinsert from TM ;)
    #     $self->_model->table_record_delete_batch($tm_params);
    #     $self->_model->table_record_insert_batch($tm_params, $tabledata);
    # }

    # $self->_model->set_modified(q{});        # empty

    return;
}

=head2 save_record_insert

Insert record.

=cut

sub save_record_insert {
    my ($self, $record) = @_;

    # Ask first
    my $answer = $self->_view->{dialog2}->Show();
    if ( $answer !~ /Ok/i ) {
        $self->_view->set_status( 'Canceled', 'ms', 'blue' );
        return;
    }

    my $pk_id = $self->_model->store_record_insert($record);

    if ($pk_id) {
        my $pkcol_name = $record->[0]{metadata}{pkcol};
        $self->screen_write( { $pkcol_name => $pk_id }, 'fields' );
        $self->set_app_mode('edit');
        $self->_view->set_status( 'New record', 'ms', 'darkgreen' );
    }
    else {
        $self->_view->set_status( 'Failed', 'ms', 'darkred' );
        return;
    }

    # TODO: Insert in List

    return;
}

=head2 save_record_update

Update record.

=cut

sub save_record_update {
    my ( $self, $record ) = @_;

    my $pkcol_name = $record->[0]{metadata}{pkcol};
    my $pk_id      = $self->{scrdata}{$pkcol_name};
    if ( !defined $pk_id ) {
        $self->_view->set_status( 'No screen data?', 'ms', 'orange' );
        return;
    }

    # Where: id_column = id_value
    $record->[0]{metadata}{where}{$pkcol_name} = [ $pk_id, 'allstr' ];

    $self->_model->store_record_update($record);

    return;
}

=head2 take_note

Save record to a temporary file on disk.  Can be restored into a new
record.  An easy way of making multiple records based on a template.

=cut

sub take_note {
    my $self = shift;

    my $msg = $self->save_screendata( $self->note_file_name )
            ? 'Note taken'
            : 'Note take failed';

    $self->_view->set_status( $msg, 'ms','blue' );

    return;
}

=head2 restore_note

Restore record from a temporary file on disk into a new record.  An
easy way of making multiple records based on a template.

=cut

sub restore_note {
    my $self = shift;

    my $msg = $self->restore_screendata( $self->note_file_name )
            ? 'Note restored'
            : 'Note restore failed';

    $self->_view->set_status( $msg, 'ms','blue' );

    return;
}

=head2 note_file_name

Note file name defaults to the name of the screen with a I<dat>
extension.

=cut

sub note_file_name {
    my $self = shift;

    # Store record data to file
    my $data_file = catfile(
        $self->_cfg->cfapps,
        $self->_cfg->cfname,
        $self->{_scrstr} . q{.dat},
    );

    return $data_file;
}

=head2 screen_record

Make a record from screen data.

=cut

sub get_screen_data_as_record {
    my ($self, $use_view) = @_;

    if ( !$self->is_record() ) {
        $self->_view->set_status('Empty screen','ms','orange' );
        return;
    }

    my @record;
    my $record = {};

    #-  Main table
    $record->{metadata} =  $self->maintable_metadata();
    while ( my ( $field, $value ) = each( %{$self->{scrdata} } ) ) {
        $record->{data}{$field} = $value;
    }
    push @record, $record;

    # Get PK field name and value
    my $pk_col_name = $record->{metadata}{pkcol};
    my $pk_id = $self->{scrdata}{$pk_col_name};

    #-  Dependent table(s), if any
    my $deprec = {};
    my $tm_dss = $self->_screen->get_tm_controls();
    foreach my $tm_ds ( keys %{$tm_dss} ) {
        $deprec->{$tm_ds}{metadata} =
          $self->deptable_metadata( $tm_ds, $pk_id, $use_view );
        $deprec->{$tm_ds}{data} = $self->control_tmatrix_read($tm_ds);

        # The TMatrix doesn't contain the pkcol => value, add it
        my $pk_ref = { $pk_col_name => $pk_id };
        foreach my $rec ( @{ $deprec->{$tm_ds}{data} } ) {
            @{$rec}{ keys %{$pk_ref} } = values %{$pk_ref};
        }
    }
    push @record, $deprec;

    return \@record;
}

sub maintable_metadata {
    my ($self, $use_view) = @_;

    #-- Table metadata
    my $maintable   = $self->_scrcfg->maintable;
    my $columns     = $maintable->{columns};
    my $pk_col_name = $maintable->{pkcol}{name};

    # Construct where, add findtype info
    my $metadata = {};
    $metadata->{table} = $use_view ? $maintable->{view} : $maintable->{name};
    $metadata->{pkcol} = $pk_col_name;

    return $metadata;
}

sub deptable_metadata {
    my ($self, $tm_ds, $pk_id, $use_view) = @_;

    # Table metadata

    my $maintable   = $self->_scrcfg->maintable;
    my $pk_col_name = $maintable->{pkcol}{name};

    my $deptable = $self->_scrcfg->deptable->{$tm_ds};
    my $columns  = $deptable->{columns};

    # Construct where, add findtype info
    my $tm_metadata = {};
    $tm_metadata->{where}{$pk_col_name} = [ $pk_id, 'allstr' ];
    $tm_metadata->{table} = $use_view ? $deptable->{view} : $deptable->{name};
    $tm_metadata->{updstyle} = $deptable->{updatestyle};
    $tm_metadata->{pkcol}    = $pk_col_name;

    return $tm_metadata;
}

=head2 save_screendata

Save screen data to temp file with Storable.

=cut

sub save_screendata {
    my ($self, $data_file) = @_;

    my $record = $self->screen_record();

    return store( $record, $data_file );
}

=head2 restore_screendata

Restore screen data from file saved with Storable.

=cut

sub restore_screendata {
    my ($self, $data_file) = @_;

    unless ( -f $data_file ) {
        print "$data_file not found!\n";
        return;
    }

    my $rec = retrieve($data_file);
    unless (defined $rec) {
        carp "Unable to retrieve from $data_file!\n";
        return;
    }

    #- Main table

    my $mainrec = $rec->[0];                 # main record is first

    # Dont't want to restore the Id field, remove it
    my $pkcol_name = $mainrec->{metadata}{pkcol};
    delete $mainrec->{data}{ $pkcol_name };

    $self->screen_write( $mainrec->{data}, 'record' );

    #- Dependent table(s), if any

    my $deprec = $rec->[1];                 # dependent records follow

    foreach my $tm_ds ( keys %{ $self->_screen->get_tm_controls() } ) {
        $self->control_tmatrix_write($deprec->{$tm_ds}{data}, $tm_ds);
    }

    return 1;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Tpda3::Tk::Controller
