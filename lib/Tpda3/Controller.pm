package Tpda3::Controller;

use strict;
use warnings;
use utf8;

use English;
use Data::Dumper;

use Encode qw(is_utf8 encode decode);
use Scalar::Util qw(blessed looks_like_number);
use List::MoreUtils qw{uniq};
use Class::Unload;
use Log::Log4perl qw(get_logger :levels);
use Storable qw (store retrieve);
use File::Basename;
use File::Spec::Functions qw(catfile);
use Math::Symbolic;

use Try::Tiny;
use Tpda3::Exceptions;

require Tpda3::Utils;
require Tpda3::Config;
require Tpda3::Model;
require Tpda3::Lookup;
require Tpda3::Selected;
require Tpda3::Generator;

=head1 NAME

Tpda3::Controller - The Controller

=head1 VERSION

Version 0.62

=cut

our $VERSION = 0.62;

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

=item _tblkeys  - primary and foreign keys and values record

=item _scrdata  - current screen data

=back

=cut

sub new {
    my $class = shift;

    my $model = Tpda3::Model->new();

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
    my $driver = $self->_cfg->connection->{driver};
    if (   ( $self->_cfg->user and $self->_cfg->pass )
        or ( $driver eq 'sqlite' ) )
    {
        $self->_model->db_connect();
        return;
    }

    # Retry until connected or canceled
    $self->start_delay()
        unless ( $self->_model->is_connected
        or $self->_cfg->connection->{driver} eq 'sqlite' );

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
    while ( not $self->_model->is_connected ) {

        # Show login dialog if still not connected
        my $return_string = $self->dialog_login($error);
        if ($return_string eq 'cancel') {
            $self->_view->set_status( 'Login cancelled', 'ms' );
            last TRY;
        }

        # Try to connect only if user and pass are provided
        if ($self->_cfg->user and $self->_cfg->pass ) {
            try {
                $self->_model->db_connect();
            }
            catch {
                if ( my $e = Exception::Base->catch($_) ) {
                    if ( $e->isa('Tpda3::Exception::Db::Connect') ) {
                        $error = $e->usermsg;
                    }
                }
            };
        }
        else {
            $error = 'User and password required';
        }

    }

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

=head2 localize

Simple localisation.

=cut

sub localize {
    my ($self, $section, $string) = @_;

    my $localized = $self->_cfg->localize->{$section}{$string};
    unless ($localized) {
        $localized = "'$string'";
        print "Localization error for '$string'\n";
    }

    return $localized;
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
    $self->_view->event_handler_for_menu(
        'mn_fm',
        sub {
            return if !defined $self->ask_to_save;

            # From add or sele mode forbid find mode
            $self->toggle_mode_find()
                unless ( $self->_model->is_mode('add')
                    or $self->_model->is_mode('sele') );
        }
    );

    #-- Toggle execute find - Menu
    $self->_view->event_handler_for_menu(
        'mn_fe',
        sub {
            $self->_model->is_mode('find')
                ? $self->record_find_execute
                : $self->_view->set_status(
                    $self->localize( 'status', 'not-find' ),
                    'ms', 'orange' );
        }
    );

    #-- Toggle execute count - Menu
    $self->_view->event_handler_for_menu(
        'mn_fc',
        sub {
            $self->_model->is_mode('find')
                ? $self->record_find_count
                : $self->_view->set_status(
                    $self->localize( 'status', 'not-find' ),
                    'ms', 'orange' );
        }
    );

    #-- Exit
    $self->_view->event_handler_for_menu(
        'mn_qt',
        sub {
            return if !defined $self->ask_to_save;
            $self->on_quit;
        }
    );

    #-- Help
    $self->_view->event_handler_for_menu(
        'mn_gd',
        sub {
            $self->guide;
        }
    );

    #-- About
    $self->_view->event_handler_for_menu(
        'mn_ab',
        sub {
            $self->about;
        }
    );

    #-- Preview RepMan report
    $self->_view->event_handler_for_menu(
        'mn_pr',
        sub { $self->repman; }
    );

    #-- Edit RepMan report metadata
    $self->_view->event_handler_for_menu(
        'mn_er',
        sub {
            $self->screen_module_load('Reports','tools');
        }
    );

    #-- Save geometry
    $self->_view->event_handler_for_menu(
        'mn_sg',
        sub {
            $self->save_geometry();
        }
    );

    #-- Admin - set default mnemonic
    $self->_view->event_handler_for_menu(
        'mn_mn',
        sub {
            $self->set_mnemonic();
        }
    );

    #-- Admin - configure
    $self->_view->event_handler_for_menu(
        'mn_cf',
        sub {
            $self->set_app_configs();
        }
    );

    #- Custom application menu from menu.yml

    my $appmenus = $self->_view->get_app_menus_list();
    foreach my $item ( @{$appmenus} ) {
        $self->_view->event_handler_for_menu(
            $item,
            sub {
                $self->screen_module_load($item);
            }
        );
    }

    #- Toolbar

    #-- Find mode
    $self->_view->event_handler_for_tb_button(
        'tb_fm',
        sub {
            $self->toggle_mode_find();
        }
    );

    #-- Find execute
    $self->_view->event_handler_for_tb_button(
        'tb_fe',
        sub {
            $self->record_find_execute();
        }
    );

    #-- Find count
    $self->_view->event_handler_for_tb_button(
        'tb_fc',
        sub {
            $self->record_find_count();
        }
    );

    #-- Print (preview) default report button
    $self->_view->event_handler_for_tb_button(
        'tb_pr',
        sub {
            $self->screen_report_print();
        }
    );

    #-- Generate default document button
    $self->_view->event_handler_for_tb_button(
        'tb_gr',
        sub {
            $self->screen_document_generate();
        }
    );

    #-- Take note
    $self->_view->event_handler_for_tb_button(
        'tb_tn',
        sub {
            $self->take_note();
        }
    );

    #-- Restore note
    $self->_view->event_handler_for_tb_button(
        'tb_tr',
        sub {
            $self->restore_note();
        }
    );

    #-- Reload
    $self->_view->event_handler_for_tb_button(
        'tb_rr',
        sub {
            $self->record_reload();
        }
    );

    #-- Add mode; From sele mode forbid add mode
    $self->_view->event_handler_for_tb_button(
        'tb_ad',
        sub {
            $self->toggle_mode_add();
        }
    );

    #-- Delete
    $self->_view->event_handler_for_tb_button(
        'tb_rm',
        sub {
            $self->event_record_delete();
        }
    );

    #-- Save record
    $self->_view->event_handler_for_tb_button(
        'tb_sv',
        sub {
            $self->record_save();
        }
    );

    #-- Attach to desktop - pin (save geometry to config file)
    $self->_view->event_handler_for_tb_button(
        'tb_at',
        sub {
            $self->save_geometry();
        }
    );

    #-- Quit
    $self->_view->event_handler_for_tb_button(
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

    if ( $sel and !$self->_model->is_modified ) {
        $self->_view->nb_set_page_state( 'det', 'normal');
    }
    else {
        $self->_view->nb_set_page_state( 'det', 'disabled');
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

    $self->_view->set_status( '', 'ms' );    # clear

    if ( $self->_model->is_mode('sele') ) {
        $self->set_app_mode('edit');
    }
    else {
        $self->toggle_interface_controls;
    }

    $self->_view->nb_set_page_state( 'lst', 'normal');

    return unless $self->_view->get_nb_previous_page eq 'lst';

    my $selected = $self->_view->list_read_selected();    # array reference
    unless ($selected) {
        $self->_view->set_status( $self->localize( 'status', 'not-selected' ),
            'ms', 'orange' );
        $self->set_app_mode('idle');

        return;
    }

    #- Compare PK values, load record only if different

    my $pk_val_new = $selected->[0];    # first is the pk value
    my $fk_val_new = $selected->[1];    # second the fk value

    my $pk_val_old = $self->screen_get_pk_val() || q{};    # empty for eq
    my $fk_val_old = $self->screen_get_fk_val() || q{};

    if ( $pk_val_new ne $pk_val_old ) {
        $self->record_load_new( $pk_val_new, $fk_val_new );
    }
    else {
        # For detail screens in 'rec' page
        if ( defined $fk_val_new ) {
            if ( $fk_val_new ne $fk_val_old ) {
                $self->record_load_new( $pk_val_new, $fk_val_new );
            }
        }
    }

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

    my $dsm = $self->screen_detail_name();
    if ($dsm) {
        $self->screen_detail_load($dsm);
    }
    else {
        $self->_view->get_notebook()->raise('rec');
        return;
    }

    $self->get_selected_and_set_fk_val;

    $self->record_load();                    # load detail record

    $self->_view->set_status( $self->localize( 'status', 'info-rec-load-d' ),
                              'ms', 'blue' );
    $self->set_app_mode('edit');

    # $self->_model->set_scrdata_rec(q{});    # empty

    $self->_view->nb_set_page_state( 'lst', 'disabled');

    return;
}

=head2 screen_detail_name

Detail screen module name from screen configuration.

=cut

sub screen_detail_name {
    my $self = shift;

    my $screen = $self->scrcfg('rec')->screen_detail;

    my $dsm;
    if ( ref $screen->{detail} eq 'ARRAY' ) {
        $dsm = $self->get_dsm_name($screen);
    }
    else {
        $dsm = $screen;
    }

    return $dsm;
}

=head2 get_selected_and_set_fk_val

Read the selected row from I<tm1> TableMatrix widget from the
I<Record> page and get the foreign key value designated by the
I<filter> configuration value of the screen.

Save the foreign key value.

The default table with selector column is I<tm1>.

=cut

sub get_selected_and_set_fk_val {
    my $self = shift;

    my $row = $self->tmatrix_get_selected;

    return unless defined $row and $row > 0;

    # Detail screen module name from config
    my $screen = $self->scrcfg('rec')->screen_detail;

    my $tmx = $self->scrobj('rec')->get_tm_controls('tm1');
    my $params = $tmx->cell_read( $row, $screen->{filter} );

    my $fk_col = $self->screen_get_fk_col;
    my $fk_val = $params->{$fk_col};

    $self->screen_set_fk_val($fk_val);

    return;
}

=head2 screen_detail_load

Check if the detail screen module is loaded, and load if it's not.

=cut

sub screen_detail_load {
    my ( $self, $dsm ) = @_;

    my $dscrstr = $self->screen_string('det');

    unless ( $dscrstr && ( $dscrstr eq lc $dsm ) ) {
        #print "Loading detail screen ($dsm)\n";
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
        $self->_view->set_menu_enable($menu, $state);
    }
}

=head2 _check_app_menus

Check if screen modules from the menu exists and are loadable.
Disable those which fail the test.

Only for I<menu_user> hardwired menu name for now!

=cut

sub _check_app_menus {
    my $self = shift;

    my $appmenus = $self->_view->get_app_menus_list();
    foreach my $menu_item ( @{$appmenus} ) {
        my ( $class, $module_file ) = $self->screen_module_class($menu_item);
        eval { require $module_file };
        if ($@) {
            $self->_view->set_menu_enable($menu_item, 'disabled');
            print "$menu_item screen disabled ($module_file).\n";
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
     lookup              = customername
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

    my $locale_data = $self->_cfg->localize->{search};

    my $dict     = Tpda3::Lookup->new($locale_data);
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
        my $field_cfg = $self->scrcfg('rec')->main_table_column($column);
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

        $self->_log->trace("Setup binding for '$bind_name' with:");
        $self->_log->trace( sub { Dumper($para) } );

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

        $self->_view->make_binding_entry(
            $ctrl_ref->{$column}[1],
            '<Return>',
            sub {
                my $filter
                    = defined $para->{filter}
                    ? $self->filter_field( $para->{filter} )
                    : undef;
                my $record = $dict->lookup( $self->_view, $para, $filter );
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
activates the C<Tpda3::XX::Dialog::Search> module, to look-up value
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

    my $locale_data = $self->_cfg->localize->{search};

    my $dict     = Tpda3::Selected->new($locale_data);
    my $ctrl_ref = $self->scrobj($page)->get_controls();

    return unless $self->scrcfg($page)->can('bindings_select');

    my $bindings = $self->scrcfg($page)->bindings_select;

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

        $self->_log->trace("Setup select binding for '$bind_name' with:");
        $self->_log->trace( sub { Dumper($para) } );

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

        $self->_view->make_binding_entry(
            $ctrl_ref->{$bind_name}[1],
            '<Return>',
            sub {
                $self->_view->status_message("warn#"); # clear message
                my $value = $self->ctrl_read_from($field);
                if ($field and $value) {
                    $para->{where} = { $field => $value };
                    my $records = $dict->selected( $self->_view, $para );

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
                    $self->_view->status_message("warn#$textstr");
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
        my $col = $self->scrcfg('rec')
            ->dep_table_column_attr( $tm_ds, $fld, 'id' );
        $filter = $tmx->cell_read( $r, $col );
    }

    my $locale_data = $self->_cfg->localize->{search};
    my $dict        = Tpda3::Lookup->new($locale_data);
    my $record      = $dict->lookup( $self->_view, $lk_para, $filter );

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
    my $field_cfg = $self->scrcfg('rec')->dep_table_column( $tm_ds, $column );

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
                ->dep_table_column( $tm_ds, $lookup_field );
        }
        else {
            $field_cfg
                = $self->scrcfg('rec')->main_table_column($lookup_field);
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
                ->dep_table_columns( $tm_ds, $scr_field );
        }
        else {
            $field_cfg = $self->scrcfg('rec')->main_table_column($scr_field);
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

    return $self->screen_get_pk_val;
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

    $self->_view->nb_set_page_state( 'det', 'disabled');
    $self->_view->nb_set_page_state( 'lst', 'normal');

    # Trigger 'on_mode_idle' method in screen if defined
    my $page = $self->_view->get_nb_current_page();
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

    $self->_view->nb_set_page_state( 'det', 'disabled' );
    $self->_view->nb_set_page_state( 'lst', 'disabled' );

    # Default value for user in screen.  Add 'id_user' value if
    # 'id_user' control exists in screen
    my $user_field = 'id_user';              # hardwired user field name
    my $control_ref = $self->scrobj()->get_controls($user_field);
    $self->ctrl_write_to( $user_field, $self->_cfg->user ) if $control_ref;

    # Trigger 'on_mode_add' method in screen if defined
    my $page = $self->_view->get_nb_current_page();
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
    my $page = $self->_view->get_nb_current_page();
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
    $self->_view->nb_set_page_state( 'det', 'normal');
    $self->_view->nb_set_page_state( 'lst', 'normal');

    # Trigger 'on_mode_edit' method in screen if defined
    my $page = $self->_view->get_nb_current_page();
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

    my $nb = $self->_view->get_notebook();
    $self->_view->nb_set_page_state( 'det', 'disabled');

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

    $page ||= $self->_view->get_nb_current_page();

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
the required page.

=cut

sub scrobj {
    my ( $self, $page ) = @_;

    $page ||= $self->_view->get_nb_current_page();

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

    # reload toolbar - if? altered by prev screen
    $self->_cfg->toolbar_interface_reload();

    # Make new NoteBook widget and setup callback
    $self->_view->create_notebook();
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

    return unless $self->check_cfg_version;  # current version is 3

    # Details page
    my $has_det = $self->scrcfg('rec')->has_screen_detail;
    if ($has_det) {
        my $lbl_details = $self->localize( 'notebook', 'lbl_details' );
        $self->_view->create_notebook_panel( 'det', $lbl_details );
        $self->_set_event_handler_nb('det');
    }

    # Show screen
    my $nb = $self->_view->get_notebook();
    $self->{_rscrobj}->run_screen($nb);

    # Store currently loaded screen class
    $self->{_rscrcls} = $class;

    # Load instance config
    $self->_cfg->config_load_instance();

    #-- Lookup bindings for Entry widgets
    $self->setup_lookup_bindings_entry('rec');
    $self->setup_select_bindings_entry('rec');

    #-- Lookup bindings for tables (TableMatrix)
    $self->setup_bindings_table();

    # Set PK column name
    $self->screen_set_pk_col();

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

    my $group_labels = $self->scrcfg()->scr_toolbar_groups();
    foreach my $label ( @{$group_labels} ) {
        $self->set_event_handler_screen($label);
    }

    # Toggle find mode menus
    my $menus_state
        = $self->scrcfg()->screen_style() eq 'report'
        ? 'disabled'
        : 'normal';
    $self->_set_menus_enable($menus_state);

    $self->_view->set_status( '', 'ms' );

    $self->_model->unset_scrdata_rec();

    # Change application title
    my $descr = $self->scrcfg('rec')->screen_description;
    $self->_view->title(' Tpda3 - ' . $descr) if $descr;

    # Update window geometry
    $self->set_geometry();

    # Load lists into ComboBox type widgets
    $self->screen_load_lists();

    return 1;                       # to make ok from Test::More happy
}

=head2 check_cfg_version

Return undef if screen config version doesn't check.

=cut

sub check_cfg_version {
    my $self = shift;

    my $cfg = $self->scrcfg()->screen;

    my $req_ver = 4;            # current screen config version
    my $cfg_ver = ( exists $cfg->{version} )
                ? $cfg->{version}
                : 1
                ;

    unless ( $cfg_ver == $req_ver ) {
        my $screen_name = $self->scrcfg->screen_name();
        print "Error ($screen_name.conf):\n";
        print "  screen config version is $cfg_ver\n";
        print "       required version is $req_ver\n";
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

    $self->_view->notebook_page_clean('det');

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
    my $nb = $self->_view->get_notebook();
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

    $self->_view->set_status( '', 'ms' );

    # Set FK column name
    $self->screen_set_fk_col();

    return;
}

=head2 screen_string

Return a lower case string of the current screen module name.

=cut

sub screen_string {
    my ( $self, $page ) = @_;

    $page ||= $self->_view->get_nb_current_page();

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
        ? $self->scrcfg()->screen_name
        : 'main';

    $self->_cfg->config_save_instance(
        $scr_name,
        $self->_view->get_geometry()
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

    foreach my $field ( keys %{ $self->scrcfg()->main_table_columns } ) {

        # Control config attributes
        my $fld_cfg  = $self->scrcfg()->main_table_column($field);
        my $ctrltype = $fld_cfg->{ctrltype};
        my $ctrlrw   = $fld_cfg->{readwrite};

        my $para = $self->scrcfg()->{lists_ds}{$field};

        next unless ref $para eq 'HASH';       # undefined, skip

        # Query table and return data to fill the lists
        my $choices = $self->{_model}->get_codes( $field, $para, $ctrltype );

        if ( $ctrltype eq 'm' ) {
            if ( $ctrl_ref->{$field}[1] ) {
                my $control = $ctrl_ref->{$field}[1];
                $self->_view->list_control_choices($control, $choices);
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

    my ( $toolbars, $attribs ) = $self->_view->toolbar_names();

    my $mode = $self->_model->get_appmode;
    my $page = $self->_view->get_nb_current_page();

    my $is_rec = $self->is_record('rec');

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
                    !$self->scrcfg('rec')->get_defaultreport_file;
            }

            #-- Generate document

            # Activate only if default document template configured
            # for screen
            if ( ( $name eq 'tb_gr' ) and ( $status eq 'normal' ) ) {
                $status = 'disabled' if
                    !$self->scrcfg('rec')->get_defaultdocument_file;
            }
        }
        else {
            #-- List tab

            $status = 'disabled';
        }

        #- Set status for toolbar buttons

        $self->_view->enable_tool( $name, $status );
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

    my $page = $self->_view->get_nb_current_page();
    my $mode = $self->_model->get_appmode;

    return if $page eq 'lst';

    #- Toolbar (table)

    my $group_labels = $self->scrcfg()->scr_toolbar_groups();
    foreach my $label ( @{$group_labels} ) {
        my ( $toolbars, $tb_attrs ) = $self->scrobj()->app_toolbar_names($label);
        foreach my $button_name ( @{$toolbars} ) {
            my $status
                = $self->scrcfg()->screen_style() eq 'report'
                ? 'normal'
                : $tb_attrs->{$button_name}{state}{$page}{$mode};
            $self->scrobj($page)->enable_tool( $label, $button_name, $status );
        }
    }

    #- Other controls

    # my $cfg_ref = $self->scrcfg($page);
    # my $cfgdeps = $self->scrcfg($page)->dependencies;

    # foreach my $field ( keys %{ $cfg_ref->main_table_columns } ) {

    #     # Skip field if not in record or not dependent
    #     next
    #         unless $self->is_dependent( $field, $cfgdeps );

    #     my $fldcfg = $cfg_ref->main_table_column($field);

    #     # Process dependencies
    #     my $state;
    #     if (exists $cfgdeps->{$field} ) {
    #         $state = $self->dependencies($field, $cfgdeps);
    #     }

    #     print "Set state of '$field' to '$state'\n";
    #     my $control = $self->scrobj()->get_controls($field)->[1];
    #     $control->configure( -state => $state );
    # }

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

=item full   - field = I<searchstring>

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
    my $columns = $self->scrcfg('rec')->main_table_columns;

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
    $params->{table} = $self->scrcfg('rec')->main_table_view; # use view
    $params->{pkcol} = $self->scrcfg('rec')->main_table_pkcol;

    my ($ary_ref, $limit) = $self->_model->query_records_find($params);

    # return unless defined $ary_ref->[0];     # test if AoA ?
    unless (ref $ary_ref eq 'ARRAY') {
        die "Find failed!";
    }

    my $record_count = scalar @{$ary_ref};
    my $msg1 = $self->localize( 'status', 'count_record' );
    my $msg0 = $record_count == $limit
             ? $self->localize( 'status', 'first' )
             : q{};

    $self->_view->set_status( "$msg0 $record_count $msg1", 'ms', 'darkgreen' );

    $self->_view->list_init();
    my $record_inlist = $self->_view->list_populate($ary_ref);
    $self->_view->list_raise() if $record_inlist > 0;

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

    my $record_count = $self->_model->query_records_count($params);

    my $msg = $self->localize( 'status', 'count_record' );
    $self->_view->set_status( "$record_count $msg", 'ms', 'darkgreen' );

    return;
}

=head2 screen_report_print

Printing report configured as default with Report Manager.

=cut

sub screen_report_print {
    my $self = shift;

    return unless ref $self->scrobj('rec');

    my $pk_col = $self->screen_get_pk_col;
    my $pk_val = $self->screen_get_pk_val;

    my $param;
    if ($pk_val) {
        $param = "$pk_col=$pk_val";          # default parameter ID
    } else {
        # Atentie
        my $textstr = "Load a record first";
        $self->_view->status_message("error#$textstr");
        return;
    }

    my $report_exe  = $self->_cfg->cfextapps->{repman}{exe_path};
    my $report_file = $self->scrcfg('rec')->get_defaultreport_file;

    my $options = qq{-preview -param$param};

    $self->_log->trace("Report tool: $report_exe");
    $self->_log->trace("Report file: $report_file");

    # Metaviewxp
    my $cmd;
    if ( defined $param ) {
        $cmd = qq{"$report_exe" $options "$report_file"};
    }
    else {
        print "0 parameters?\n";
        return;
    }

    $self->_log->debug("Report cmd: $cmd.");

    if ( system $cmd ) {
        $self->_view->set_status( $self->localize( 'status', 'error-repo' ),
            'ms' );
    }

    return;
}

=head2 screen_document_generate

Generate default document assigned to screen.

=cut

sub screen_document_generate {
    my $self = shift;

    return unless ref $self->scrobj('rec');

    my $record;

    my $datasource = $self->scrcfg()->get_defaultdocument_datasource();
    if ($datasource) {
        $record = $self->get_alternate_data_record($datasource);
    }
    else {
        $record = $self->get_screen_data_record('qry', 'all');
    }

    my $fields_no = scalar keys %{ $record->[0]{data} };
    if ( $fields_no <= 0 ) {
        $self->_view->set_status( $self->localize( 'status', 'empty-record' ),
            'ms', 'red' );
        $self->_log->error('Generator: No data!');
    }

    my $model_file = $self->scrcfg()->get_defaultdocument_file();
    unless ( -f $model_file ) {
        $self->_view->set_status(
            $self->localize( ' status ', ' error-repo ' ),
            'ms', 'red' );
        $self->_log->error('Generator: Template not found');
        return;
    }

    my $output_path = $self->_cfg->config_tex_path('output');
    unless ( -d $output_path ) {
        $self->_view->set_status(
            $self->localize( ' status ', 'no-out-path' ),
            'ms', 'red' );
        $self->_log->error('Generator: Output path not found');
        return;
    }

    my $gen = Tpda3::Generator->new();

    #-- Generate LaTeX document from template

    my $tex_file = $gen->tex_from_template($record, $model_file, $output_path);
    unless ( $tex_file and ( -f $tex_file ) ) {
        my $msg = $self->localize( 'status', 'error-gen-tex' );
        $self->_view->set_status( $msg, 'ms', 'red' );
        $self->_log->error($msg);
        return;
    }

    #-- Generate PDF from LaTeX

    my $pdf_file = $gen->pdf_from_latex($tex_file);
    unless ( $pdf_file and ( -f $pdf_file ) ) {
        my $msg = $self->localize( 'status', 'error-gen-pdf' );
        $self->_view->set_status( $msg, 'ms', 'red' );
        $self->_log->error($msg);
        return;
    }

    $self->_view->set_status( "PDF: $pdf_file", 'ms', 'blue' );

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

    $record->{data} = $self->_model->query_record( $record->{metadata} );

    my @rec;
    push @rec, $record;    # rec data at index 0

    return \@rec;
}

=head2 screen_read

Read screen controls (widgets) and save in a Perl data structure.

Returns different data for different application modes.

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
    my $date_format = $self->_cfg->application->{dateformat} || 'iso';

    foreach my $field ( keys %{ $scrcfg->main_table_columns() } ) {
        my $fld_cfg = $scrcfg->main_table_column($field);

        # Control config attributes
        my $ctrltype = $fld_cfg->{ctrltype};
        my $ctrlrw   = $fld_cfg->{readwrite};

        if ( !$all ) {
            unless ( $self->_model->is_mode('find') ) {
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

    my $ctrltype = $self->scrcfg()->main_table_column($field)->{ctrltype};

    my $value;
    my $sub_name = "control_read_$ctrltype";
    if ( $self->_view->can($sub_name) ) {
        my $control_ref = $self->scrobj()->get_controls($field);
        $value = $self->_view->$sub_name( $control_ref, $date_format );
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

    $value = Tpda3::Utils->trim($value);

    # Find mode
    if ( $self->_model->is_mode('find') ) {
        if ($value) {
            $self->{_scrdata}{$field} = $value;
        }
        else {
            if ($ctrltype eq 'e') {
                # Can't use numeric eq (==) here
                if ( $value =~ m{^0+$} ) {
                    $self->{_scrdata}{$field} = $value;
                }
            }
        }
    }
    # Add mode, non empty fields, 0 is allowed
    elsif ( $self->_model->is_mode('add') ) {
        if ( defined($value) and ( $value =~ m{\S+} ) ) {
            $self->{_scrdata}{$field} = $value;
        }
    }
    # Edit mode, non empty fields, 0 is allowed
    elsif ( $self->_model->is_mode('edit') ) {
        if ( defined($value) and ( $value =~ m{\S+} ) ) {
            $self->{_scrdata}{$field} = $value;
        }
        else {
            $self->{_scrdata}{$field} = undef;
        }
    }
    else {
        # Error!
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
    my $page = $self->_view->get_nb_current_page();

    return if $page eq 'lst';

    my $ctrl_ref = $self->scrobj($page)->get_controls();
    return unless scalar keys %{$ctrl_ref};    # no controls?

    my $cfg_ref = $self->scrcfg($page);

    # Get configured date style, default is ISO
    my $date_format = $self->_cfg->application->{dateformat} || 'iso';

    # my $cfgdeps = $self->scrcfg($page)->dependencies;

    foreach my $field ( keys %{ $cfg_ref->main_table_columns } ) {

        # Skip field if not in record or not dependent
        next
            unless ( exists $record->{$field}
                         # or $self->is_dependent( $field, $cfgdeps )
                 );

        my $fldcfg = $cfg_ref->main_table_column($field);

        my $value = $record->{$field};
        # Defaults in columns config?
        # || ( $self->_model->is_mode('add') ? $fldcfg->{default} : undef );

        # # Process dependencies
        my $state;
        # if (exists $cfgdeps->{$field} ) {
        #     $state = $self->dependencies($field, $cfgdeps, $record);
        # }

        if (defined $value) {
            $value = decode( 'utf8', $value ) unless is_utf8($value);

            # Trim spaces and '\n' from the end
            $value = Tpda3::Utils->trim($value);

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

=cut

sub ctrl_write_to {
    my ($self, $field, $value, $state, $date_format) = @_;

    my $ctrltype = $self->scrcfg()->main_table_column($field)->{ctrltype};

    my $sub_name = qq{control_write_$ctrltype};
    if ( $self->_view->can($sub_name) ) {
        my $control_ref = $self->scrobj()->get_controls($field);
        $self->_view->$sub_name($control_ref, $value, $state, $date_format);
    }
    else {
        print "WW: No '$ctrltype' ctrl type for writing '$field'!\n";
    }

    return;
}

=head2 make_empty_record

Make empty record, used for clearing the screen.

=cut

sub make_empty_record {
    my $self = shift;

    my $page    = $self->_view->get_nb_current_page();
    my $cfg_ref = $self->scrcfg($page);

    my $record = {};
    foreach my $field ( keys %{ $cfg_ref->main_table_columns } ) {
        $record->{$field} = undef;
    }

    return $record;
}

# sub is_dependent {
#     my ( $self, $field, $depcfg ) = @_;

#     return exists $depcfg->{$field};
# }

# sub dependencies {
#     my ($self, $field, $depcfg, $record) = @_;

#     my $depon_field = $depcfg->{$field}{depends_on};
#     # print "  '$field' depends on '$depon_field'\n";

#     $self->control_read_e($depon_field);
#     my $depon_value = $self->{_scrdata}{$depon_field};

#     # print "  depon_value is $depon_value\n";
#     unless ($depon_value) {
#         $depon_value = $record->{$depon_field} || q{};
#     }

#     my $value_dep = $depcfg->{$field}{condition}{value_dep};
#     my $value_set = $depcfg->{$field}{condition}{value_set};
#     my $state_set = $depcfg->{$field}{condition}{state_set};

#     # print "  value_dep = '$value_dep'\n";
#     # print "  value_set = '$value_set'\n";
#     # print "  state_set = '$state_set'\n";

#     $value_dep       = Tpda3::Utils->trim($value_dep);
#     $depon_value = Tpda3::Utils->trim($depon_value);

#     my $ctrl_state;
#     if ( $value_dep eq $depon_value ) {
#         $ctrl_state = $state_set;
#     }
#     else {
#         $ctrl_state = $depcfg->{$field}{default};
#     }

#     return $ctrl_state;
# }

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

    my $answer = $self->ask_to_save;    # if $self->_model->is_modified;
    if ( !defined $answer ) {
        $self->_view->get_toolbar_btn('tb_fm')->deselect;
        return;
    }

    $self->_model->is_mode('find')
        ? $self->set_app_mode('idle')
        : $self->set_app_mode('find');

    $self->_view->set_status( '', 'ms' );    # clear messages

    return;
}

=head2 toggle_mode_add

Toggle add mode, ask to save record if modified.

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
    my ( $self, $set_state ) = @_;

    $self->_log->trace("Screen 'rec' controls state is '$set_state'");

    my $page = $self->_view->get_nb_current_page();
    my $bg   = $self->scrobj($page)->get_bgcolor();

    my $ctrl_ref = $self->scrobj($page)->get_controls();
    return unless scalar keys %{$ctrl_ref};

    my $control_states = $self->control_states($set_state);

    return unless defined $self->scrcfg($page);

    foreach my $field ( keys %{ $self->scrcfg($page)->main_table_columns } ) {
        my $fld_cfg = $self->scrcfg($page)->main_table_column($field);

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
        $bg_color = $bg if $bg_color =~ m{bg|bground|background};

        # Configure controls
        my $control = $self->scrobj()->get_controls($field)->[1];
        $self->_view->configure_controls($control, $state, $bg_color, $fld_cfg);
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
    my ( $self, $pk_val, $fk_val ) = @_;

    $self->screen_set_pk_val($pk_val);    # save PK value
    $self->screen_set_fk_val($fk_val) if defined $fk_val;    # and FK value

    $self->tmatrix_set_selected();    # initialize selector

    $self->record_load();

    if ( $self->_model->is_loaded ) {
        $self->_view->set_status(
            $self->localize( 'status', 'info-rec-load-r' ),
            'ms', 'blue' );
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

    $self->_view->set_status( $self->localize( 'status', 'info-rec-reload' ),
        'ms', 'blue' );

    $self->_model->set_scrdata_rec(0);    # false = loaded,  true = modified,
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

    my $page = $self->_view->get_nb_current_page();

    #-  Main table
    my $params = $self->main_table_metadata('qry');

    my $record = $self->_model->query_record($params);
    my $textstr = 'Empty record';
    $self->_view->status_message("error#$textstr")
        if scalar keys %{$record} <= 0;

    $self->screen_write($record);

    #- Dependent table(s), (if any)

    foreach my $tm_ds ( keys %{ $self->scrobj($page)->get_tm_controls() } ) {
        my $tm_params = $self->dep_table_metadata( $tm_ds, 'qry' );

        my $records = $self->_model->table_batch_query($tm_params);

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

    $self->_model->set_scrdata_rec(0);    # false = loaded,  true = modified,
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

    $self->list_update_remove();    # first remove from list

    $self->record_delete();

    $self->_view->set_status( $self->localize( 'status', 'info-deleted' ),
        'ms', 'darkgreen' );    # removed

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

    $self->_model->prepare_record_delete( \@record );

    $self->set_app_mode('idle');

    $self->_model->unset_scrdata_rec();    # false = loaded,  true = modified,
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

    $self->screen_set_pk_val();

    $self->_model->unset_scrdata_rec();    # false = loaded,  true = modified,
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

    return 0 if !$self->is_record;

    if (   $self->_model->is_mode('edit')
        or $self->_model->is_mode('add') )
    {
        if ( $self->record_changed ) {
            my $answer = $self->ask_to('save');

            if ( $answer eq 'yes' ) {
                $self->record_save();
            }
            elsif ( $answer eq 'no' ) {
                $self->_view->set_status(
                    $self->localize( 'status', 'not-saved' ),
                    'ms', 'blue' );
            }
            else {
                $self->_view->set_status(
                    $self->localize( 'status', 'canceled' ),
                    , 'ms', 'blue' );
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
        $message = $self->localize('dialog','msg-sav');
        $details = $self->localize('dialog','det-sav');
    }
    elsif ( $for_action eq 'save_insert' ) {
        $message = $self->localize('dialog','msg-add');
        $details = $self->localize('dialog','det-add');
    }
    elsif ( $for_action eq 'delete' ) {
        $message = $self->localize('dialog','msg-del');
        $details = $self->localize('dialog','det-del');
    }

    # Message dialog
    return $self->_view->dialog_confirm($message, $details);
}

=head2 record_save

Save record.  Different procedures for different modes.

First, check if required data present in screen.

=cut

sub record_save {
    my $self = shift;

    if ( $self->_model->is_mode('add') ) {

        my $record = $self->get_screen_data_record('ins');

        return if !$self->if_check_required_data($record);

        my $answer = $self->ask_to('save_insert');

        return if $answer eq 'cancel' or $answer eq 'no';

        if ($answer eq 'yes') {
            my $pk_val = $self->record_save_insert($record);
            if ($pk_val) {
                $self->record_reload();
                $self->list_update_add(); # insert the new record in the list
                $self->_view->set_status(
                    $self->localize( 'status', 'info-saved' ),
                    , 'ms', 'darkgreen' );
            }
        }
        else {
            $self->_view->set_status(
                $self->localize( 'status', 'canceled' ),
                , 'ms', 'orange' );
        }
    }
    elsif ( $self->_model->is_mode('edit') ) {
        if ( !$self->is_record ) {
            $self->_view->set_status(
                $self->localize( 'status', 'empty-record' ),
                'ms', 'orange' );
            return;
        }

        my $record = $self->get_screen_data_record('upd');

        return if !$self->if_check_required_data($record);

        $self->_model->prepare_record_update($record);
        $self->_view->set_status( $self->localize( 'status', 'info-saved' ),
            'ms', 'darkgreen' );
    }
    else {
        $self->_view->set_status( $self->localize( 'status', 'not-editadd' ),
            'ms', 'darkred' );
        return;
    }

    # Save record as witness reference for comparison
    $self->save_screendata( $self->storable_file_name('orig') );

    $self->_model->set_scrdata_rec(0);    # false = loaded,  true = modified,
                                          # undef = unloaded

    $self->toggle_detail_tab;

    return;
}

=head2 if_check_required_data

Check if required data is present in the screen.

There are two list used in this method, the list of the non empty
fields from the screen and the list of the fields that require to have
a value.

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

sub if_check_required_data {
    my ($self, $record) = @_;

    unless ( scalar keys %{ $record->[0]{data} } > 0 ) {
        $self->_view->set_status( $self->localize( 'status', 'empty-record' ),
            'ms', 'darkred' );
        return 0;
    }

    my $ok_to_save = 1;

    my $ctrl_req = $self->scrobj('rec')->get_rq_controls();
    if ( !scalar keys %{$ctrl_req} ) {
        my $warn_str = 'WW: Unimplemented screen data check in '
            . ucfirst $self->screen_string('rec');
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
            #$self->_view->set_status( "$cond_field field?", 'ms', 'darkred' );
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
        my $message = $self->localize( 'dialog', 'info-add' );
        my $details = join( "\n", @message );
        $self->_view->dialog_info($message, $details);
    }

    return $ok_to_save;
}

=head2 record_save_insert

Insert record.

=cut

sub record_save_insert {
    my ( $self, $record ) = @_;

    my $pk_val = $self->_model->prepare_record_insert($record);

    if ($pk_val) {
        my $pk_col = $record->[0]{metadata}{pkcol};
        $self->screen_write( { $pk_col => $pk_val } );
        $self->set_app_mode('edit');
        $self->screen_set_pk_val($pk_val);    # save PK value
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

    $self->_view->list_populate( [ \@list ] );    # AoA

    return;
}

=head2 list_update_remove

Compare the selected row in the I<List> with given Pk and optionally Fk
values and remove it.

=cut

sub list_update_remove {
    my $self = shift;

    my $pk_val = $self->screen_get_pk_val();
    my $fk_val = $self->screen_get_fk_val();

    $self->_view->list_remove_selected( $pk_val, $fk_val );

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
        $self->_view->set_status( $self->localize( 'status', 'err-chkchanged' ),
            'ms', 'orange' );
        die "Can't find saved data for comparison!";
    }

    my $witness = retrieve($witness_file);

    my $record = $self->get_screen_data_record('upd');

    return $self->_model->record_compare( $witness, $record );
}

=head2 take_note

Save record to a temporary file on disk.  Can be restored into a new
record.  An easy way of making multiple records based on a template.

=cut

sub take_note {
    my $self = shift;

    my $msg
        = $self->save_screendata( $self->storable_file_name )
        ? $self->localize( 'status', 'info-note-take' )
        : $self->localize( 'status', 'error-note-take' );

    $self->_view->set_status( $msg, 'ms', 'blue' );

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
        ? $self->localize( 'status', 'info-note-rest' )
        : $self->localize( 'status', 'error-note-rest' );

    $self->_view->set_status( $msg, 'ms', 'blue' );

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
        = catfile( $self->_cfg->configdir,
        $self->scrcfg->screen_name . $suffix . q{.dat},
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
    while ( my ( $field, $value ) = each( %{ $self->{_scrdata} } ) ) {
        $record->{data}{$field} = $value;
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

    #- Get PK field name and value and FK if exists
    my $pk_col = $self->screen_get_pk_col;
    my $pk_val = $self->screen_get_pk_val;
    my ( $fk_col, $fk_val );

    # my $has_dep = 0;
    # if ($self->scrcfg->screen->{style} eq 'dependent') {
    #     $has_dep = 1;
    $fk_col = $self->screen_get_fk_col;
    $fk_val = $self->screen_get_fk_val;

    # }

    if ( $for_sql eq 'qry' ) {
        $metadata->{table} = $self->scrcfg->main_table_view;
        $metadata->{where}{$pk_col} = $pk_val;    # pk
        $metadata->{where}{$fk_col} = $fk_val if $fk_col and $fk_val;
    }
    elsif ( ( $for_sql eq 'upd' ) or ( $for_sql eq 'del' ) ) {
        $metadata->{table} = $self->scrcfg->main_table_name;
        $metadata->{where}{$pk_col} = $pk_val;    # pk
        $metadata->{where}{$fk_col} = $fk_val if $fk_col and $fk_val;
    }
    elsif ( $for_sql eq 'ins' ) {
        $metadata->{table} = $self->scrcfg->main_table_name;
        $metadata->{pkcol} = $pk_col;
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
    my ( $self, $tm_ds, $for_sql ) = @_;

    my $metadata = {};

    #- Get PK field name and value
    my $pk_col = $self->screen_get_pk_col;
    my $pk_val = $self->screen_get_pk_val;

    if ( $for_sql eq 'qry' ) {
        $metadata->{table} = $self->scrcfg->dep_table_view($tm_ds);
        $metadata->{where}{$pk_col} = $pk_val;    # pk
    }
    elsif ( $for_sql eq 'upd' or $for_sql eq 'del' ) {
        $metadata->{table} = $self->scrcfg->dep_table_name($tm_ds);
        $metadata->{where}{$pk_col} = $pk_val;    # pk
    }
    elsif ( $for_sql eq 'ins' ) {
        $metadata->{table} = $self->scrcfg->dep_table_name($tm_ds);
    }
    else {
        die "Bad parameter: $for_sql";
    }

    my $columns = $self->scrcfg->dep_table_columns($tm_ds);

    $metadata->{pkcol}    = $pk_col;
    $metadata->{fkcol}    = $self->scrcfg->dep_table_fkcol($tm_ds);
    $metadata->{order}    = $self->scrcfg->dep_table_orderby($tm_ds);
    $metadata->{colslist} = Tpda3::Utils->sort_hash_by_id($columns);
    $metadata->{updstyle} = $self->scrcfg->dep_table_updatestyle($tm_ds);

    return $metadata;
}

=head2 report_table_metadata

Retrieve table meta-data for report screen style configurations from
the screen configuration.

=cut

sub report_table_metadata {
    my ( $self, $tm_ds, $level ) = @_;

    my $metadata = {};

    # DataSourceS meta-data
    my $dss    = $self->scrcfg->dep_table_datasources($tm_ds);
    my $cntcol = $self->scrcfg->dep_table_rowcount($tm_ds);
    my $table  = $dss->{level}[$level]{table};
    my $pkcol  = $dss->{level}[$level]{pkcol};

    # DataSource meta-data by column
    my $ds = $self->scrcfg->dep_table_columns_by_level($tm_ds, $level);

    my @datasource = grep { m/^[^=]/ } keys %{$ds};
    my @tables = uniq @datasource;
    if (scalar @tables == 1) {
        $metadata->{table} = $tables[0];
    }
    else {
        # Wrong datasources config for level $level?
        return;
    }

    $metadata->{pkcol}     = $pkcol;
    $metadata->{colslist}  = $ds->{$tables[0]};
    $metadata->{rowcount} = $cntcol;
    push @{ $metadata->{colslist} }, $pkcol;  # add PK to cols list

    return $metadata;
}

=head2 get_table_sumup_cols

Return table C<sumup> cols.

=cut

sub get_table_sumup_cols {
    my ( $self, $tm_ds, $level ) = @_;

    my $metadata = $self->scrcfg->dep_table_columns_by_level($tm_ds, $level);

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
        die 'ERR: Unknown PK column name!';
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
        die 'Unknown PK column name!';
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

=head2 flatten_cfg

TODO

=cut

sub flatten_cfg {
    my ( $self, $level, $attribs ) = @_;

    my %flatten;
    while ( my ( $key, $value ) = each( %{$attribs} ) ) {
        if ( ref $value eq 'HASH' ) {
            $flatten{$key} = $value->{"level$level"};
        }
        else {
            $flatten{$key} = $value;
        }
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

    my $dir = $self->_cfg->configdir;
    my @files = glob("$dir/*.dat");

    foreach my $file (@files) {
        if ( -f $file ) {
            my $cnt = unlink $file;
            if ( $cnt == 1 ) {
                # print "Cleanup: $file\n";
            }
            else {
                $self->_log->error("EE, cleaning up: $file");
            }
        }
    }
}

=head2 on_quit

Close application.

=cut

sub on_quit {
    my $self = shift;

    print "Shuting down...\n";

    $self->_view->on_close_window(@_);
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Controller
