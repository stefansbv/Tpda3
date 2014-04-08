package Tpda3::Controller;

use strict;
use warnings;
use utf8;

use IPC::System::Simple 1.17 qw(capture);
use Class::Unload;
use File::Basename;
use File::Spec::Functions qw(catfile);
use List::MoreUtils qw(uniq any);
use Log::Log4perl qw(get_logger :levels);
use Math::Symbolic;
use Scalar::Util qw(blessed looks_like_number);
use Storable qw (store retrieve);
use Try::Tiny;
use Data::Compare;
use Locale::TextDomain 1.20 qw(Tpda3);

require Tpda3::Exceptions;
require Tpda3::Utils;
require Tpda3::Config;
require Tpda3::Model;
require Tpda3::Lookup;
require Tpda3::Selected;
require Tpda3::Tk::Dialog::Message;

use Tpda3::Model::Table;

=head1 NAME

Tpda3::Controller - The Controller

=head1 VERSION

Version 0.82

=cut

our $VERSION = 0.82;

=head1 SYNOPSIS

    use Tpda3::Controller;

    my $controller = Tpda3::Controller->new();

    $controller->start();

=head1 METHODS

=head2 new

Constructor method.

=over

=item _rscrcls  - class name of the current I<record> screen

=item _rscrobj  - current I<record> screen object

=item _dscrcls  - class name of the current I<detail> screen

=item _dscrobj  - current I<detail> screen object

=item _tblkeys  - record of database table keys and values

=item _scrdata  - current screen data

=back

=cut

sub new {
    my $class = shift;

    my $model   = Tpda3::Model->new;

    my $self = {
        _model   => $model,
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

    return $self;
}

=head2 start

Show the login dialog, until connected or until a fatal error message
is received from the RDBMS.

=cut

sub start {
    my $self = shift;

    #-  Connect

    $self->{_model}->_print('info#Connecting...');
    $self->{_view}->toggle_status_cn(0);

    # Connect if user and pass or if driver is SQLite
    my $driver = $self->cfg->connection->{driver};
    if (   ( $self->cfg->user and $self->cfg->pass )
        or ( $driver eq 'sqlite' ) )
    {
        $self->model->db_connect();
        return;
    }

    # Retry until connected or canceled
    $self->start_delay()
        unless ( $self->model->is_connected
        or $self->cfg->connection->{driver} eq 'sqlite' );

    return;
}

=head2 connect_dialog

Show login dialog until connected or canceled.  Called with delay from
Tk::Controller.

=cut

sub connect_dialog {
    my $self = shift;

    my $error;

  TRY:
    while ( not $self->model->is_connected ) {

        # Show login dialog if still not connected
        my $return_string = $self->dialog_login($error);
        if ($return_string eq 'cancel') {
            $self->view->set_status( 'Login cancelled', 'ms' );
            last TRY;
        }

        # Try to connect only if user and pass are provided
        if ($self->cfg->user and $self->cfg->pass ) {
            try {
                $self->model->db_connect();
            }
            catch {
                if ( my $e = Exception::Base->catch($_) ) {
                    if ( $e->isa('Exception::Db::Connect') ) {
                        $error = $e->usermsg;
                    }
                }
            };
        }
        else {
            $error = 'error#User and password are required';
        }
    }

    return;
}

=head2 model

Return model instance variable

=cut

sub model {
    my $self = shift;

    return $self->{_model};
}

=head2 view

Return view instance variable

=cut

sub view {
    my $self = shift;

    return $self->{_view};
}

=head2 cfg

Return config instance variable

=cut

sub cfg {
    my $self = shift;

    return $self->{_cfg};
}

sub table_key {
    my ($self, $page, $name) = @_;

    die "Unknown 'page' parameter for 'table_key'"
        unless defined $page
        and ( $page eq 'rec' or $page eq 'det' );

    die "Unknown 'name' parameter for 'table_key'" unless $name;

    return $self->{_tblkeys}{$page}{$name};
}

=head2 _log

Return log instance variable

=cut

sub _log {
    my $self = shift;

    return $self->{_log};
}

=head2 dialog_login

Login dialog.

=cut

sub dialog_login {
    my $self = shift;

    print 'dialog_login not implemented in ', __PACKAGE__, "\n";

    return;
}

=head2 _set_event_handlers

Setup event handlers for the interface.

=cut

sub _set_event_handlers {
    my $self = shift;

    $self->_log->trace('Setup event handlers');

    #- Base menu

    #-- Toggle find mode - Menu
    $self->view->event_handler_for_menu(
        'mn_fm',
        sub {
            return if !defined $self->ask_to_save;

            # From add or sele mode forbid find mode
            $self->toggle_mode_find()
                unless ( $self->model->is_mode('add')
                    or $self->model->is_mode('sele') );
        }
    );

    #-- Toggle execute find - Menu
    $self->view->event_handler_for_menu(
        'mn_fe',
        sub {
            $self->model->is_mode('find')
                ? $self->record_find_execute
                : $self->view->set_status('Not in find mode', 'ms', 'orange' );
        }
    );

    #-- Toggle execute count - Menu
    $self->view->event_handler_for_menu(
        'mn_fc',
        sub {
            $self->model->is_mode('find')
                ? $self->record_find_count
                : $self->view->set_status('Not in find mode', 'ms', 'orange');
        }
    );

    #-- Exit
    $self->view->event_handler_for_menu(
        'mn_qt',
        sub {
            return if !defined $self->ask_to_save;
            $self->on_quit;
        }
    );

    #-- Help
    $self->view->event_handler_for_menu(
        'mn_gd',
        sub {
            $self->guide();
        }
    );

    #-- About
    $self->view->event_handler_for_menu(
        'mn_ab',
        sub {
            $self->about;
        }
    );

    #-- Preview RepMan report
    $self->view->event_handler_for_menu(
        'mn_pr',
        sub { $self->repman; }
    );

    #-- Generate PDF from TT model
    $self->view->event_handler_for_menu(
        'mn_tt',
        sub { $self->ttgen; }
    );

    #-- Edit RepMan report metadata
    $self->view->event_handler_for_menu(
        'mn_er',
        sub {
            $self->screen_module_load('Reports','tools');
        }
    );

    #-- Edit Templates metadata
    $self->view->event_handler_for_menu(
        'mn_et',
        sub {
            $self->screen_module_load('Templates','tools');
        }
    );

    #-- Admin - set default mnemonic
    $self->view->event_handler_for_menu(
        'mn_mn',
        sub {
            $self->set_mnemonic();
        }
    );

    #-- Admin - configure
    $self->view->event_handler_for_menu(
        'mn_cf',
        sub {
            $self->set_app_configs();
        }
    );

    #- Custom application menu from menu.yml

    my $appmenus = $self->view->get_app_menus_list();
    foreach my $item ( @{$appmenus} ) {
        $self->view->event_handler_for_menu(
            $item,
            sub {
                $self->screen_module_load($item);
            }
        );
    }

    #- Toolbar

    #-- Find mode
    $self->view->event_handler_for_tb_button(
        'tb_fm',
        sub {
            $self->toggle_mode_find();
        }
    );

    #-- Find execute
    $self->view->event_handler_for_tb_button(
        'tb_fe',
        sub {
            $self->record_find_execute();
        }
    );

    #-- Find count
    $self->view->event_handler_for_tb_button(
        'tb_fc',
        sub {
            $self->record_find_count();
        }
    );

    #-- Print (preview) default report button
    $self->view->event_handler_for_tb_button(
        'tb_pr',
        sub {
            $self->screen_report_print();
        }
    );

    #-- Generate default document button
    $self->view->event_handler_for_tb_button(
        'tb_gr',
        sub {
            $self->screen_document_generate();
        }
    );

    #-- Take note
    $self->view->event_handler_for_tb_button(
        'tb_tn',
        sub {
            $self->take_note();
        }
    );

    #-- Restore note
    $self->view->event_handler_for_tb_button(
        'tb_tr',
        sub {
            $self->restore_note();
        }
    );

    #-- Reload
    $self->view->event_handler_for_tb_button(
        'tb_rr',
        sub {
            $self->record_reload();
        }
    );

    #-- Add mode; From sele mode forbid add mode
    $self->view->event_handler_for_tb_button(
        'tb_ad',
        sub {
            $self->toggle_mode_add();
        }
    );

    #-- Delete
    $self->view->event_handler_for_tb_button(
        'tb_rm',
        sub {
            $self->event_record_delete();
        }
    );

    #-- Save record
    $self->view->event_handler_for_tb_button(
        'tb_sv',
        sub {
            $self->record_save();
        }
    );

    #-- Attach to desktop - pin (save geometry to config file)
    $self->view->event_handler_for_tb_button(
        'tb_at',
        sub {
            $self->save_geometry();
        }
    );

    #-- Quit
    $self->view->event_handler_for_tb_button(
        'tb_qt',
        sub {
            return if !defined $self->ask_to_save;
            $self->on_quit;
        }
    );

    return;
}

=head2 _set_event_handler_nb

set event handler for the notebook pages.

=cut

sub _set_event_handler_nb {
    my ( $self, $page ) = @_;

    print '_init not implemented in ', __PACKAGE__, "\n";

    return;
}

=head2 toggle_detail_tab

Toggle state of the I<Detail> tab.

If TableMatrix with selector col configured and if there is a selected
row and the data is saved, enable the I<Detail> tab, else disable.

=cut

sub toggle_detail_tab {
    my $self = shift;

    my $sel = $self->tmatrix_get_selected;

    if ( $sel and !$self->model->is_modified ) {
        $self->view->nb_set_page_state( 'det', 'normal');
    }
    else {
        $self->view->nb_set_page_state( 'det', 'disabled');
    }

    return;
}

=head2 on_page_rec_activate

When the C<Record> page is activated, do:

If the previous page is C<List>, then get the selected item from the
C<List> widget and load the corresponding record from the database in
the I<rec> screen, but only if it is not already loaded.

If the previous page is C<Details>, toggle toolbar buttons state for
the current page.

=cut

sub on_page_rec_activate {
    my $self = shift;

    $self->view->set_status( '', 'ms' );    # clear

    if ( $self->model->is_mode('sele') ) {
        $self->set_app_mode('edit');
    }
    else {
        $self->toggle_interface_controls;
    }

    $self->view->nb_set_page_state( 'lst', 'normal');

    return unless $self->view->get_nb_previous_page eq 'lst';

    my $selected_href = $self->view->list_read_selected();
    unless ($selected_href) {
        $self->view->set_status(__ 'Not selected', 'ms', 'orange');
        $self->set_app_mode('idle');

        return;
    }

    #- Compare Key values, load record only if different

    my @current
        = $self->table_key( 'rec', 'main' )->map_keys( sub { $_->value } );
    my @selected = values %{$selected_href};

    my $dc   = Data::Compare->new(\@selected, \@current);
    my $same = $dc->Cmp ? 1 : 0;
    # print "Same? ", $same ? 'YES ' : 'NO ', "\n";

    $self->record_load_new($selected_href) unless $same;

    $self->toggle_detail_tab;

    return;
}

=head2 on_page_lst_activate

On page I<lst> activate.

=cut

sub on_page_lst_activate {
    my $self = shift;

    $self->set_app_mode('sele');

    return;
}

=head2 on_page_det_activate

On page I<det> activate, check if detail screen module is loaded and
load it if not.

=cut

sub on_page_det_activate {
    my $self = shift;

    if ( my $dsm = $self->screen_detail_name ) {
        $self->screen_detail_load($dsm);
    }
    else {
        return $self->view->get_notebook()->raise('rec');
    }

    $self->get_selected_and_store_key;
    $self->record_load();       # load detail record

    $self->view->set_status(__ 'Record loaded (d)', 'ms', 'blue');
    $self->set_app_mode('edit');

    $self->view->nb_set_page_state( 'lst', 'disabled');

    return;
}

=head2 screen_detail_name

Detail screen module name from screen configuration.

=cut

sub screen_detail_name {
    my $self = shift;

    my $screen = $self->scrcfg('rec')->screen('details');

    my $dsm;
    if ( ref $screen->{detail} eq 'ARRAY' ) {
        $dsm = $self->get_dsm_name($screen);
    }
    else {
        $dsm = $screen;
    }

    return $dsm;
}

=head2 get_selected_and_store_key

Read the selected row from I<tm1> TableMatrix widget from the
I<Record> page and get the foreign key value designated by the
I<filter> configuration value of the screen.

Save the foreign key value.

Only one table can have a selector column: I<tm1>.

=cut

sub get_selected_and_store_key {
    my $self = shift;

    my $row = $self->tmatrix_get_selected;

    return unless defined $row and $row > 0;

    # Detail screen module name from config
    my $screen = $self->scrcfg('rec')->screen('details');
    my $tmx    = $self->scrobj('rec')->get_tm_controls('tm1');

    my $rec_params = $self->table_key('rec','main')->get_key(0)->get_href;
    $self->screen_store_key_values($rec_params);
    my $det_params = $tmx->cell_read( $row, $screen->{filter} );
    $self->screen_store_key_values($det_params);

    return;
}

=head2 screen_detail_load

Check if the detail screen module is loaded, and load if it's not.

=cut

sub screen_detail_load {
    my ( $self, $dsm ) = @_;

    my $dscrstr = $self->screen_string('det');

    unless ( $dscrstr && ( $dscrstr eq lc($dsm) ) ) {
        # Loading detail screen ($dsm)
        $self->screen_module_detail_load($dsm);
    }
    return;
}

=head2 get_dsm_name

Find the selected row in the TM. Read it and return the name of the
detail screen module to load.

The configuration is like this:

  {
      'detail' => [
          {
              'value' => 'CS',
              'name'  => 'Cursuri'
          },
          {
              'value' => 'CT',
              'name'  => 'Consult'
          }
      ],
      'filter' => 'id_act',
      'match'  => 'cod_tip'
  };

=cut

sub get_dsm_name {
    my ( $self, $detscr ) = @_;

    my $row = $self->tmatrix_get_selected;

    return unless defined $row and $row > 0;

    my $col_name = $detscr->{match};

    my $tmx = $self->scrobj('rec')->get_tm_controls('tm1');
    my $rec = $tmx->cell_read( $row, $col_name );

    my $col_value = $rec->{$col_name};

    my @dsm = grep { $_->{value} eq $col_value } @{ $detscr->{detail} };

    return $dsm[0]{name};
}

=head2 _set_menus_enable

Disable some menus at start.

=cut

sub _set_menus_enable {
    my ( $self, $state ) = @_;

    foreach my $menu (qw(mn_fm mn_fe mn_fc)) {
        $self->view->set_menu_enable($menu, $state);
    }
}

=head2 _check_app_menus

Check if screen modules from the menu exists and are loadable.
Disable those which fail the test.

Only for I<menu_user> hardwired menu name for now!

=cut

sub _check_app_menus {
    my $self = shift;

    my $appmenus = $self->view->get_app_menus_list();
    foreach my $menu_item ( @{$appmenus} ) {
        my ( $class, $module_file ) = $self->screen_module_class($menu_item);
        try { require $module_file }
        catch {
            $self->view->set_menu_enable($menu_item, 'disabled');
            print "$menu_item screen disabled ($module_file).\n";
            print "Reason: $_" if $self->cfg->verbose;
        }
    }

    return;
}

=head2 setup_lookup_bindings_entry

Creates widget bindings that use the C<Tpda3::XX::Dialog::Search>
module to look-up value key translations from a table and put them in
one or more widgets.

The simplest configuration, with one lookup field and one return
field, looks like this:

 <bindings>
   <customer>
     table               = customers
     search              = customername
     field               = customernumber
   </customer>
 </bindings>

This configuration allows to lookup for a I<customernumber> in the
I<customers> table when knowing the I<customername>.  The
I<customername> and I<customernumber> fields must be defined in the
current table, with properties like width, label and datatype. this are
also the names of the widgets in the screen I<Orders>.  Multiple
I<field> items can be added to the configuration, to return more than
one value, and write its contents to the screen.

When the field names are different than the control names we need to
map the name of the fields with the name of the controls and the
configuration will be a little more complicated.

Here is an example from a I<real> application, with two configs with a
complex field bindings and one with a simple one:

  <bindings>
      <loc_ds>
          table           = siruta
          <search>
              localitate  = loc_ds
          </search>
          <field>
              mnemonic    = jud_ds
              codp        = codp_ds
              siruta      = siruta_ds
          </field>
      </loc_ds>
      <loc_ln>
          table           = siruta
          <search>
              localitate  = loc_ln
          </search>
          <field>
              mnemonic    = jud_ln
              codp        = codp_ln
              siruta      = siruta_ln
          </field>
      </loc_ln>
      <tara>
          table           = tari
          search          = tara
          field           = [ tara_cod ]
      </tara>
  </bindings>

There is another (new) option for a field name from the screen to be
used as a filter.

  filter = field_name

=cut

sub setup_lookup_bindings_entry {
    my ( $self, $page ) = @_;

    my $dict     = Tpda3::Lookup->new;
    my $ctrl_ref = $self->scrobj($page)->get_controls();

    my $bindings = $self->scrcfg($page)->bindings;

    foreach my $bind_name ( keys %{$bindings} ) {
        next unless $bind_name;            # skip if just an empty tag

        # If 'search' is a hashref, get the first key, else the value
        my $search
            = ref $bindings->{$bind_name}{search}
            ? ( keys %{ $bindings->{$bind_name}{search} } )[0]
            : $bindings->{$bind_name}{search};

        # Field name (widget name in the Screen) to bind to
        my $column
            = ref $bindings->{$bind_name}{search}
            ? $bindings->{$bind_name}{search}{$search}
            : $search;

        # Add the search field to the columns list
        my $field_cfg = $self->scrcfg('rec')->maintable('columns', $column);

        my @cols;
        my $rec = {};
        $rec->{$search} = {
            displ_width => $field_cfg->{displ_width},
            label       => $field_cfg->{label},
            datatype    => $field_cfg->{datatype},
            name        => $column, # add a name attribute
        };

        push @cols, $rec;

        # Add filter field if defined in screen config
        my $filter_field
            = exists $bindings->{$bind_name}{filter}
            ? $bindings->{$bind_name}{filter}
            : undef;

        # Compose the parameter for the 'Search' dialog
        my $para = {
            table  => $bindings->{$bind_name}{table},
            search => $search,
            filter => $filter_field,
        };

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

        $self->view->make_binding_entry(
            $ctrl_ref->{$column}[1],
            '<Return>',
            sub {
                my $filter
                    = defined $para->{filter}
                    ? $self->filter_field( $para->{filter} )
                    : undef;
                my $record = $dict->lookup( $self->view, $para, $filter );
                $self->screen_write($record);
            }
        );
    }

    return;
}

=head2 filter_field

Read the (filter) field value from the current screen and return a
hash reference.

=cut

sub filter_field {
    my ($self, $filter_field) = @_;

    return unless $filter_field;

    my $filter_value = $self->ctrl_read_from($filter_field);

    return { $filter_field => $filter_value };
}

=head2 setup_bindings_table

Creates column bindings for table widgets created with
C<Tk::TableMatrix> using the information from the I<tablebindings>
section of the screen configuration.

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
activates the C<Tpda3::XX::Dialog::Search> module, to look-pu value
key translations from a database table and fill the configured cells
with the results.  The second can call a method in the current screen.

=cut

sub setup_bindings_table {
    my $self = shift;

    print 'setup_bindings_table not implemented in ', __PACKAGE__, "\n";

    return;
}

=head2 setup_select_bindings_entry

Setup select bindings entry.

=cut

sub setup_select_bindings_entry {
    my ( $self, $page ) = @_;

    my $dict     = Tpda3::Selected->new;
    my $ctrl_ref = $self->scrobj($page)->get_controls();

    return unless $self->scrcfg($page)->can('bindings_select');

    my $bindings = $self->scrcfg($page)->bindings_select();

    foreach my $bind_name ( keys %{$bindings} ) {
        next unless $bind_name;            # skip if just an empty tag

        # Where to insert the results
        my $tm_ds    = $bindings->{$bind_name}{target_tm};
        my $callback = $bindings->{$bind_name}{callback};
        my $field    = $bindings->{$bind_name}{filter};

        # Compose the parameter for the 'Search' dialog
        my $para = {
            table  => $bindings->{$bind_name}{table},
        };

        # Detect the configuration style and add the 'fields' to the
        # columns list
        my $flds;
      SWITCH: for ( ref $bindings->{$bind_name}{field} ) {
            /array/i && do {
                $flds
                    = $self->fields_cfg_array( $bindings->{$bind_name}, $tm_ds );
                last SWITCH;
            };
            print "WW: Wrong select bindings configuration!\n";
            return;
        }
        push my @cols, @{$flds};

        $para->{columns} = [@cols];    # add columns info to parameters

        $self->view->make_binding_entry(
            $ctrl_ref->{$bind_name}[1],
            '<Return>',
            sub {
                $self->view->status_message("warn#"); # clear message
                my $value = $self->ctrl_read_from($field);
                if ($field and $value) {
                    $para->{where} = { $field => $value };
                    my $records = $dict->selected( $self->view, $para );

                    # Insert into TM
                    my $xtable  = $self->scrobj('rec')->get_tm_controls($tm_ds);
                    $xtable->clear_all();
                    $xtable->fill($records);     # insert records in table

                    # Execute callback
                    if ( $callback
                             and $self->scrobj($page)->can($callback) ) {
                        $self->scrobj($page)->$callback();
                    }
                }
                else {
                    my $textstr
                        = $field
                        ? "No value for '$field' column!"
                        : "No 'filter' column in config!"
                        ;
                    $self->view->status_message("warn#$textstr");
                }
            }
        );
    }

    return;
}

=head2 add_dispatch_for_lookup

Return an entry in the dispatch table for a I<lookup> type binding.

=cut

sub add_dispatch_for_lookup {
    my ( $self, $bnd ) = @_;

    my $bindcol = 'colsub' . $bnd->{bindcol};

    return { $bindcol => \&lookup_call };
}

=head2 add_dispatch_for_method

Return an entry in the dispatch table for a I<method> type binding.

=cut

sub add_dispatch_for_method {
    my ( $self, $bnd ) = @_;

    my $bindcol = 'colsub' . $bnd->{bindcol};

    return { $bindcol => \&method_call };
}

=head2 method_for

This is bound to the Return key, and executes a function as defined in
the configuration, using a dispatch table.

=cut

sub method_for {
    my ( $self, $dispatch, $bindings, $r, $c, $tm_ds ) = @_;

    my $skip_cols;
    my $proc = "colsub$c";
    if ( exists $dispatch->{$proc} ) {
        $skip_cols = $dispatch->{$proc}->( $self, $bindings, $r, $c, $tm_ds );
    }

    return $skip_cols;
}

=head2 lookup_call

Activates the C<Tpda3::XX::Dialog::Search> module, to look-up value
key translations from a database table and fill the configured cells
with the results.

=cut

sub lookup_call {
    my ( $self, $bnd, $r, $c, $tm_ds ) = @_;

    my $tmx = $self->scrobj('rec')->get_tm_controls($tm_ds);

    my $lk_para = $self->get_lookup_setings( $bnd, $r, $c, $tm_ds );

    # Check and set filter
    my $filter;
    if ( $lk_para->{filter} ) {
        my $fld = $lk_para->{filter};
        my $col
            = $self->scrcfg('rec')->deptable( $tm_ds, 'columns', $fld, 'id' );
        $filter = $tmx->cell_read( $r, $col );
    }

    my $dict        = Tpda3::Lookup->new;
    my $record      = $dict->lookup( $self->view, $lk_para, $filter );

    $tmx->write_row( $r, $c, $record, $tm_ds );

    my $skip_cols = scalar @{ $lk_para->{columns} };  # skip ahead cols number

    return $skip_cols;
}

=head2 method_call

Call a method from the Screen module on I<Return> key.

=cut

sub method_call {
    my ( $self, $bnd, $r, $c ) = @_;

    # Filter on bindcol = $c
    my @names = grep { $bnd->{method}{$_}{bindcol} == $c }
        keys %{ $bnd->{method} };
    my $bindings = $bnd->{method}{ $names[0] };

    my $method = $bindings->{subname};       # TODO: rename to method?
    if ( $self->scrobj('rec')->can($method) ) {
        $self->scrobj('rec')->$method($r);
    }
    else {
        print "WW: '$method' not implemented!\n";
    }

    return 1;    # skip_cols
}

=head2 get_lookup_setings

Return the data structure used by the C<Tpda3::XX::Dialog::Search>
module.  Uses the I<tablebindings> section of the screen configuration
and the related field attributes from the I<dep_table> section.

This is a configuration example from the C<Orders> screen:

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

=over

=item I<bindcol> - column number to bind to

=item I<search>  - field name to be searched for a substring

=item I<columns> - columns to be displayed in the list, with attributes

=item I<table>   - name of the look-up table

=back

An example of a returned data structure, for the Orders screen:

 {
    'search'  => 'productname',
    'columns' => [
        {
            'productname' => {
                'width'   => 36,
                'datatype' => 'alphanum',
                'name'    => 'productname',
                'label'   => 'Product',
            }
        },
        {
            'productcode' => {
                'width'   => 15,
                'datatype' => 'alphanum',
                'label'   => 'Code',
            }
        },
    ],
    'table' => 'products',
 }

=cut

sub get_lookup_setings {
    my ( $self, $bnd, $r, $c, $tm_ds ) = @_;

    # Filter on bindcol = $c
    my @names = grep { $bnd->{lookup}{$_}{bindcol} == $c }
        keys %{ $bnd->{lookup} };
    my $bindings = $bnd->{lookup}{ $names[0] };

    # If 'search' is a hashref, get the first key, else the value
    my $search
        = ref $bindings->{search}
        ? ( keys %{ $bindings->{search} } )[0]
        : $bindings->{search};

    # If 'search' is a hashref, get the first keys name attribute
    my $column
        = ref $bindings->{search}
        ? $bindings->{search}{$search}{name}
        : $search;

    # If 'filter'
    my $filter
        = $bindings->{filter}
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
    my $field_cfg = $self->scrcfg('rec')->deptable($tm_ds, 'columns', $column);

    my @cols;
    my $rec = {};
    $rec->{$search} = {
        displ_width => $field_cfg->{displ_width},
        label       => $field_cfg->{label},
        datatype    => $field_cfg->{datatype},
    };
    $rec->{$search}{name} = $column if $column;    # add name attribute

    push @cols, $rec;

    # Detect the configuration style and add the 'fields' to the
    # columns list
    my $flds;
SWITCH: for ( ref $bindings->{field} ) {
        /array/i && do {
            $flds = $self->fields_cfg_array( $bindings, $tm_ds );
            last SWITCH;
        };
        /hash/i && do {
            $flds = $self->fields_cfg_hash( $bindings, $tm_ds );
            last SWITCH;
        };
        print "WW: Wrong bindings configuration!\n";
        return;
    }
    push @cols, @{$flds};

    $lk_para->{columns} = [@cols];    # add columns info to parameters

    return $lk_para;
}

=head2 fields_cfg_array

Multiple return fields.

=cut

sub fields_cfg_array {
    my ( $self, $bindings, $tm_ds ) = @_;

    my @cols;

    # Multiple fields returned as array
    foreach my $lookup_field ( @{ $bindings->{field} } ) {
        my $field_cfg;
        if ($tm_ds) {
            $field_cfg = $self->scrcfg('rec')
                ->deptable( $tm_ds, 'columns', $lookup_field );
        }
        else {
            $field_cfg
                = $self->scrcfg('rec')->maintable( 'columns', $lookup_field );
        }
        my $rec = {};
        $rec->{$lookup_field} = {
            displ_width => $field_cfg->{displ_width},
            label       => $field_cfg->{label},
            datatype    => $field_cfg->{datatype},
        };
        push @cols, $rec;
    }

    return \@cols;
}

=head2 fields_cfg_hash

Multiple return fields and widget name different from field name.

=cut

sub fields_cfg_hash {
    my ( $self, $bindings, $tm_ds ) = @_;

    my @cols;

    # Multiple fields returned as array
    foreach my $lookup_field ( keys %{ $bindings->{field} } ) {
        my $scr_field = $bindings->{field}{$lookup_field};
        my $field_cfg;
        if ($tm_ds) {
            $field_cfg = $self->scrcfg('rec')
                ->deptable( $tm_ds, 'columns', $scr_field );
        }
        else {
            $field_cfg
                = $self->scrcfg('rec')->maintable( 'columns', $scr_field );
        }

        my $rec = {};
        $rec->{$lookup_field} = {
            displ_width => $field_cfg->{displ_width},
            label       => $field_cfg->{label},
            datatype    => $field_cfg->{datatype},
            name        => $scr_field,
        };
        push @cols, $rec;
    }

    return \@cols;
}

=head2 set_app_mode

Set application mode to $mode.

=cut

sub set_app_mode {
    my ( $self, $mode ) = @_;

    $self->model->set_mode($mode);

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

Return true if a record is loaded in the main screen.

=cut

sub is_record {
    my $self  = shift;
    my $table = $self->table_key( 'rec', 'main' );
    return if !$table or !$table->isa('Tpda3::Model::Table');
    return $table->get_key(0)->value;
}

=head2 on_screen_mode_idle

when in I<idle> mode set status to I<normal> and clear all controls
content in the I<Screen> than set status of controls to I<disabled>.

=cut

sub on_screen_mode_idle {
    my $self = shift;

    # Empty the main controls and TM, if any

    $self->record_clear;

    foreach my $tm_ds ( keys %{ $self->scrobj('rec')->get_tm_controls() } ) {
        $self->scrobj('rec')->get_tm_controls($tm_ds)->clear_all();
    }

    $self->controls_state_set('off');

    $self->view->nb_set_page_state( 'det', 'disabled');
    $self->view->nb_set_page_state( 'lst', 'normal');

    # Trigger 'on_mode_idle' method in screen if defined
    my $page = $self->view->get_nb_current_page();
    $self->scrobj($page)->on_mode_idle()
        if ( $page eq 'rec' or $page eq 'det' )
        and $self->scrobj($page)->can('on_mode_idle');

    return;
}

=head2 on_screen_mode_add

When in I<add> mode set status to I<normal> and clear all controls
content in the I<Screen> and change the background to the default
color as specified in the configuration.

Create an empty record and write it to the controls. If default values
are defined for some fields, then fill in that value.

=cut

sub on_screen_mode_add {
    my $self = shift;

    $self->record_clear;              # empty the main controls and TM
    $self->tmatrix_set_selected();    # initialize selector

    foreach my $tm_ds ( keys %{ $self->scrobj('rec')->get_tm_controls() } ) {
        $self->scrobj('rec')->get_tm_controls($tm_ds)->clear_all();
    }

    $self->controls_state_set('edit');

    $self->view->nb_set_page_state( 'det', 'disabled' );
    $self->view->nb_set_page_state( 'lst', 'disabled' );

    # Default value for user in screen.  Add 'id_user' value if
    # 'id_user' control exists in screen
    my $user_field = 'id_user';              # hardwired user field name
    my $control_ref = $self->scrobj()->get_controls($user_field);
    $self->ctrl_write_to( $user_field, $self->cfg->user ) if $control_ref;

    # Trigger 'on_mode_add' method in screen if defined
    my $page = $self->view->get_nb_current_page();
    $self->scrobj($page)->on_mode_add()
        if ( $page eq 'rec' or $page eq 'det' )
        and $self->scrobj($page)->can('on_mode_add');

    return;
}

=head2 on_screen_mode_find

When in I<find> mode set status to I<normal> and clear all controls
content in the I<Screen> and change the background to light green.

=cut

sub on_screen_mode_find {
    my $self = shift;

    # Empty the main controls and TM, if any

    $self->record_clear;

    foreach my $tm_ds ( keys %{ $self->scrobj('rec')->get_tm_controls() } ) {
        $self->scrobj('rec')->get_tm_controls($tm_ds)->clear_all();
    }

    $self->controls_state_set('find');

    # Trigger 'on_mode_find' method in screen if defined
    my $page = $self->view->get_nb_current_page();
    $self->scrobj($page)->on_mode_find()
        if ( $page eq 'rec' or $page eq 'det' )
        and $self->scrobj($page)->can('on_mode_find');

    return;
}

=head2 on_screen_mode_edit

When in I<edit> mode set status to I<normal> and change the background
to the default color as specified in the configuration.

=cut

sub on_screen_mode_edit {
    my $self = shift;

    $self->controls_state_set('edit');
    $self->view->nb_set_page_state( 'det', 'normal');
    $self->view->nb_set_page_state( 'lst', 'normal');

    # Trigger 'on_mode_edit' method in screen if defined
    my $page = $self->view->get_nb_current_page();
    $self->scrobj($page)->on_mode_edit()
        if ( $page eq 'rec' or $page eq 'det' )
        and $self->scrobj($page)->can('on_mode_edit');

    return;
}

=head2 on_screen_mode_sele

Noting to do here.

=cut

sub on_screen_mode_sele {
    my $self = shift;

    my $nb = $self->view->get_notebook();
    $self->view->nb_set_page_state( 'det', 'disabled');

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

=head2 scrcfg

Return screen configuration object for I<page>, or for the current
page.

=cut

sub scrcfg {
    my ( $self, $page ) = @_;

    $page ||= $self->view->get_nb_current_page();

    return unless $page;

    if ( $page eq 'lst' ) {
        die "Wrong page (scrcfg): $page!";
    }

    my $scrobj = $self->scrobj($page);

    if ( $scrobj and ( exists $scrobj->{scrcfg} ) ) {
        return $scrobj->{scrcfg};
    }

    return;
}

=head2 scrobj

Return current screen object reference, or the object reference from
the required page unless the current page is L<lst>.

=cut

sub scrobj {
    my ( $self, $page ) = @_;

    $page ||= $self->view->get_nb_current_page();

    return if $page eq 'lst';

    return $self->{_rscrobj}
        if ( $page eq 'rec' )
        and ( exists $self->{_rscrobj} );

    return $self->{_dscrobj}
        if ( $page eq 'det' )
        and ( exists $self->{_dscrobj} );

    if ($page eq 'det') {
        warn "Wrong page (scrobj): $page!\n";
    }
    else {
        die 'No screen object!';
    }

    return;
}

=head2 application_class

Main application class name.

=cut

sub application_class {
    my $self = shift;

    print 'application_class not implemented in ', __PACKAGE__, "\n";

    return;
}

=head2 screen_module_class

Return screen module class and file name.

=cut

sub screen_module_class {
    my ( $self, $module, $from_tools ) = @_;

    print 'screen_module_class not implemented in ', __PACKAGE__, "\n";

    return;
}

=head2 screen_module_load

Load screen chosen from the menu.

=cut

sub screen_module_load {
    my ( $self, $module, $from_tools ) = @_;

    #print "Loading $module\n";

    my $rscrstr = lc $module;

    # Destroy existing NoteBook widget
    $self->view->destroy_notebook();

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

    # reload toolbar - if? altered by prev screen
    $self->cfg->toolbar_interface_reload();

    # Make new NoteBook widget and setup callback
    $self->view->create_notebook();
    $self->_set_event_handler_nb('rec');
    $self->_set_event_handler_nb('lst');

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

    return unless $self->check_cfg_version;  # current version is 5

    # Details page
    my $has_det = $self->scrcfg('rec')->has_screen_details();
    if ($has_det) {
        my $lbl_details = __ 'Details';
        $self->view->create_notebook_panel( 'det', $lbl_details );
        $self->_set_event_handler_nb('det');
    }

    # Show screen
    my $nb = $self->view->get_notebook();
    $self->{_rscrobj}->run_screen($nb);

    # Store currently loaded screen class
    $self->{_rscrcls} = $class;

    # Load instance config
    $self->cfg->config_load_instance();

    #-- Lookup bindings for Entry widgets
    $self->setup_lookup_bindings_entry('rec');
    $self->setup_select_bindings_entry('rec');

    #-- Lookup bindings for tables (TableMatrix)
    $self->setup_bindings_table();

    # Set Key column names
    $self->{_tblkeys}{rec} = undef; # reset
    $self->screen_init_keys( 'rec', $self->scrcfg('rec') );

    $self->set_app_mode('idle');

    # List header
    my $header_look = $self->scrcfg('rec')->list_header('lookup');
    my $header_cols = $self->scrcfg('rec')->list_header('column');
    my $fields      = $self->scrcfg('rec')->maintable('columns');

    if ($header_look and $header_cols) {
        $self->view->make_list_header( $header_look, $header_cols, $fields );
    }
    else {
        $self->view->nb_set_page_state( 'lst', 'disabled' );
    }

    #- Event handlers

    my $group_labels = $self->scrcfg()->scr_toolbar_groups();
    foreach my $label ( @{$group_labels} ) {
        $self->set_event_handler_screen($label);
    }

    # Toggle find mode menus
    my $menus_state
        = $self->scrcfg()->screen('style') eq 'report'
        ? 'disabled'
        : 'normal';
    $self->_set_menus_enable($menus_state);

    $self->view->set_status( '', 'ms' );

    $self->model->unset_scrdata_rec();

    # Change application title
    my $descr = $self->scrcfg('rec')->screen('description');
    $self->view->title(' Tpda3 - ' . $descr) if $descr;

    # Update window geometry
    $self->set_geometry();

    # Load lists into ComboBox type widgets
    $self->screen_load_lists();

    return 1;                       # to make ok from Test::More happy
}


=head2 screen_init_keys

Initialize key column names for the current screen.  The format of the
configuration section has changed starting with v0.70.
  <maintable>
      name                = customers
      view                = v_customers
      <keys>
          name            = [ customernumber ]
      </keys>
  ...
  </maintable>

=cut

sub screen_init_keys {
    my ($self, $page, $scrcfg) = @_;

    #-- Main table on the '$page' page

    my $keys_m = $self->scrcfg->maintable( 'keys', 'name' );

    die
        "Configuration error!\nThe key fields configuration was changed in Tpda3 v0.70.\nSorry for the inconvenience.\n"
        unless defined $keys_m and ref($keys_m) eq 'ARRAY';

    my $table  = Tpda3::Model::Table->new(
        keys   => $keys_m,
        table  => $self->scrcfg->maintable('name'),
        view   => $self->scrcfg->maintable('view'),
    );
    if (ref $table) {
        # Register main table object on $page page
        $self->{_tblkeys}{$page}{main} = $table;
    }

    #-- Dependent tables (TableMatrix)

    my @tms = keys %{ $self->scrcfg->deptable };
    foreach my $tm (@tms) {
        my $keys_d = $self->scrcfg->deptable( $tm, 'keys', 'name' );
        my $table = Tpda3::Model::Table->new(
            keys   => $keys_d,
            table  => $self->scrcfg->deptable( $tm, 'name' ),
            view   => $self->scrcfg->deptable( $tm, 'view' ),
        );

        if (ref $table) {
            # Register dep '$tm' table object on $page page
            $self->{_tblkeys}{$page}{$tm} = $table;
        }
    }

    return;
}

=head2 check_cfg_version

Return undef if screen config version doesn't check.

=cut

sub check_cfg_version {
    my $self = shift;

    my $cfg = $self->scrcfg()->screen;

    my $req_ver = 5;            # current screen config version
    my $cfg_ver = ( exists $cfg->{version} ) ? $cfg->{version} : 1;

    unless ( $cfg_ver == $req_ver ) {
        my $screen_name = $self->scrcfg->screen('name');
        my $msg = "Screen configuration ($screen_name.conf) error!\n\n";
          $msg .= "The screen configuration file version is '$cfg_ver' ";
          $msg .= "but the required version is '$req_ver'\n\n";
          $msg .= "Hint: Upgrade Tpda3 to a newer version.\n" if
              $cfg_ver > $req_ver;
        Exception::Config::Version->throw(
            usermsg => $msg,
            logmsg  => "Config version error for '$screen_name.conf'\n",
        );
        if ( $self->{_rscrcls} ) {
            Class::Unload->unload( $self->{_rscrcls} );
            if ( Class::Inspector->loaded( $self->{_rscrcls} ) ) {
                $self->_log->info("Error unloading '$self->{_rscrcls}' screen");
            }
        }
        return;
    }
    else {
        return 1;
    }
}

=head2 set_event_handler_screen

Setup event handlers for the toolbar buttons configured in the
C<scrtoolbar> section of the current screen configuration.

Default usage is for the I<add> and I<delete> buttons attached to the
TableMatrix widget.

=cut

sub set_event_handler_screen {
    print 'set_event_handler_screen not implemented in ', __PACKAGE__, "\n";
}

=head2 screen_module_detail_load

Load detail screen.

=cut

sub screen_module_detail_load {
    my ( $self, $module ) = @_;

    my $dscrstr = lc $module;

    $self->view->notebook_page_clean('det');

    # Unload current screen
    if ( $self->{_dscrcls} ) {
        Class::Unload->unload( $self->{_dscrcls} );
        if ( Class::Inspector->loaded( $self->{_dscrcls} ) ) {
            $self->_log->error("Failed unloading '$self->{_dscrcls}' dscreen");
        }
    }

    $self->_set_event_handler_nb('det');

    my ( $class, $module_file ) = $self->screen_module_class($module);
    eval { require $module_file };
    if ($@) {
        die "EE: Can't load '$module_file'";
    }

    unless ( $class->can('run_screen') ) {
        my $msg = "Error! Screen '$class' can not 'run_screen'";
        print "$msg\n";
        $self->_log->error($msg);

        return;
    }

    # New screen instance
    $self->{_dscrobj} = $class->new($dscrstr);
    $self->_log->trace("New screen instance: $module");

    # Show screen
    my $nb = $self->view->get_notebook();
    $self->{_dscrobj}->run_screen( $nb, $self->{_dscrcfg} );

    # Store currently loaded screen class
    $self->{_dscrcls} = $class;

    # Event handlers

    #-- Lookup bindings for Entry widgets
    $self->setup_lookup_bindings_entry('det');

    #-- Lookup bindings for tables (TableMatrix)
    $self->setup_bindings_table();

    # Load lists into ComboBox like widgets
    $self->screen_load_lists();

    $self->view->set_status( '', 'ms' );

    # Set Key column names
    $self->{_tblkeys}{det} = undef; # reset
    $self->screen_init_keys( 'det', $self->scrcfg('det') );

    return;
}

=head2 screen_string

Return a lower case string of the current screen module name.

=cut

sub screen_string {
    my ( $self, $page ) = @_;

    $page ||= $self->view->get_nb_current_page();

    my $module;
    if ( $page eq 'rec' ) {
        $module = $self->{_rscrcls};
    }
    elsif ( $page eq 'det' ) {
        $module = $self->{_dscrcls} || q{};    # empty
    }
    else {
        print "WW: screen_string called with page '$page'\n";
        return;
    }

    my $scrstr = ( split /::/, $module )[-1] || q{};    # or nothing

    return lc $scrstr;
}

=head2 save_geometry

Save geometry in instance configuration file.

=cut

sub save_geometry {
    my $self = shift;

    my $scr_name = $self->scrcfg()
        ? $self->scrcfg()->screen('name')
        : 'main';

    $self->cfg->config_save_instance(
        $scr_name,
        $self->view->get_geometry()
    );

    return;
}

=head2 set_mnemonic

Dialog to set the default mnemonic - application configuration to be
used when none is specified.

=cut

sub set_mnemonic {
    my $self = shift;

    print 'set_mnemonic not implemented in ', __PACKAGE__, "\n";

    return;
}

=head2 set_geometry

Set window geometry from instance config if exists or from defaults.

=cut

sub set_geometry {
    my $self = shift;

    my $scr_name
        = $self->scrcfg()
        ? $self->scrcfg()->screen('name')
        : return;

    my $geom;
    if ( $self->cfg->can('geometry') ) {
        my $go = $self->cfg->geometry();
        if (exists $go->{$scr_name}) {
            $geom = $go->{$scr_name};
        }
    }
    unless ($geom) {
        $geom = $self->scrcfg('rec')->screen('geometry');
    }

    $self->view->set_geometry($geom);

    return;
}

=head2 set_app_configs

Dialog to set runtime configurations for Tpda3.

=cut

sub set_app_configs {
    my $self = shift;

    print 'set_app_configs not implemented in ', __PACKAGE__, "\n";

    return;
}

=head2 screen_load_lists

Load options in Listbox like widgets - JCombobox support only.

All JComboBox widgets must have a <lists_ds> record in config to
define where the data for the list come from:

Data source for list widgets (JCombobox)

 <lists_ds>
     <statuscode>
         orderby = description
         table   = status
         code    = code
         name    = description
         default = none
     </statuscode>
 </lists_ds>

=cut

sub screen_load_lists {
    my $self = shift;

    # Entry objects hash
    my $ctrl_ref = $self->scrobj()->get_controls();

    return unless scalar keys %{$ctrl_ref};

    foreach my $field ( keys %{ $self->scrcfg()->maintable('columns') } ) {

        # Control config attributes
        my $fld_cfg  = $self->scrcfg()->maintable('columns', $field);
        my $ctrltype = $fld_cfg->{ctrltype};
        my $ctrlrw   = $fld_cfg->{readwrite};

        my $para = $self->scrcfg()->lists_ds($field);

        next unless ref $para eq 'HASH';       # undefined, skip

        # Query table and return data to fill the lists

        my $choices = $self->model->get_codes( $field, $para, $ctrltype );

        if ( $ctrltype eq 'm' ) {
            if ( $ctrl_ref->{$field}[1] ) {
                my $control = $ctrl_ref->{$field}[1];
                $self->view->list_control_choices($control, $choices);
            }
            else {
                print "EE: config error for '$field'\n";
            }
        }
        else {
            print "EE: No '$ctrltype' ctrl type for writing '$field'!\n";
        }
    }

    return;
}

=head2 toggle_interface_controls

Toggle controls (tool bar buttons) appropriate for different states of
the application, and different pages.

=cut

sub toggle_interface_controls {
    my $self = shift;

    my ( $toolbars, $attribs ) = $self->view->toolbar_names();

    my $mode = $self->model->get_appmode;
    my $page = $self->view->get_nb_current_page();

    my $is_rec = $self->is_record();

    foreach my $name ( @{$toolbars} ) {
        my $status = $attribs->{$name}{state}{$page}{$mode};

        #- Corrections

        unless ( ( $page eq 'lst' ) and $self->{_rscrcls} ) {
            next unless $status;

            #-- Restore note

            if ( ( $name eq 'tb_tr' ) and ( $status eq 'normal' ) ) {
                my $data_file = $self->storable_file_name;
                $status = 'disabled' if !-f $data_file;
            }

            #-- Print preview.

            # Activate only if default report configured for screen
            if ( ( $name eq 'tb_pr' ) and ( $status eq 'normal' ) ) {
                $status = 'disabled' if
                    !$self->scrcfg('rec')->defaultreport('file');
            }

            #-- Generate document

            # Activate only if default document template configured
            # for screen
            if ( ( $name eq 'tb_gr' ) and ( $status eq 'normal' ) ) {
                $status = 'disabled' if
                    !$self->scrcfg('rec')->defaultdocument('file');
            }
        }
        else {
            #-- List tab

            $status = 'disabled';
        }

        #- Set status for toolbar buttons

        $self->view->enable_tool( $name, $status );
    }

    return;
}

=head2 toggle_screen_interface_controls

Toggle screen controls (toolbar buttons) appropriate for different
states of the application.

Also used by the toolbar buttons near the TableMatrix widget in some
screens.

=cut

sub toggle_screen_interface_controls {
    my $self = shift;

    my $page = $self->view->get_nb_current_page();
    my $mode = $self->model->get_appmode;

    return if $page eq 'lst';

    #- Toolbar (table)

    my $group_labels = $self->scrcfg()->scr_toolbar_groups();
    foreach my $label ( @{$group_labels} ) {
        my ( $toolbars, $tb_attrs ) = $self->scrobj()->app_toolbar_names($label);
        foreach my $button_name ( @{$toolbars} ) {
            my $status
                = $self->scrcfg()->screen('style') eq 'report'
                ? 'normal'
                : $tb_attrs->{$button_name}{state}{$page}{$mode};
            $self->scrobj($page)->enable_tool( $label, $button_name, $status );
        }
    }

    return;
}

=head2 record_find_execute

Execute search.

In the screen configuration file, there is an attribute named
I<findtype>, defined for every field of the table associated with the
screen and used to control the behavior of count and search.

All controls from the screen with I<findtype> configured other than
I<none>, are read. The values are used to create a perl data structure
used by the SQL::Abstract module to build an SQL WHERE clause.

The accepted values for I<findtype> are:

=over

=item contains - Translated to LIKE | CONTAINING I<%searchstring%>

=item full     - field = I<searchstring>

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

    my $params = {};

    # Columns data (from list header)
    $params->{columns} = $self->list_column_names();

    # Table configs
    my $columns = $self->scrcfg('rec')->maintable('columns');

    # Add findtype info to screen data
    foreach my $field ( keys %{ $self->{_scrdata} } ) {
        my $value = $self->{_scrdata}{$field};
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
    $params->{table} = $self->table_key('rec','main')->view;
    $params->{pkcol} = $self->table_key('rec','main')->get_key(0)->name;

    my ($ary_ref, $limit);
    try {
        ($ary_ref, $limit) = $self->model->query_records_find($params);
    }
    catch {
        $self->catch_db_exceptions($_);
    };

    # return unless defined $ary_ref->[0];     # test if AoA ?
    unless (ref $ary_ref eq 'ARRAY') {
        # die "Find failed!";
        return;
    }

    my $record_count = scalar @{$ary_ref};
    my $msg1 = __n 'record', 'records', $record_count;
    my $msg0 = $record_count == $limit
             ? __ 'first'
             : q{};

    my $message = __x(
        "{pre} {count} {post}",
        pre   => $msg0,
        count => $record_count,
        post  => $msg1
    );
    $self->view->set_status($message, 'ms', 'darkgreen');

    $self->view->list_init();
    my $record_inlist = $self->view->list_populate($ary_ref);
    $self->view->list_raise() if $record_inlist > 0;

    # Double check
    if ($record_inlist != $record_count) {
        die "Record count error?!";
    }

    # Set mode to sele if found
    $self->set_app_mode('sele') if $record_inlist > 0;

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
    my $columns = $self->scrcfg('rec')->maintable('columns');

    my $params = {};

    # Add findtype info to screen data
    foreach my $field ( keys %{ $self->{_scrdata} } ) {
        my $value = $self->{_scrdata}{$field};
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
    $params->{table} = $self->table_key('rec','main')->view;
    $params->{pkcol} = $self->table_key('rec','main')->get_key(0)->name;

    my $record_count;
    try {
        $record_count = $self->model->query_records_count($params);
    }
    catch {
        $self->catch_db_exceptions($_);
    };

    my $msg = __ 'records';
    $self->view->set_status( "$record_count $msg", 'ms', 'darkgreen' );

    return;
}

=head2 screen_report_print

Printing report configured as default with Report Manager.

=cut

sub screen_report_print {
    my $self = shift;

    return unless ref $self->scrobj('rec');

    my $pk_col = $self->table_key('rec','main')->get_key(0)->name;
    my $pk_val = $self->table_key('rec','main')->get_key(0)->value;

    my $param;
    if ($pk_val) {
        $param = "$pk_col=$pk_val";          # default parameter ID
    } else {
        # Atentie
        my $textstr = __ "Load a record, first";
        $self->view->status_message("error#$textstr");
        return;
    }

    my $report_exe  = $self->cfg->cfextapps->{repman}{exe_path};
    my $report_name = $self->scrcfg('rec')->defaultreport('file');
    my $report_file = $self->cfg->resource_path_for($report_name, 'rep');

    # Metaviewxp
    my @opts  = qq{-preview};
    my $cmd = qq{"$report_exe"};
    if ( defined $param ) {
        push @opts, qq{-param$param};
        push @opts, qq{"$report_file"};
    }
    else {
        $self->_log->debug("No parameters for RepMan");
        die "No parameters for RepMan\n",
    }

    my $output = q{};
    try {
        $output = capture("$cmd @opts");
    }
    catch {
        Exception::IO::SystemCmd->throw(
            usermsg => 'Error from RepMan',
            logmsg  => $output,
        );
    };

    return;
}

=head2 screen_document_generate

Generate default document assigned to screen.

=cut

sub screen_document_generate {
    my $self = shift;

    return unless ref $self->scrobj('rec');

    my $record;

    my $datasource = $self->scrcfg()->defaultdocument('datasource');
    if ($datasource) {
        $record = $self->get_alternate_data_record($datasource);
    }
    else {
        $record = $self->get_screen_data_record('qry', 'all');
    }

    my $fields_no = scalar keys %{ $record->[0]{data} };
    if ( $fields_no <= 0 ) {
        $self->view->set_status(__ 'Empty record', 'ms', 'red');
        $self->_log->error('Generator: no data!');
    }

    my $model_name = $self->scrcfg()->defaultdocument('file');
    my $model_file = $self->cfg->resource_path_for($model_name, 'tex', 'model');

    unless ( -f $model_file ) {
        $self->view->set_status(__ 'Report failed!', 'ms', 'red' );
        $self->_log->error('Generator: Template not found');
        return;
    }

    my $out_path = $self->cfg->resource_path_for(undef, 'tex', 'output');
    unless ( -d $out_path ) {
        $self->view->set_status(__ 'Output path not found', 'ms', 'red' );
        $self->_log->error('Generator: Output path not found');
        return;
    }

    # Data from other sources
    my $other_data = $self->model->other_data($model_name);

    $record = $record->[0]{data};            # only the data
    my $rec = Hash::Merge->new->merge(
        $record,
        $other_data,
    );

    # Avoid UTF-8 problems in TeX
    foreach my $key ( keys %{$rec} ) {
        $rec->{$key} = Tpda3::Utils->decode_unless_utf( $rec->{$key} );
    }

    $self->view->generate_doc( $model_file, $rec);

    return;
}

=head2 get_alternate_data_record

Datasource from configuration for default document assigned to screen.

=cut

sub get_alternate_data_record {
    my ( $self, $datasource ) = @_;

    #-- Metadata

    my $record = {};
    $record->{metadata} = $self->main_table_metadata('qry');
    $record->{data}     = {};
    $record->{metadata}{table} = $datasource;      # change datasource

    #-- Data

    try {
        $record->{data} = $self->model->query_record( $record->{metadata} );
    }
    catch {
        $self->catch_db_exceptions($_);
    };

    my @rec;
    push @rec, $record;    # rec data at index 0

    return \@rec;
}

=head2 screen_read

Read screen controls (widgets) and save in a Perl data structure.

Creates different data for different application modes.

=over

=item I<Find> mode

Read the fields that have the configured I<readwrite> attribute set to
I<rw> and I<ro> ignoring the fields with I<r>, but also ignoring the
fields with no values.

=item I<Edit> mode

Read the fields that have the configured I<readwrite> attribute set to
I<rw>, ignoring the rest (I<r> and I<ro>), but including the fields
with no values as I<undef> for the value.

=item I<Add>  mode

Read the fields that have the configured I<readwrite> attribute set to
I<rw>, ignoring the rest (I<r> and I<ro>), but also ignoring the
fields with no values.

=back

Option to read all fields regardless of the configured I<readwrite>
attribute.

=cut

sub screen_read {
    my ($self, $all) = @_;

    # Initialize
    $self->{_scrdata} = {};

    my $scrobj = $self->scrobj;    # current screen object
    my $scrcfg = $self->scrcfg;    # current screen config

    my $ctrl_ref = $scrobj->get_controls();

    return unless scalar keys %{$ctrl_ref};

    # Get configured date style, default is ISO
    my $date_format = $self->cfg->application->{dateformat} || 'iso';

    foreach my $field ( keys %{ $scrcfg->maintable('columns') } ) {
        my $fld_cfg = $scrcfg->maintable('columns', $field);

        # Control config attributes
        my $ctrltype = $fld_cfg->{ctrltype};
        my $ctrlrw   = $fld_cfg->{readwrite};

        if ( !$all ) {
            unless ( $self->model->is_mode('find') ) {
                next if ( $ctrlrw eq 'r' ) or ( $ctrlrw eq 'ro' );
            }
        }

        $self->ctrl_read_from($field, $date_format);
    }

    return;
}

=head2 ctrl_read_from

Run the appropriate method according to the control (widget) type to
read from the screen controls. The value is stored in a global data
structure C<< $self->{_scrdata}{field-name} >> and also returned.

=cut

sub ctrl_read_from {
    my ($self, $field, $date_format) = @_;

    my $ctrltype = $self->scrcfg()->maintable('columns', $field, 'ctrltype');

    my $value;
    my $sub_name = "control_read_$ctrltype";
    if ( $self->view->can($sub_name) ) {
        my $control_ref = $self->scrobj()->get_controls($field);
        $value = $self->view->$sub_name($field, $control_ref, $date_format );
        $self->clean_and_save_value( $field, $value, $ctrltype );
    }
    else {
        print "EE: No '$ctrltype' ctrl type for reading '$field'!\n";
    }

    return $value;
}

=head2 clean_and_save_value

Trim value and add it to the C<_scrdata> global data structure.

=over

=item find mode

Add to the data structure the values that Perl recognise as true
values.  Add value 0 when read from an Entry controll, but ignore it
when read from a CheckBox control.  This allows searching for C<0> in
numeric fields.

=item add mode

Add to the data structure the values that Perl recognise as true
values.  Add value 0 when read from an Entry controll, or from a
CheckBox control.

=item edit mode

When in C<edit> mode Tpda3 builds the SQL UPDATE from all the controls,
because some of them may be empty, interpreted as a new NULL value.

=back

=cut

sub clean_and_save_value {
    my ($self, $field, $value, $ctrltype) = @_;

    $value = Tpda3::Utils->trim($value) if defined $value;

    # Find mode
    if ( $self->model->is_mode('find') ) {
        if ($value) {
            $self->{_scrdata}{$field} = $value;
        }
        else {
            if ($ctrltype eq 'e') {
                # Can't use numeric eq (==) here
                if (defined($value) and ( $value =~ m{^0+$} ) ) {
                    $self->{_scrdata}{$field} = $value;
                }
            }
        }
    }
    # Add mode, non empty fields, 0 is allowed
    elsif ( $self->model->is_mode('add') ) {
        if ( defined($value) and ( $value =~ m{\S+} ) ) {
            $self->{_scrdata}{$field} = $value;
        }
    }
    # Edit mode, non empty fields, 0 is allowed
    elsif ( $self->model->is_mode('edit') ) {
        if ( defined($value) and ( $value =~ m{\S+} ) ) {
            $self->{_scrdata}{$field} = $value;
        }
        else {
            $self->{_scrdata}{$field} = undef;
        }
    }
    else {
        # Idle mode -> empty record
        $self->{_scrdata}{$field} = undef;
    }

    return;
}

=head2 screen_write

Write record to screen.  The parameter is a hash reference with the
field names as keys.  I<undef> value clears the control.

=cut

sub screen_write {
    my ( $self, $record ) = @_;

    #- Use current page
    my $page = $self->view->get_nb_current_page();

    return if $page eq 'lst';

    my $ctrl_ref = $self->scrobj($page)->get_controls();
    return unless scalar keys %{$ctrl_ref};    # no controls?

    my $cfg_ref = $self->scrcfg($page);

    # Get configured date style, default is ISO
    my $date_format = $self->cfg->application->{dateformat} || 'iso';

    # my $cfgdeps = $self->scrcfg($page)->dependencies;

    foreach my $field ( keys %{ $cfg_ref->maintable('columns') } ) {

        # Skip field if not in record or not dependent
        next
            unless ( exists $record->{$field}
                         # or $self->is_dependent( $field, $cfgdeps )
                 );

        my $fldcfg = $cfg_ref->maintable('columns', $field);

        my $value = $record->{$field};
        # Defaults in columns config?
        # || ( $self->model->is_mode('add') ? $fldcfg->{default} : undef );

        # # Process dependencies
        my $state;
        # if (exists $cfgdeps->{$field} ) {
        #     $state = $self->dependencies($field, $cfgdeps, $record);
        # }

        if (defined $value) {
            $value = Tpda3::Utils->decode_unless_utf($value);

            # Trim spaces and '\n' from the end
            $value = Tpda3::Utils->trim($value) if $value;

            # Number
            if (   ( $fldcfg->{datatype} eq 'numeric' )
                or ( $fldcfg->{datatype} eq 'integer' ) )
            {
                $value = $self->format_number( $value, $fldcfg->{numscale} );
            }
        }

        $self->ctrl_write_to($field, $value, $state, $date_format);
    }

    return;
}

=head2 ctrl_write_to

Run the appropriate sub according to control (entry widget) type to
write to screen controls.

TODO: Use hash for paramaters

=cut

sub ctrl_write_to {
    my ($self, $field, $value, $state, $date_format) = @_;

    my $ctrltype = $self->scrcfg()->maintable('columns', $field, 'ctrltype');

    my $sub_name = qq{control_write_$ctrltype};
    if ( $self->view->can($sub_name) ) {
        my $control_ref = $self->scrobj()->get_controls($field);
        $self->view->$sub_name( $field, $control_ref, $value, $state,
            $date_format );
    }
    else {
        warn "WW: No '$ctrltype' ctrl type for writing '$field'!";
    }

    return;
}

=head2 make_empty_record

Make empty record, used for clearing the screen.

=cut

sub make_empty_record {
    my $self = shift;

    my $page    = $self->view->get_nb_current_page();
    my $cfg_ref = $self->scrcfg($page);

    my $record = {};
    foreach my $field ( keys %{ $cfg_ref->maintable('columns') } ) {
        $record->{$field} = undef;
    }

    return $record;
}

=head2 tmatrix_get_selected

Get selected table row from I<tm1>.

=cut

sub tmatrix_get_selected {
    my $self = shift;

    my $tmx = $self->scrobj('rec')->get_tm_controls('tm1');

    my $sc;
    if ( blessed $tmx ) {
        $sc = $tmx->get_selected();
    }

    return $sc;
}

=head2 tmatrix_set_selected

Set selected table row from I<tm1>.

=cut

sub tmatrix_set_selected {
    my ( $self, $row ) = @_;

    my $tmx = $self->scrobj('rec')->get_tm_controls('tm1');

    if ( blessed $tmx ) {
        $tmx->set_selected($row);
    }

    return;
}

=head2 toggle_mode_find

Toggle find mode, ask to save record if modified.

=cut

sub toggle_mode_find {
    my $self = shift;

    my $answer = $self->ask_to_save;    # if $self->model->is_modified;
    if ( !defined $answer ) {
        $self->view->get_toolbar_btn('tb_fm')->deselect;
        return;
    }

    $self->model->is_mode('find')
        ? $self->set_app_mode('idle')
        : $self->set_app_mode('find');

    $self->view->set_status( '', 'ms' );    # clear messages

    return;
}

=head2 toggle_mode_add

Toggle add mode, ask to save record if modified.

=cut

sub toggle_mode_add {
    my $self = shift;

    if ( $self->model->is_mode('edit') ) {
        my $answer = $self->ask_to_save;    # if $self->model->is_modified;
        if ( !defined $answer ) {
            $self->view->get_toolbar_btn('tb_ad')->deselect;
            return;
        }
    }

    $self->model->is_mode('add')
        ? $self->set_app_mode('idle')
        : $self->set_app_mode('add');

    $self->view->set_status( '', 'ms' );    # clear messages

    return;
}

=head2 controls_state_set

Toggle all controls state from I<Screen>.

=cut

sub controls_state_set {
    my ( $self, $set_state ) = @_;

    $self->_log->trace("Screen 'rec' controls state is '$set_state'");

    my $page = $self->view->get_nb_current_page();
    my $bg   = $self->scrobj($page)->get_bgcolor();

    my $ctrl_ref = $self->scrobj($page)->get_controls();
    return unless scalar keys %{$ctrl_ref};

    my $control_states = $self->control_states($set_state);

    return unless defined $self->scrcfg($page);

    foreach my $field ( keys %{ $self->scrcfg($page)->maintable('columns') } ) {
        my $fld_cfg = $self->scrcfg($page)->maintable('columns', $field);

        my $state = $control_states->{state};
        $state = $fld_cfg->{state}
            if $state eq 'from_config';

        my $bkground = $control_states->{background};
        my $bg_color = $bkground;
        $bg_color = $fld_cfg->{bgcolor}
            if $bkground eq 'from_config';
        $bg_color = $bg
            if $bkground eq 'disabled_bgcolor';

        # Special case for find mode and fields with 'findtype' set to none
        if ( $set_state eq 'find' ) {
            if ( $fld_cfg->{findtype} eq 'none' ) {
                $state    = 'disabled';
                $bg_color = $self->scrobj($page)->get_bgcolor();
            }
        }

        # Allow 'bg' as bgcolor config attribute value for controls
        $bg_color = $bg if $bg_color =~ m{bg|background};

        # Configure controls
        my $control = $self->scrobj()->get_controls($field);
        if ($control) {
            $self->view->configure_controls($control->[1], $state, $bg_color, $fld_cfg);
        }
        else {
            warn "Can't configure control for '$field'";
        }
    }

    return;
}

=head2 format_number

Return trimmed and formated numeric value.

=cut

sub format_number {
    my ( $self, $value, $numscale ) = @_;

    # Check if looks like a number
    return $value unless looks_like_number $value;

    $value = 0 unless defined $value;
    $value = sprintf( "%.${numscale}f", $value );

    return $value;
}

=head2 control_states

Return settings for controls, according to the state of the application.

=cut

sub control_states {
    my ( $self, $state ) = @_;

    return $self->{control_states}{$state};
}

=head2 record_load_new

Load a new record.

The (primary) key field value is col0 from the selected item in the
list control on the I<List> page.

=cut

sub record_load_new {
    my ( $self, $selected_href ) = @_;

    $self->screen_store_key_values($selected_href);

    $self->tmatrix_set_selected();    # initialize selector

    $self->record_load();

    if ( $self->model->is_loaded ) {
        $self->view->set_status(__ 'Record loaded (r)', 'ms', 'blue');
    }

    return;
}

=head2 record_reload

Reload the current record.

Reads the contents of the (primary) key field, retrieves the record from
the database table and loads the record data in the controls.

=cut

sub record_reload {
    my $self = shift;

    $self->record_load();

    $self->toggle_detail_tab;

    $self->view->set_status(__ 'Reloaded', 'ms', 'blue');

    $self->model->set_scrdata_rec(0);    # false = loaded,  true = modified,
                                         # undef = unloaded

    return;
}

=head2 record_load

Load the selected record in the current screen. First it loads the
main record into the screen widgets, than the dependent record(s) into
the TableMatrix widget(s) if configured.

=cut

sub record_load {
    my $self = shift;

    my $page = $self->view->get_nb_current_page();

    #-  Main table
    my $params = $self->main_table_metadata('qry');

    my $record;
    try {
        $record = $self->model->query_record($params);
    }
    catch {
        $self->catch_db_exceptions($_);
    };

    my $textstr = __ 'Empty record';
    $self->view->status_message("error#$textstr")
        if scalar keys %{$record} <= 0;

    $self->screen_write($record);

    #- Dependent table(s), (if any)

    foreach my $tm_ds ( keys %{ $self->scrobj($page)->get_tm_controls() } ) {
        my $tm_params = $self->dep_table_metadata( $tm_ds, 'qry' );

        my $records;
        try {
            $records = $self->model->table_batch_query($tm_params);
        }
        catch {
            $self->catch_db_exceptions($_);
        };

        my $tmx = $self->scrobj('rec')->get_tm_controls($tm_ds);
        $tmx->clear_all();
        $tmx->fill($records);

        my $sc = $self->scrcfg('rec')->dep_table_has_selectorcol($tm_ds);
        if ($sc) {
            $tmx->tmatrix_make_selector($sc);
        }
    }

    # Save record as witness reference for comparison
    $self->save_screendata( $self->storable_file_name('orig') );

    # Trigger on_load_record method from screen if defined
    $self->scrobj($page)->on_load_record()
        if $self->scrobj($page)->can('on_load_record');

    $self->model->set_scrdata_rec(0);    # false = loaded,  true = modified,
                                         # undef = unloaded

    return;
}

=head2 event_record_delete

Ask user if really wants to delete the record and proceed accordingly.

=cut

sub event_record_delete {
    my $self = shift;

    my $answer = $self->ask_to('delete');

    return if $answer eq 'cancel' or $answer eq 'no';

    $self->list_remove;         # first remove from list

    $self->record_delete();

    $self->view->set_status(__ 'Deleted', 'ms', 'darkgreen' );    # removed

    return;
}

=head2 record_delete

Delete record and clear the screen.

=cut

sub record_delete {
    my $self = shift;

    #-  Main table

    #-- Metadata
    my @record;

    my $record = {};
    $record->{metadata} = $self->main_table_metadata('del');
    push @record, $record;    # rec data at index 0

    #-  Dependent table(s), if any

    my $deprec = {};
    my $tm_dss = $self->scrobj->get_tm_controls();    #

    foreach my $tm_ds ( keys %{$tm_dss} ) {
        $deprec->{$tm_ds}{metadata}
            = $self->dep_table_metadata( $tm_ds, 'del' );
    }
    push @record, $deprec if scalar keys %{$deprec};    # det data at index 1

    try {
        $self->model->prepare_record_delete( \@record );
    }
    catch {
        $self->catch_db_exceptions($_);
    };

    $self->set_app_mode('idle');

    $self->model->unset_scrdata_rec();    # false = loaded,  true = modified,
                                           # undef = unloaded

    return;
}

=head2 record_clear

Clear the screen.

=cut

sub record_clear {
    my $self = shift;

    my $record = $self->make_empty_record();

    $self->screen_write($record);

    $self->screen_clear_key_values;

    $self->model->unset_scrdata_rec();    # false = loaded,  true = modified,
                                          # undef = unloaded
    return;
}

=head2 ask_to_save

If in I<add> or I<edit> mode show dialog and ask to save or
cancel. Reset modified status.

=cut

sub ask_to_save {
    my ($self, $page) = @_;

    return 0 unless $self->{_rscrcls}; # do we have record screen?

    return 0 unless $self->is_record;

    if (   $self->model->is_mode('edit')
        or $self->model->is_mode('add') )
    {
        if ( $self->record_changed ) {
            my $answer = $self->ask_to('save');

            if ( $answer eq 'yes' ) {
                $self->record_save();
            }
            elsif ( $answer eq 'no' ) {
                $self->view->set_status(__ 'Not saved', 'ms', 'blue' );
            }
            else {
                $self->view->set_status(__ 'Canceled', 'ms', 'blue');
                return;
            }
        }
    }

    return 1;
}

=head2 ask_to

Create a custom dialog to ask the user confirmation about the current
action.

=cut

sub ask_to {
    my ( $self, $for_action ) = @_;

    #- Dialog texts

    my ($message, $details);
    if ( $for_action eq 'save' ) {
        $message = __ 'Record changed';
        $details = __ 'Save record?';
    }
    elsif ( $for_action eq 'save_insert' ) {
        $message = __ 'New record';
        $details = __ 'Save record?';
    }
    elsif ( $for_action eq 'delete' ) {
        $message = __ 'Delete record';
        $details = __ 'Confirm record delete?';
    }

    # Message dialog
    return $self->view->dialog_confirm($message, $details, 'question', 'ycn');
}

=head2 record_save

Save record.  Different procedures for different modes.

First, check if required data present in screen.

=cut

sub record_save {
    my $self = shift;

    if ( $self->model->is_mode('add') ) {

        my $record = $self->get_screen_data_record('ins');

        return unless $self->check_required_data($record);

        my $answer = $self->ask_to('save_insert');

        return if $answer eq 'cancel' or $answer eq 'no';

        if ($answer eq 'yes') {
            my $pk_val = $self->record_save_insert($record);
            if ($pk_val) {
                $self->record_reload();
                $self->list_update_add(); # insert the new record in the list
                $self->view->set_status(__ 'Saved', 'ms', 'darkgreen');
            }
        }
        else {
            $self->view->set_status('canceled', 'ms', 'orange');
        }
    }
    elsif ( $self->model->is_mode('edit') ) {
        if ( !$self->is_record ) {
            $self->view->set_status(__ 'Empty record', 'ms', 'orange');
            return;
        }

        my $record = $self->get_screen_data_record('upd');

        return unless $self->check_required_data($record);

        try {
            $self->model->prepare_record_update($record);
        }
        catch {
            $self->catch_db_exceptions($_);
        };

        $self->view->set_status(__ 'Saved', 'ms', 'darkgreen');
    }
    else {
        $self->view->set_status(__ 'Not in edit|add mode!', 'ms', 'darkred');
        return;
    }

    # Save record as witness reference for comparison
    $self->save_screendata( $self->storable_file_name('orig') );

    $self->model->set_scrdata_rec(0);    # false = loaded,  true = modified,
                                         # undef = unloaded

    $self->toggle_detail_tab;

    return;
}

=head2 check_required_data

Check if required data is present in the screen.

There are two list used in this method, the list of the non empty
fields from the screen and the list of the fields that must have a
value.

This lists are compared and we build a new list with those items which
appear only in the second list, and build a message string with it.

Example I<Screen> data structure for the required field:

  $self->{rq_controls} = {
       productcode => [ 0, '  Product code' ],
       productname => [ 1, '  Product name' ],
       ...
       field1 => [ 10, '  Field descr. 1', [ 'tip1', 'Value 1' ] ],
       field2 => [ 11, '  Field descr. 2', [ 'tip2', 'Value 2' ] ],
  };

Fields depending on other fields. Check field1 only if tip1 has some value.

Returns I<true> if all required fields have values.

=cut

sub check_required_data {
    my ($self, $record) = @_;

    unless ( scalar keys %{ $record->[0]{data} } > 0 ) {
        $self->view->set_status(__ 'Empty record', 'ms', 'darkred');
        return 0;
    }

    my $page = $self->view->get_nb_current_page();
    my $ok_to_save = 1;

    my $ctrl_req = $self->scrobj($page)->get_rq_controls();
    if ( !scalar keys %{$ctrl_req} ) {
        my $warn_str = 'WW: Unimplemented screen data check in '
            . ucfirst $self->screen_string($page);
        $self->_log->info($warn_str);

        return $ok_to_save;
    }

    # List of the fields with values from the screen
    my @scr_fields;
    foreach my $field ( keys %{ $record->[0]{data} } ) {
        push @scr_fields, $field
            if defined( $record->[0]{data}{$field} )
                and $record->[0]{data}{$field} =~ m{\S+};
    }

    # List of the required fields from the rq_controls screen variable
    my (@req_fields, @req_cond);
    foreach my $field ( keys %{$ctrl_req} ) {
        my $cond = $ctrl_req->{$field}[2];
        if (ref($ctrl_req->{$field}[2]) eq 'ARRAY') {
            push @req_cond, $field;
        }
        else {
            push @req_fields, $field;
        }
    }

    my $lc = List::Compare->new('--unsorted', \@scr_fields, \@req_fields);

    my @required = $lc->get_complement;  # required except fields with data

    # Process the fields with conditional requirement
    foreach my $check_field (@req_cond) {
        my $cond_field = $ctrl_req->{$check_field}[2][0];
        my $cond_value = $ctrl_req->{$check_field}[2][1];
        if ( exists $record->[0]{data}{$cond_field} ) {
            my $check_value = $record->[0]{data}{$cond_field};
            if ( $cond_value eq $check_value ) {
                push @required, $check_field
                    unless $record->[0]{data}{$check_field};
            }
        }
        else {
            # No data for condition field?
            #$self->view->set_status( "$cond_field field?", 'ms', 'darkred' );
            print "No data for condition field: $cond_field field?\n";
        }
    }

    # Build a sorted, by index 0, message array data structure
    my $messages = [];
    foreach my $field (@required) {
        $messages->[ $ctrl_req->{$field}[0] ] = $ctrl_req->{$field}[1];
        $ok_to_save = 0;
    }

    my @message = grep { defined } @{$messages};    # remove undef elements

    if ( !$ok_to_save ) {
        my $message = __ 'Please, fill in data for:';
        my $details = join( "\n", @message );
        $self->view->dialog_info($message, $details);
    }

    return $ok_to_save;
}

=head2 record_save_insert

Insert record.

=cut

sub record_save_insert {
    my ( $self, $record ) = @_;

    my $pk_val;
    try {
        $pk_val = $self->model->prepare_record_insert($record);
    }
    catch {
        $self->catch_db_exceptions($_);
    };

    if ($pk_val) {
        my $pk_col = $record->[0]{metadata}{pkcol};
        $self->screen_write( { $pk_col => $pk_val } );
        $self->screen_store_key_values( { $pk_col => $pk_val } );
        $self->set_app_mode('edit');
    }

    return $pk_val;
}


=head2 list_update_add

Insert the current record in I<List>.

BUG: Lookup fields are empty in the list.

=cut

sub list_update_add {
    my $self = shift;

    my $columns = $self->list_column_names();
    my $current = $self->get_screen_data_record('upd');

    my @list;
    foreach my $field ( @{$columns} ) {
        push @list, $current->[0]->{data}{$field};
    }

    $self->view->list_populate( [ \@list ] );    # AoA

    return;
}

=head2 list_remove

Compare the selected row in the I<List> with given keys values and
remove it.

=cut

sub list_remove {
    my $self = shift;

    my @keys = $self->table_key('rec','main')->all_keys;
    my $key_values = {};
    foreach my $key (@keys) {
        $key_values->{$key->name} = $key->value;
    }
    $self->view->list_remove_selected($key_values);

    return;
}

=head2 record_changed

Retrieve the witness data structure from disk and the current data
structure read from the screen widgets and compare them.

=cut

sub record_changed {
    my $self = shift;

    my $witness_file = $self->storable_file_name('orig');

    unless ( -f $witness_file ) {
        $self->view->set_status(__ 'Changed record check failed!', 'ms', 'orange');
        die "Can't find saved data for comparison!";
    }

    my $witness = retrieve($witness_file);

    my $record = $self->get_screen_data_record('upd');

    return $self->model->record_compare( $witness, $record );
}

=head2 take_note

Save record to a temporary file on disk.  Can be restored into a new
record.  An easy way of making multiple records based on a template.

=cut

sub take_note {
    my $self = shift;

    my $msg
        = $self->save_screendata( $self->storable_file_name )
        ? __ 'Record copied'
        : __ 'Record copy failed';

    $self->view->set_status( $msg, 'ms', 'blue' );

    return;
}

=head2 restore_note

Restore record from a temporary file on disk into a new record.  An
easy way of making multiple records based on a template.

=cut

sub restore_note {
    my $self = shift;

    my $msg
        = $self->restore_screendata( $self->storable_file_name )
        ? __ 'Record restored'
        : __ 'Record restore failed';

    $self->view->set_status( $msg, 'ms', 'blue' );

    return;
}

=head2 storable_file_name

Return a file name build using the name of the configuration (by
convention the lower characters screen name) with a I<dat> extension.

If I<orig> parameter then add an I<-orig> string to the screen name.
Used for the witness files.

=cut

sub storable_file_name {
    my ( $self, $orig ) = @_;

    my $suffix = $orig ? q{-orig} : q{};

    # Store record data to file
    my $data_file
        = catfile( $self->cfg->configdir,
        $self->scrcfg->screen('name') . $suffix . q{.dat},
        );

    return $data_file;
}

=head2 get_screen_data_record

Make a record from screen data.  The data structure is an AoH where at
index 0 there is the main record meta-data and data and at index 1 the
dependent table(s) data and meta-data.

=cut

sub get_screen_data_record {
    my ( $self, $for_sql, $all ) = @_;

    $self->screen_read($all);

    my @record;

    #-  Main table

    #-- Metadata
    my $record = {};
    $record->{metadata} = $self->main_table_metadata($for_sql);
    $record->{data}     = {};

    #-- Data
    foreach my $field ( keys %{ $self->{_scrdata} } ) {
        $record->{data}{$field} = $self->{_scrdata}{$field};
    }

    push @record, $record;    # rec data at index 0

    #-  Dependent table(s), if any

    my $deprec = {};
    my $tm_dss = $self->scrobj->get_tm_controls();    #

    foreach my $tm_ds ( keys %{$tm_dss} ) {
        $deprec->{$tm_ds}{metadata}
            = $self->dep_table_metadata( $tm_ds, $for_sql );
        my $tmx = $self->scrobj('rec')->get_tm_controls($tm_ds);
        ( $deprec->{$tm_ds}{data}, undef ) = $tmx->data_read();

        # TableMatrix data doesn't contain pk_col=>pk_val, add it
        my $pk_ref = $record->{metadata}{where};
        foreach my $rec ( @{ $deprec->{$tm_ds}{data} } ) {
            @{$rec}{ keys %{$pk_ref} } = values %{$pk_ref};
        }
    }
    push @record, $deprec if scalar keys %{$deprec};    # det data at index 1

    return \@record;
}

=head2 main_table_metadata

Retrieve main table meta-data from the screen configuration.

=cut

sub main_table_metadata {
    my ( $self, $for_sql ) = @_;

    my $metadata = {};

    my $page = $self->view->get_nb_current_page();

    if ( $for_sql eq 'qry' ) {
        $metadata->{table} = $self->table_key($page, 'main')->view;
        my @keys = $self->table_key($page, 'main')->all_keys;
        foreach my $key (@keys) {
            $metadata->{where}{ $key->name } = $key->value;
        }
    }
    elsif ( ( $for_sql eq 'upd' ) or ( $for_sql eq 'del' ) ) {
        $metadata->{table} = $self->table_key($page, 'main')->table;
        my @keys = $self->table_key($page, 'main')->all_keys;
        foreach my $key (@keys) {
            $metadata->{where}{ $key->name } = $key->value;
        }
    }
    elsif ( $for_sql eq 'ins' ) {
        $metadata->{table} = $self->table_key($page, 'main')->table;
        $metadata->{pkcol} = $self->table_key($page, 'main')->get_key(0)->name;
    }
    else {
        warn "Wrong parameter: $for_sql\n";
        return;
    }

    return $metadata;
}

=head2 dep_table_metadata

Retrieve dependent table meta-data from the screen configuration.

=cut

sub dep_table_metadata {
    my ( $self, $tm, $for_sql ) = @_;

    my $metadata = {};

    my $page = $self->view->get_nb_current_page();

    my $pk_key = $self->table_key($page, 'main')->get_key(0)->name;
    my $pk_val = $self->table_key($page, 'main')->get_key(0)->value;

    if ( $for_sql eq 'qry' ) {
        $metadata->{table} = $self->table_key($page, $tm)->view;
        $metadata->{where}{$pk_key} = $pk_val;
    }
    elsif ( $for_sql eq 'upd' or $for_sql eq 'del' ) {
        $metadata->{table} = $self->table_key($page, $tm)->table;
        $metadata->{where}{$pk_key} = $pk_val;
    }
    elsif ( $for_sql eq 'ins' ) {
        $metadata->{table} = $self->table_key($page, $tm)->table;
    }
    else {
        die "Bad parameter: $for_sql";
    }

    my $columns = $self->scrcfg->deptable($tm, 'columns');

    $metadata->{pkcol}    = $pk_key;
    $metadata->{fkcol}    = $self->table_key($page, $tm)->get_key(1)->name;
    $metadata->{order}    = $self->scrcfg->deptable($tm, 'orderby');
    $metadata->{colslist} = Tpda3::Utils->sort_hash_by_id($columns);
    $metadata->{updstyle} = $self->scrcfg->deptable($tm, 'updatestyle');

    return $metadata;
}

=head2 report_table_metadata

Retrieve table meta-data for report screen style configurations from
the screen configuration.

=cut

sub report_table_metadata {
    my ( $self, $level ) = @_;

    my $metadata = {};

    # DataSourceS meta-data
    my $dss    = $self->scrcfg()->repotable('datasources');
    my $cntcol = $self->scrcfg()->repotable('rowcount');
    my $table  = $dss->{level}[$level]{table};
    my $pkcol  = $dss->{level}[$level]{pkcol};

    # DataSource meta-data by column
    my $ds = $self->scrcfg()->repo_table_columns_by_level($level);

    my @datasource = grep { m/^[^=]/ } keys %{$ds};
    my @tables = uniq @datasource;
    if (scalar @tables == 1) {
        $metadata->{table} = $tables[0];
    }
    else {
        # Wrong datasources config for level $level?
        return;
    }

    $metadata->{pkcol}    = $pkcol;
    $metadata->{colslist} = $ds->{$tables[0]};
    $metadata->{rowcount} = $cntcol;
    push @{ $metadata->{colslist} }, $pkcol;  # add PK to cols list

    return $metadata;
}

=head2 get_table_sumup_cols

Return table C<sumup> cols.

=cut

sub get_table_sumup_cols {
    my ( $self, $tm_ds, $level ) = @_;

    my $metadata = $self->scrcfg->repo_table_columns_by_level($tm_ds, $level);

    return $metadata->{'=sumup'};
}

=head2 save_screendata

Save screen data to temp file with Storable.

=cut

sub save_screendata {
    my ( $self, $data_file ) = @_;

    my $record = $self->get_screen_data_record('upd');

    $self->_log->trace("Saving screen data in '$data_file'");

    return store( $record, $data_file );
}

=head2 restore_screendata

Restore screen data from file saved with Storable.

=cut

sub restore_screendata {
    my ( $self, $data_file ) = @_;

    unless ( -f $data_file ) {
        warn "Data file '$data_file' not found!\n";
        return;
    }

    my $rec = retrieve($data_file);
    unless ( defined $rec ) {
        warn "Unable to retrieve from $data_file!\n";
        return;
    }

    #- Main table

    my $mainrec = $rec->[0];    # main record is first

    # Dont't want to restore the Id field, remove it
    my $where = $mainrec->{metadata}{where};
    delete $mainrec->{data}{$_} for keys %{$where};

    $self->screen_write( $mainrec->{data} );

    #- Dependent table(s), if any

    my $deprec = $rec->[1];     # dependent records follow

    foreach my $tm_ds ( keys %{ $self->scrobj('rec')->get_tm_controls() } ) {
        my $tmx = $self->scrobj('rec')->get_tm_controls($tm_ds);
        $tmx->clear_all();
        $tmx->fill( $deprec->{$tm_ds}{data} );
    }

    return 1;
}

=head2 screen_store_key_values

Store key column values for the current screen.

=cut

sub screen_store_key_values {
    my ( $self, $record_href ) = @_;

    my $page = $self->view->get_nb_current_page();

    foreach my $field ( keys %{$record_href} ) {
        my $value = $record_href->{$field};
        $self->table_key( $page, 'main' )->update_field( $field, $value );
    }

    return;
}

=head2 screen_clear_key_values

Clear key column values for the current screen.

=cut

sub screen_clear_key_values {
    my $self = shift;

    my $page = $self->view->get_nb_current_page();
    my $table_keys = $self->table_key($page, 'main');
    return unless blessed $table_keys;
    foreach my $key ( $table_keys->all_keys ) {
        $key->value(undef);
    }

    return;
}

=head2 list_column_names

Return the list column names.

=cut

sub list_column_names {
    my $self = shift;

    my $header_look = $self->scrcfg('rec')->list_header('lookup');
    my $header_cols = $self->scrcfg('rec')->list_header('column');

    my $columns = [];
    push @{$columns}, @{$header_look};
    push @{$columns}, @{$header_cols};

    return $columns;
}

=head2 flatten_cfg

TODO

=cut

sub flatten_cfg {
    my ( $self, $level, $attribs ) = @_;
    my %flatten;
    foreach my $key ( keys %{$attribs} ) {
        my $value = $attribs->{$key};
        ( ref $value eq 'HASH' )
            ? ( $flatten{$key} = $value->{"level$level"} )
            : ( $flatten{$key} = $value );
    }
    return \%flatten;
}

=head2 record_merge_columns

Merge level columns with header columns and set default values.

=cut

sub record_merge_columns {
    my ($self, $record, $header) = @_;

    my %hr;
    foreach my $field ( keys %{ $header->{columns} } ) {
        my $field_type = $header->{columns}{$field}{datatype};
        # column type          default
        my $default_value
        = $field_type eq 'numeric' ? 0
        : $field_type eq 'integer' ? 0
        :                            undef # default
        ;

        $hr{$field} = $record->{$field} ? $record->{$field} : $default_value;
    }

    return \%hr;
}

=head2 DESTROY

Cleanup on destroy.  Remove I<Storable> data files from the
configuration directory.

=cut

sub DESTROY {
    my $self = shift;

    # my $dir = $self->cfg->configdir;
    # my @files = glob("$dir/*.dat");

    # foreach my $file (@files) {
    #     if ( -f $file ) {
    #         my $cnt = unlink $file;
    #         if ( $cnt == 1 ) {
    #             # print "Cleanup: $file\n";
    #         }
    #         else {
    #             $self->_log->error("EE, cleaning up: $file");
    #         }
    #     }
    # }
}

=head2 on_quit

Close application.

=cut

sub on_quit {
    my $self = shift;

    print "Shutting down...\n";

    $self->view->on_close_window(@_);
}

sub catch_db_exceptions {
    my ($self, $exc) = @_;

    my ($message, $details);

    if ( my $e = Exception::Base->catch($exc) ) {
        if ( $e->isa('Exception::Db::SQL') ) {
            $message = $e->usermsg;
            $details = $e->logmsg;
            print "Exc isa SQL ($message, $details)\n";
        }
        elsif ( $e->isa('Exception::Db::Connect') ) {
            $message = $e->usermsg;
            $details = $e->logmsg;
            print "Exception is a Connect ($message, $details)\n";
        }
        else {
            print "Exception is a Unknown\n";
            $self->_log->error( $e->message );
            $e->throw;    # rethrow the exception
            return;
        }

        my $dlg = Tpda3::Tk::Dialog::Message->new($self->view);
        $dlg->message_dialog($message, $details, 'error', 'close');
    }

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Controller
