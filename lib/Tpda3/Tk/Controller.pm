package Tpda3::Tk::Controller;

use strict;
use warnings;

use Data::Dumper;
use Carp;

use Tk;
use Tk::DialogBox;

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

=item _rscrcls  - class name of the current I<record> screen

=item _rscrobj  - current I<record> screen object

=item _rscrcfg  - current  I<record> screen config object

=item _dscrcls  - class name of the current I<detail> screen

=item _dscrobj  - current I<detail> screen object

=item _dscrcfg  - current I<detail> screen config object

=item _tblkeys  - primary and foreign keys and values record

=item _scrdata  - current screen data

=item _tm_sel   - TableMatrix selected row

=back

=cut

sub new {
    my $class = shift;

    my $model = Tpda3::Model->new();

    my $view = Tpda3::Tk::View->new(
        $model,
    );

    my $self = {
        _model    => $model,
        _app      => $view,                       # an alias as for Wx ...
        _view     => $view,
        _rscrcls  => undef,
        _rscrobj  => undef,
        _rscrcfg  => undef,
        _dscrcls  => undef,
        _dscrobj  => undef,
        _dscrcfg  => undef,
        _tblkeys  => undef,
        _scrdata  => undef,
        _tm_sel   => undef,
        _cfg      => Tpda3::Config->instance(),
        _log      => get_logger(),
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

Check if we have user and pass, if not, show dialog.  Connect to
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
            return if ! defined $self->ask_to_save;
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
            my $scr_name = $self->screen_string('rec') || 'main';
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
            my $scr_name = $self->screen_string('rec') || 'main';
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
            $self->toggle_mode_add() if $self->{_rscrcls};
        }
    );

    #-- Delete
    $self->_view->get_toolbar_btn('tb_rm')->bind(
        '<ButtonRelease-1>' => sub {
            $self->record_delete();
        }
    );

    #-- Save record
    $self->_view->get_toolbar_btn('tb_sv')->bind(
        '<ButtonRelease-1>' => sub {
            $self->record_save();
        }
    );

    #-- Quit
    $self->_view->get_toolbar_btn('tb_qt')->bind(
        '<ButtonRelease-1>' => sub {
            return if ! defined $self->ask_to_save;
            $self->_view->on_quit;
        }
    );

    #-- Make some key bindings

    $self->_view->bind(
        '<Control-q>' => sub {
            return if ! defined $self->ask_to_save;
            $self->_view->on_quit
        }
    );
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
            $self->toggle_mode_find()
              if $self->{_rscrcls} and !$self->_model->is_mode('add');
        }
    );
    $self->_view->bind(
        '<F8>' => sub {
            ( $self->{_rscrcls} and $self->_model->is_mode('find') )
              ? $self->record_find_execute
              : $self->_view->set_status( 'Not find mode', 'ms', 'orange' );
        }
    );
    $self->_view->bind(
        '<F9>' => sub {
            ( $self->{_rscrcls} and $self->_model->is_mode('find') )
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
                $self->on_page_lst_activate;
            }
            elsif ($page eq 'rec') {
                $self->on_page_rec_activate;
            }
            elsif ($page eq 'det') {
                $self->on_page_det_activate;
            }

            $self->_view->set_status('','ms'); # clear status message
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

=head2 toggle_detail_tab

Toggle state of the 'I<det>.

Search for TableMatrix with selector col configured and if the number
of data rows is greater then zero, disable, else enable the I<Detail>
tab.

=cut

sub toggle_detail_tab {
    my $self = shift;

    my $nbk = $self->_view->get_notebook();
    my $sel = $self->tmatrix_get_selected;

    if ( $sel and !$self->_model->is_modified ) {
        $nbk->pageconfigure( 'det', -state => 'normal' );
    }
    else {
        $nbk->pageconfigure( 'det', -state => 'disabled' );
    }

    return;
}

=head2 on_page_rec_activate

On page I<rec> activate.

=cut

sub on_page_rec_activate {
    my $self = shift;

    my $pk_val_new = $self->_view->list_read_selected();
    if ( ! defined $pk_val_new ) {
        $self->_view->set_status('Nothing selected','ms','orange');
        return;
    }

    my $pk_val_old = $self->screen_get_pk_val() || q{}; # empty for eq

    if ($pk_val_new eq $pk_val_old) {
        $self->set_app_mode('edit'); # restore interface state
    }
    else {
        $self->set_app_mode('edit');
        $self->record_load_new($pk_val_new);
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
    $self->_view->get_recordlist->focus;

    return;
}

=head2 on_page_det_activate

On page I<det> activate.

=cut

sub on_page_det_activate {
    my $self = shift;

    my $dsm = $self->screen_detail_name();

    # Check if detail screen module is loaded and load it if it's not
    if ($dsm) {
        $self->screen_detail_load($dsm);
    }
    else {
        $self->_view->get_notebook()->raise('rec');
        print "Not selected\n";
        return;
    }

    $self->get_selected_and_set_fk_val;

    # Load detail record
    $self->record_load();

    $self->_view->set_status('Record loaded (d)','ms','blue');
    $self->set_app_mode('edit');
    # $self->_model->set_scrdata_rec(q{});    # empty

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

Read the selected row from TableMatrix widget and get the foreign key
value designated by the I<filter> configuration value of the screen.

Save the foreign key value.

The default selector table is I<tm1>.

=cut

sub get_selected_and_set_fk_val {
    my $self = shift;

    my $row = $self->tmatrix_get_selected;

    return unless defined $row and $row > 0;

    # Detail screen module name from config
    my $screen = $self->scrcfg('rec')->screen_detail;

    my $params = $self->tmatrix_read_cell($row, $screen->{filter}, 'tm1');

    my $fk_col = $self->screen_get_fk_col;
    my $fk_val = $params->{$fk_col};

    $self->screen_set_fk_val($fk_val);

    return;
}

=head2 screen_detail_load

Check if the detail screen module is loaded, and load if it's not.

=cut

sub screen_detail_load {
    my ($self, $dsm) = @_;

    my $dscrstr = $self->screen_string('det');

    if ( $dscrstr && ( $dscrstr eq lc $dsm ) ) {
        print "Already loaded ($dsm)\n";
    }
    else {
        print "Loading detail ($dsm)\n";
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
    my ($self, $detscr) = @_;

    my $row = $self->tmatrix_get_selected;

    return unless defined $row and $row > 0;

    my $col_name  = $detscr->{match};
    my $rec = $self->tmatrix_read_cell($row, $col_name, 'tm1');
    my $col_value = $rec->{$col_name};

    my @dsm = grep { $_->{value} eq $col_value } @{$detscr->{detail}};

    return $dsm[0]{name};
}

=head2 _set_event_handler_screen

Setup event handlers for the I<add> and I<delete> buttons attached to
the TableMatrix widget.

TODO: Where to configure what to do and how to make this bindings
configurable?

=cut

sub _set_event_handler_screen {
    my ($self, $tm_ds) = @_;

    # Get ToolBar button atributes
    my $attribs = $self->scrcfg->dep_table_toolbars($tm_ds);

    return if not ref $attribs;

    $self->_log->trace("Setup event handler for TM buttons");

    #- screen ToolBar

    #-- Add row button
    $self->scrobj('rec')->get_toolbar_btn('tb2ad')->bind(
        '<ButtonRelease-1>' => sub {
            $self->tmatrix_add_row($tm_ds);
        }
    );

    #-- Remove row button
    $self->scrobj('rec')->get_toolbar_btn('tb2rm')->bind(
        '<ButtonRelease-1>' => sub {
            $self->tmatrix_remove_row($tm_ds);
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

Only for I<menu_user> hardwired menu name for now!

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
    my ($self, $page) = @_;

    my $dict     = Tpda3::Lookup->new;
    my $ctrl_ref = $self->scrobj('rec')->get_controls();

    my $bindings = $self->scrcfg('rec')->bindings;

    $self->_log->info("Setup binding for configured widgets ($page)");

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
        my $field_cfg = $self->scrcfg('rec')->main_table_column($column);
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
                  $self->fields_cfg_one($bindings->{$bind_name} );
                last SWITCH;
            };
            /array/i && do {
                $flds = $self->fields_cfg_many($bindings->{$bind_name} );
                last SWITCH;
            };
            /hash/i  && do {
                $flds = $self->fields_cfg_named($bindings->{$bind_name} );
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
                $self->screen_write($record, 'fields' );
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

    foreach my $tm_ds ( keys %{ $self->scrobj('rec')->get_tm_controls } ) {

        my $bindings = $self->scrcfg('rec')->tablebindings->{$tm_ds};

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
        my $tm = $self->scrobj('rec')->get_tm_controls($tm_ds);
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
        my $col = $self->scrcfg('rec')->dep_table_column_attr($tm_ds,$fld,'id');
        $filter = $self->tmatrix_read_cell($r, $col);
    }

    my $dict   = Tpda3::Lookup->new;
    my $record = $dict->lookup( $self->_view, $lk_para, $filter );

    $self->tmatrix_write_row( $r, $c, $record, $tm_ds );

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
    if ( $self->{scrobj('rec')}->can($method) ) {
        $self->{scrobj('rec')}->$method($r);
        #$self->{scrobj('rec')}->calculate_order_line($r);
    }
    else {
        print "WW: '$method' not implemented!\n";
    }

    return 1;                   # skip_cols
}

=head2 get_lookup_setings

Return the data structure used by the L<Tpda3::Tk::Dialog::Search>
module.  Uses the I<tablebindings> section of the screen configuration
and the related field attributes from the I<dep_table> section.

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
    my $field_cfg = $self->scrcfg('rec')->dep_table_column($tm_ds, $column);

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
            $flds = $self->fields_cfg_one($bindings, $tm_ds);
            last SWITCH;
        };
        /array/i && do {
            $flds = $self->fields_cfg_many($bindings, $tm_ds);
            last SWITCH;
        };
        /hash/i  && do {
            $flds = $self->fields_cfg_named($bindings, $tm_ds);
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
    my ( $self, $bindings, $tm_ds ) = @_;

    # One field, no array
    my @cols;
    my $lookup = $bindings->{field};
    my $field_cfg;
    if ($tm_ds) {
        $field_cfg = $self->scrcfg('rec')->dep_table_column($tm_ds, $lookup);
    }
    else {
        $field_cfg = $self->scrcfg('rec')->main_table_column($lookup);
    }
    my $rec = {};
    $rec->{$lookup} = {
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
    my ( $self, $bindings, $tm_ds ) = @_;

    my @cols;

    # Multiple fields returned as array
    foreach my $lookup_field ( @{ $bindings->{field} } ) {
        my $field_cfg;
        if ($tm_ds) {
            $field_cfg = $self->scrcfg('rec')->dep_table_column($tm_ds, $lookup_field);
        }
        else {
            $field_cfg = $self->scrcfg('rec')->main_table_column($lookup_field);
        }
        my $rec = {};
        $rec->{$lookup_field} = {
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
    my ( $self, $bindings, $tm_ds ) = @_;

    my @cols;
    # Multiple fields returned as array
    foreach my $lookup_field ( keys %{ $bindings->{field} } ) {
        my $scr_field = $bindings->{field}{$lookup_field}{name};
        my $field_cfg;
        if ($tm_ds) {
            $field_cfg = $self->scrcfg('rec')->dep_table_columns($tm_ds, $scr_field);
        }
        else {
            $field_cfg = $self->scrcfg('rec')->main_table_column($scr_field);
        }

        my $rec = {};
        $rec->{$lookup_field} = {
            width => $field_cfg->{width},
            label => $field_cfg->{label},
            order => $field_cfg->{order},
            name  => $scr_field,
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

    return unless ref $self->scrobj('rec');

    $self->toggle_screen_interface_controls;

    if ( my $method_name = $self->{method_for}{$mode} ) {
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
        $self->tmatrix_clear($tm_ds);
    }

    $self->controls_state_set('off');

    my $nb = $self->_view->get_notebook();
    $nb->pageconfigure('det', -state => 'disabled');
    $nb->pageconfigure('lst', -state => 'normal');

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

    $self->record_clear;

    foreach my $tm_ds ( keys %{ $self->scrobj('rec')->get_tm_controls() } ) {
        $self->tmatrix_clear($tm_ds);
    }

    $self->controls_state_set('edit');

    my $nb = $self->_view->get_notebook();
    $nb->pageconfigure('lst', -state => 'disabled');
    $nb->pageconfigure('det', -state => 'disabled');

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
        $self->tmatrix_clear($tm_ds);
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

    my $nb = $self->_view->get_notebook();
    # $nb->pageconfigure('det', -state => 'normal');
    $nb->pageconfigure('lst', -state => 'normal');

    return;
}

=head2 on_screen_mode_sele

Noting to do here.

=cut

sub on_screen_mode_sele {
    my $self = shift;

    my $nb = $self->_view->get_notebook();
    $nb->pageconfigure('det', -state => 'disabled');

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

=head2 scrcfg

Return current screen configuration object.

=cut

sub scrcfg {
    my ($self, $page) = @_;

    $page ||= $self->_view->get_nb_current_page();

    return $self->{_rscrcfg} if $page eq 'rec';

    return $self->{_dscrcfg} if $page eq 'det';

    warn "Wrong page: $page!\n";

    return;
}

=head2 scrobj

Return current screen object reference, or the object reference from
the required page.

=cut

sub scrobj {
    my ($self, $page) = @_;

    $page ||= $self->_view->get_nb_current_page();

    return $self->{_rscrobj} if $page eq 'rec';

    return $self->{_dscrobj} if $page eq 'det';

    warn "Wrong page: $page!\n";

    return;
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

    my $rscrstr = lc $module;

    # Load the new screen configuration
    $self->{_rscrcfg} = Tpda3::Config::Screen->new();
    $self->{_rscrcfg}->config_screen_load($rscrstr);

    # Destroy existing NoteBook widget
    $self->_view->destroy_notebook();

    # Unload current screen
    if ( $self->{_rscrcls} ) {
        Class::Unload->unload( $self->{_rscrcls} );

        if ( ! Class::Inspector->loaded( $self->{_rscrcls} ) ) {
            $self->_log->trace("Unloaded '$self->{_rscrcls}' screen");
        }
        else {
            $self->_log->trace("Error unloading '$self->{_rscrcls}' screen");
        }
    }

    my $has_det = $self->scrcfg('rec')->has_screen_detail;

    # Make new NoteBook widget and setup callback
    $self->_view->create_notebook($has_det);
    $self->_set_event_handler_nb('rec');
    $self->_set_event_handler_nb('lst');
    $self->_set_event_handler_nb('det') if $has_det;

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
    $self->{_rscrobj} = $class->new( $self->{_rscrcfg} );
    $self->_log->trace("New screen instance: $module");

    # Show screen
    my $nb = $self->_view->get_notebook();
    $self->{_rscrobj}->run_screen( $nb, $self->{_rscrcfg} );

    # Store currently loaded screen class
    $self->{_rscrcls} = $class;

    # Load instance config
    $self->_cfg->config_load_instance();

    #-- Lookup bindings for Tk::Entry widgets
    $self->setup_lookup_bindings_entry('rec');

    #-- Lookup bindings for tables (TableMatrix)
    $self->setup_bindings_table();

    # Set PK column name
    $self->screen_set_pk_col();

    # Update window geometry
    $self->update_geometry();

    $self->set_app_mode('idle');

    # List header
    my @header_cols = @{ $self->scrcfg('rec')->found_cols->{col} };
    my $fields = $self->scrcfg('rec')->main_table_columns;
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
    foreach my $tm_ds ( keys %{ $self->scrobj('rec')->get_tm_controls() } ) {
        my $tmx    = $self->scrobj('rec')->get_tm_controls($tm_ds);
        my $fields = $self->scrcfg('rec')->dep_table_columns($tm_ds);
        my $strech = $self->scrcfg('rec')->dep_table_colstretch($tm_ds);
        my $sc     = $self->scrcfg('rec')->dep_table_has_selectorcol($tm_ds);
        $self->_view->make_tablematrix_header( $tmx, $fields, $strech, $sc );

        # Event handlers
        $self->set_event_handler_screen($tm_ds);
    }

    # Load lists into JBrowseEntry or JComboBox widgets
    $self->screen_init();

    $self->_set_menus_enable('normal');

    $self->_view->set_status('','ms');

    $self->_model->unset_scrdata_rec();

    return 1;                       # to make ok from Test::More happy
                                    # probably missing something :) TODO!
}

=head2 set_event_handler_screen

Setup event handlers for the I<add> and I<delete> buttons attached to
the TableMatrix widget.

TODO: Where to configure what to do and how to make this bindings
configurable?

=cut

sub set_event_handler_screen {
    my ($self, $tm_ds) = @_;

    # Get ToolBar button atributes
    my $attribs = $self->scrcfg->dep_table_toolbars($tm_ds);

    foreach my $tb_btn (keys %{$attribs}) {
        my $method = $attribs->{$tb_btn}{method};
        $self->_log->info("Handler for $tb_btn: $method ($tm_ds)");

        # Check current screen for method for binding
        my $obj;
        if ( $self->scrobj('rec')->can($method) ) {
            $obj = $self->scrobj('rec');
        }
        else {
            # Fallback to $self
            $obj = $self;
        }

        $self->scrobj('rec')->get_toolbar_btn($tm_ds, $tb_btn)->bind(
            '<ButtonRelease-1>' => sub {
                $obj->$method($tm_ds);
            }
        );
    }

    return;
}

=head2 screen_module_detail_load

Load detail screen.

=cut

sub screen_module_detail_load {
    my ( $self, $module ) = @_;

    my $dscrstr = lc $module;

    # Load the new screen configuration
    $self->{_dscrcfg} = Tpda3::Config::Screen->new();
    $self->{_dscrcfg}->config_screen_load($dscrstr);

    $self->_view->notebook_page_clean('det');

    # Unload current screen
    if ( $self->{_dscrcls} ) {
        Class::Unload->unload( $self->{_dscrcls} );

        if ( ! Class::Inspector->loaded( $self->{_dscrcls} ) ) {
            $self->_log->info("Unloaded '$self->{_dscrcls}' screen");
        }
        else {
            $self->_log->info("Error unloading '$self->{_dscrcls}' dscreen");
        }
    }

    # $self->_set_event_handler_nb('det');

    my ($class, $module_file) = $self->screen_module_class($module);
    eval {require $module_file };
    if ($@) {
        croak "EE: Can't load '$module_file'\n";
    }

    unless ($class->can('run_screen') ) {
        my $msg = "Error! Screen '$class' can not 'run_screen'";
        print "$msg\n";
        $self->_log->error($msg);

        return;
    }

    # New screen instance
    $self->{_dscrobj} = $class->new();
    $self->_log->trace("New screen instance: $module");

    # Show screen
    my $nb = $self->_view->get_notebook();
    $self->{_dscrobj}->run_screen( $nb, $self->{_dscrcfg} );

    # Store currently loaded screen class
    $self->{_dscrcls} = $class;

    # Event handlers

    #-- Lookup bindings for Tk::Entry widgets
    # $self->setup_lookup_bindings_entry('det');

    #-- Lookup bindings for tables (TableMatrix)
    # $self->setup_bindings_table();

    # # TableMatrix header(s), if any
    # foreach my $tm_ds ( keys %{ $self->_screen->get_tm_controls() } ) {
    #     my $tmx = $self->_screen->get_tm_controls($tm_ds);
    #     my $tm_fields = $self->_rscrcfg->dep_table->{$tm_ds}{columns};
    #     $self->_view->make_tablematrix_header( $tmx, $tm_fields );
    # }

    # # Load lists into JBrowseEntry or JComboBox widgets
    # $self->screen_init();

#    $self->_view->set_status('','ms');

    # Set FK column name
    $self->screen_set_fk_col();

    return;
}

sub screen_string {
    my ($self, $page) = @_;

    $page ||= $self->_view->get_nb_current_page();

    my $module;
    if ($page eq 'rec') {
        $module = $self->{_rscrcls};
    }
    elsif ($page eq 'det') {
        $module = $self->{_dscrcls} || q{}; # empty
    }
    else {
        print "WW: screen_string called with page '$page'\n";
        return;
    }

    my $scrstr = ( split /::/, $module )[-1] || q{}; # or nothing

    return lc $scrstr;
}

=head2 update_geometry

Update window geometry from instance config if exists or from
defaults.

=cut

sub update_geometry {
    my $self = shift;

    my $geom;
    if ( $self->_cfg->can('geometry') ) {
        $geom = $self->_cfg->geometry->{ $self->screen_string('rec') };
        unless ($geom) {
            $geom = $self->scrcfg('rec')->screen->{geometry};
        }
    }
    else {
        $geom = $self->scrcfg('rec')->screen->{geometry};
    }
    $self->_view->set_geometry($geom);
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
    my $ctrl_ref = $self->scrobj('rec')->get_controls();
    return unless scalar keys %{$ctrl_ref};

    foreach my $field ( keys %{ $self->scrcfg('rec')->main_table_columns } ) {

        # Control config attributes
        my $fld_cfg  = $self->scrcfg('rec')->main_table_column($field);
        my $ctrltype = $fld_cfg->{ctrltype};
        my $ctrlrw   = $fld_cfg->{rw};

        next unless $ctrl_ref->{$field}[0]; # Undefined widget variable

        my $para = $self->scrcfg('rec')->{lists}{$field};

        next unless ref $para eq 'HASH';   # Undefined, skip

        # Query table and return data to fill the lists
        my $cod_a_ref = $self->{_model}->get_codes($field, $para);

        if ( $ctrltype eq 'm' ) {

            # JComboBox
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
the application, and different pages.

=cut

sub toggle_interface_controls {
    my $self = shift;

    my ($toolbars, $attribs) = $self->_view->toolbar_names();

    my $mode = $self->_model->get_appmode;
    my $page = $self->_view->get_nb_current_page();

    my $is_rec = $self->is_record('rec');

    foreach my $name ( @{$toolbars} ) {
        my $status = $attribs->{$name}{state}{$page}{$mode};

        #- Conditions

        unless ( $page eq 'lst' ) {

            #-- Take note button
            if ( $name eq 'tb_tn' and $self->{_rscrcls} ) {
                $status = 'normal' if $mode eq 'add';
                $status = 'disabled' unless $is_rec;
            }

            #-- Restore note
            if ( $name eq 'tb_tr' and $self->{_rscrcls} ) {
                my $data_file = $self->storable_file_name;
                $status =
                  $mode eq 'add'
                  ? 'normal'
                  : 'disabled';
                $status = 'disabled' if !-f $data_file;
            }
        }

        # Print preview
        # Activate only if default report configured for screen
        # if ( $name eq 'tb_pr' and $self->{_rscrcls} ) {
        #     $status = $self->_cfg->defaultreport
        #             ? 'normal'
        #             : 'disabled';
        # }

        #-- List tab
        $status = 'disabled' if $page eq 'lst';

        #- Set status for toolbar buttons

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

    my $page = $self->_view->get_nb_current_page();

    return if $page eq 'lst';

    foreach my $tm_ds ( keys %{ $self->scrobj($page)->get_tm_controls() } ) {

        # Get ToolBar button atributes
        my $attribs = $self->scrcfg->dep_table_toolbars($tm_ds);

        my $toolbars = Tpda3::Utils->sort_hash_by_id($attribs);

        my $mode = $self->_model->get_appmode;

        foreach my $name ( @{$toolbars} ) {
            my $status = $attribs->{$name}{state}{$page}{$mode};
            $self->scrobj($page)->enable_tool( $tm_ds, $name, $status );
        }
    }

    return;
}

=head2 screen_clear

Clear the screen: empty all controls.

=cut

sub screen_clear {
    my $self = shift;

    return unless ref $self->scrobj('rec');

    $self->record_clear;

    # Don't change mode if 'det' page
    my $page = $self->_view->get_nb_current_page();
    if ( $self->_model->is_mode('edit') ) {
        $self->set_app_mode('idle') unless $page eq 'det';
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
    my $main_table = $self->scrcfg('rec')->main_table;
    my $columns = $self->scrcfg('rec')->main_table_columns;

    my $params = {};

    # Columns data (for found list)
    $params->{columns} = $self->scrcfg('rec')->found_cols->{col};

    # Add findtype info to screen data
    while ( my ( $field, $value ) = each( %{$self->{_scrdata} } ) ) {
        my $findtype = $columns->{$field}{findtype};

        # Create a where clause like this:
        #  field1 IS [NOT] NULL and field2 IS [NOT] NULL
        # for entry values equal to '%' or '!'
        $findtype = q{isnull}  if $value eq q{%};
        $findtype = q{notnull} if $value eq q{!};

        $params->{where}{$field} = [ $value, $findtype ];
    }

    # Table data
    $params->{table} = $main_table->{view};   # use view instead of table
    $params->{pkcol} = $main_table->{pkcol}{name};

    my $ary_ref = $self->_model->query_records_find($params);

    $self->_view->list_init();
    my $record_count = $self->_view->list_populate($ary_ref);

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
    my $columns = $self->scrcfg('rec')->main_table_columns;

    my $params = {};

    # Add findtype info to screen data
    while ( my ( $field, $value ) = each( %{$self->{_scrdata} } ) ) {
        my $findtype = $columns->{$field}{findtype};
        $findtype = q{contains} if $value eq q{%}; # allow count by
                                                   # field contents
        $params->{where}{$field} = [ $value, $findtype ];
    }

    # Table data
    $params->{table} = $self->scrcfg('rec')->main_table_view;   # use view instead of table
    $params->{pkcol} = $self->scrcfg('rec')->main_table_pkcol;

    $self->_model->query_records_count($params);

    return;
}

=head2 screen_report_print

Printing report configured as default with Report Manager.

=cut

sub screen_report_print {
    my $self = shift;

    return unless ref $self->scrobj('rec');

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
     $self->{_scrdata} = {};

     my $scrobj = $self->scrobj; # current screen object
     my $scrcfg = $self->scrcfg; # current screen config

     my $ctrl_ref = $scrobj->get_controls();

     return unless scalar keys %{$ctrl_ref};

     # Scan and write to controls
     foreach my $field ( keys %{ $scrcfg->main_table_columns() } ) {
         my $fld_cfg = $scrcfg->main_table_column($field);

         # Control config attributes
         my $ctrltype = $fld_cfg->{ctrltype};
         my $ctrlrw   = $fld_cfg->{rw};

         # Skip READ ONLY fields if not FIND status
         # Read ALL if $all == true (don't skip)
         if ( ! $all or $self->_model->is_mode('edit') ) {
             next if ($ctrlrw eq 'r') or ($ctrlrw eq 'ro'); # skip ro field
         }

         # Run the appropriate sub according to control (widget) type
         my $sub_name = "control_read_$ctrltype";
         if ( $self->can($sub_name) ) {
             unless ( $ctrl_ref->{$field}[1] ) {
                 print "WW: Undefined field '$field', check configuration!\n";
                 next;
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

        # Trim spaces and '\n' from the end
        $value = Tpda3::Utils->trim($value);

        $self->{_scrdata}{$field} = $value;
        # print "Screen (e): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{_scrdata}{$field} = undef;
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

        # Trim spaces and '\n' from the end
        $value = Tpda3::Utils->trim($value);

        $self->{_scrdata}{$field} = $value;
        # print "Screen (t): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{_scrdata}{$field} = undef;
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

        $self->{_scrdata}{$field} = $value;
        # print "Screen (d): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{_scrdata}{$field} = undef;
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

        $self->{_scrdata}{$field} = $value;
        # print "Screen (m): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{_scrdata}{$field} = undef;
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

        $self->{_scrdata}{$field} = $value;
        # print "Screen (l): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{_scrdata}{$field} = undef;
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
        $self->{_scrdata}{$field} = $value;
        # print "Screen (c): $field = $value\n";
    }
    else {

        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{_scrdata}{$field} = $value;
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
        $self->{_scrdata}{$field} = $value;
        # print "Screen (r): $field = $value\n";
    }
    else {
        # If update(=edit) status, add NULL value
        if ( $self->_model->is_mode('edit') ) {
            $self->{_scrdata}{"$field:r"} = undef;
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

    # Current page
    my $page = $self->_view->get_nb_current_page();

    my ($ctrl_ref, $cfg_ref);
    if ( $page eq 'rec' ) {
        $ctrl_ref = $self->scrobj('rec')->get_controls();
        $cfg_ref  = $self->scrcfg('rec');
    }
    elsif ( $page eq 'det' ) {
        $ctrl_ref = $self->scrobj('det')->get_controls();
        $cfg_ref  = $self->scrcfg('det');
    }
    else {
        warn "Wrong page: $page!\n";
        return;
    }

    return unless scalar keys %{$ctrl_ref};  # no controls?

    foreach my $field ( keys %{ $cfg_ref->main_table_columns } ) {
        my $fld_cfg = $cfg_ref->main_table_column($field);

        my $ctrl_state;
        eval {
            $ctrl_state = $ctrl_ref->{$field}[1]->cget( -state );
        };
        if ($@) {
            print "WW: Undefined field '$field', check configuration (w)!\n";
            next;
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
            next if !$value;
        }
        elsif ( $option eq 'clear' ) {
            my $rw = $fld_cfg->{rw};
            next if $rw eq 'r'; # 'det' page fields with data from 'rec'
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

=head2 tmatrix_read

Read data from a table matrix widget.

=cut

sub tmatrix_read {
    my ($self, $tm_ds) = @_;

    $tm_ds ||= q{tm1};           # default table matrix designator

    my $tmx = $self->scrobj('rec')->get_tm_controls($tm_ds);
    my $xtvar;
    if ($tmx) {
        $xtvar = $tmx->cget( -variable );
    }
    else {
        print "EE: Can't find '$tm_ds' table\n";
        return;
    }

    my $rows_no  = $tmx->cget( -rows );
    my $cols_no  = $tmx->cget( -cols );
    my $rows_idx = $rows_no - 1;
    my $cols_idx = $cols_no - 1;

    my $fields_cfg = $self->scrcfg('rec')->dep_table_columns($tm_ds);
    my $cols_ref   = Tpda3::Utils->sort_hash_by_id($fields_cfg);

    # Get selectorcol index, if any
    my $sc = $self->scrcfg('rec')->dep_table_has_selectorcol($tm_ds);

    # Read table data and create an AoH
    my @tabledata;

    # The first row is the header
    for my $row ( 1 .. $rows_idx ) {

        my $rowdata = {};
        for my $col ( 0 .. $cols_idx ) {

            next if $sc and ($col == $sc); # skip selectorcol

            my $cell_value = $tmx->get("$row,$col");
            my $col_name = $cols_ref->[$col];

            my $fld_cfg = $fields_cfg->{$col_name};
            my ($rw ) = @$fld_cfg{'rw'};     # hash slice

            next if $rw eq 'ro'; # skip ro cols

            # print "$row: $col_name => $cell_value\n";
            $rowdata->{$col_name} = $cell_value;
        }

        push @tabledata, $rowdata;
    }

    return (\@tabledata, $sc);
}

=head2 tmatrix_get_selected

Get selected table row.

=cut

sub tmatrix_get_selected {
    my $self = shift;

    return $self->{_tm_sel};
}

sub tmatrix_set_selected {
    my ($self, $selected_row) = @_;

    if ($selected_row) {
        $self->{_tm_sel} = $selected_row;
    }
    else {
        $self->{_tm_sel} = undef;
    }

    return;
}

=head2 tmatrix_read_cell

Read a cell from a TableMatrix widget and return it as a hash
reference.

TableMatrix designator is optional and default to 'tm1'.

The I<col> parameter can be a number - column index or a column name.

=cut

sub tmatrix_read_cell {
    my ($self, $row, $col, $tm_ds) = @_;

    my $is_col_name = 0;
    $is_col_name    = 1 if $col !~ m{\d+};

    $tm_ds ||= q{tm1};           # default table matrix designator

    my $tmx = $self->scrobj('rec')->get_tm_controls($tm_ds);
    unless ($tmx) {
        warn "No TM!\n";
        return;
    }

    my $fields_cfg = $self->scrcfg('rec')->dep_table_columns($tm_ds);

    my $col_name;
    if ($is_col_name) {
        $col_name = $col;
        $col = $fields_cfg->{$col_name}{id};
    }
    else {
        my $cols_ref = Tpda3::Utils->sort_hash_by_id($fields_cfg);
        $col_name = $cols_ref->[$col];
    }

    my $cell_value = $tmx->get("$row,$col");

    return {$col_name => $cell_value};
}

=head2 tmatrix_write

Write data to TableMatrix widget.

=cut

sub tmatrix_write {
    my ($self, $record_ref, $tm_ds) = @_;

    $tm_ds ||= q{tm1};           # default table matrix designator

    my $tmx = $self->scrobj('rec')->get_tm_controls($tm_ds);
    my $xtvar;
    if ($tmx) {
        $xtvar = $tmx->cget( -variable );
    }
    else {
        return;
    }

    my $row = 1;

    #- Scan and write to table
    my $scrcfg = $self->scrcfg('rec');

    foreach my $record ( @{$record_ref} ) {
        foreach my $field ( keys %{ $scrcfg->dep_table_columns($tm_ds) } ) {
            my $fld_cfg = $scrcfg->dep_table_column($tm_ds, $field);

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
    $tmx->configure( -rows => $row);

    return;
}

sub tmatrix_clear {
    my ($self, $tm_ds) = @_;

    my $tmx      = $self->scrobj('rec')->get_tm_controls($tm_ds);
    my $rows_no  = $tmx->cget( -rows );
    my $rows_idx = $rows_no - 1;
    my $r;

    for my $row ( 1 .. $rows_idx ) {
            $tmx->deleteRows( $row, 1 );
    }

    return;
}

=head2 tmatrix_make_selector

Make TableMatrix selector.

=cut

sub tmatrix_make_selector {
    my ($self, $tm_ds) = @_;

    my $sc = $self->scrcfg('rec')->dep_table_has_selectorcol($tm_ds);

    return unless $sc;

    my $tmx      = $self->scrobj('rec')->get_tm_controls($tm_ds);
    my $rows_no  = $tmx->cget( -rows );
    # my $cols_no  = $tmx->cget( -cols );
    my $rows_idx = $rows_no - 1;
    # my $cols_idx = $cols_no - 1;

    foreach my $r ( 1 .. $rows_idx ) {
        $self->embeded_buttons( $tmx, $r, $sc );
    }

    return;
}

=head2 tmatrix_write_row

Write a row to a TableMatrix widget.

TableMatrix designator is optional and default to 'tm1'.

=cut

sub tmatrix_write_row {
    my ($self, $row, $col, $record_ref, $tm_ds) = @_;

    return unless ref $record_ref;     # No results

    $tm_ds ||= q{tm1};           # default table matrix designator

    my $tmx = $self->scrobj('rec')->get_tm_controls($tm_ds);
    my $xtvar;
    if ($tmx) {
        $xtvar = $tmx->cget( -variable );
    }
    else {

        # Just ignore :)
        return;
    }

    my $nr_col = 0;
    foreach my $field ( keys %{$record_ref} ) {

        my $fld_cfg = $self->scrcfg('rec')->dep_table_column($tm_ds, $field);
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

=head2 tmatrix_add_row

Table matrix methods.  Add TableMatrix row.

=cut

sub tmatrix_add_row {
    my ($self, $tm_ds, $valori_ref) = @_;

    $tm_ds ||= q{tm1};          # default table matrix designator

    my $updstyle = $self->scrcfg('rec')->dep_table_updatestyle($tm_ds);
    my $xt = $self->scrobj('rec')->get_tm_controls($tm_ds);

    return
      unless $self->_model->is_mode('add')
          or $self->_model->is_mode('edit');

    $xt->configure( state => 'normal' );    # normal state
    my $old_r = $xt->index( 'end', 'row' ); # get old row index
    $xt->insertRows('end');
    my $new_r = $xt->index( 'end', 'row' ); # get new row index

    if (($updstyle eq 'delete+add') or ($old_r == 0)) {
        $xt->set( "$new_r,0", $new_r );     # set new index
        $self->tmatrix_renum_row($xt);
    }
    else {
        # No renumbering ...
        my $max_r = (sort {$b <=> $a} $xt->get("1,0","$old_r,0"))[0]; # max row
        if ($max_r >= $new_r) {
            $xt->set( "$new_r,0", $max_r + 1);
        }
        else {
            $xt->set( "$new_r,0", $new_r);
        }
    }

    my $sc = $self->scrcfg('rec')->dep_table_has_selectorcol($tm_ds);
    if ($sc) {
        $self->embeded_buttons( $xt, $new_r, $sc ); # add button
        $self->tmatrix_set_selected($new_r);
    }

    # Focus to newly inserted row, column 1
    $xt->focus;
    $xt->activate("$new_r,1");
    $xt->see("$new_r,1");

    $self->_model->set_scrdata_rec(1); # modified

    return;
}

=head2 tmatrix_remove_row

Delete TableMatrix row.

=cut

sub tmatrix_remove_row {
    my ($self, $tm_ds) = @_;

    $tm_ds ||= q{tm1};           # default table matrix designator

    my $updstyle = $self->scrcfg('rec')->dep_table_updatestyle($tm_ds);
    my $xt = $self->scrobj('rec')->get_tm_controls($tm_ds);

    unless ( $self->_model->is_mode('add')
                 || $self->_model->is_mode('edit') ) {
        return;
    }

    $xt->configure( state => 'normal' );

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
        $self->_view->set_status('Select a row','ms','orange');
        return;
    }

    my $sc = $self->scrcfg('rec')->dep_table_has_selectorcol($tm_ds);
    if ($sc) {
        $self->tmatrix_set_selected($r - 1);
        $self->toggle_detail_tab;
    }

    $self->tmatrix_renum_row($xt)
      if $updstyle eq 'delete+add';    # renumber rows

    # Refresh table
    $xt->activate('origin');
    $xt->activate("$r,1");

    # TODO: Feature to trigger a method here?

    $self->_model->set_scrdata_rec(1); # modified

    return $r;
}

=head2 tmatrix_renum_row

Renumber TableMatrix rows.

=cut

sub tmatrix_renum_row {
    my ($self, $xt) = @_;

    my $r = $xt->index( 'end', 'row' );

    if ( $r >= 1 ) {
        foreach my $i ( 1 .. $r ) {
            $xt->set( "$i,0", $i );
        }
    }

    return;
}

=head2 toggle_mode_find

Toggle find mode, ask to save record if modified.

=cut

sub toggle_mode_find {
    my $self = shift;

    my $answer = $self->ask_to_save; # if $self->_model->is_modified;
    if (! defined $answer) {
        $self->_view->get_toolbar_btn('tb_fm')->deselect;
        return;
    }

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

    if ( $self->_model->is_mode('edit') ) {
        my $answer = $self->ask_to_save; # if $self->_model->is_modified;
        if ( !defined $answer ) {
            $self->_view->get_toolbar_btn('tb_ad')->deselect;
            return;
        }
    }

    $self->_model->is_mode('add')
        ? $self->set_app_mode('idle')
        : $self->set_app_mode('add');

    $self->_view->set_status( '','ms' ); # clear messages

    return;
}

=head2 controls_rec_state_set

Toggle all controls state from I<Screen>.

=cut

sub controls_state_set {
    my ( $self, $state ) = @_;

    $self->_log->info("Screen 'rec' controls state is '$state'");

    my $page = $self->_view->get_nb_current_page();

    my $ctrl_ref = $self->scrobj($page)->get_controls();
    return unless scalar keys %{$ctrl_ref};

    my $control_states = $self->control_states($state);

    return unless defined $self->scrcfg($page);

    foreach my $field ( keys %{ $self->scrcfg($page)->main_table_columns } ) {
        my $fld_cfg = $self->scrcfg($page)->main_table_column($field);

        # Skip for some control types
        # next if $fld_cfg->{ctrltype} = '';

        my $ctrl_state = $control_states->{state};
        $ctrl_state = $fld_cfg->{state}
            if $ctrl_state eq 'from_config';

        my $bkground = $control_states->{background};
        my $bg_color = $bkground;
        $bg_color = $fld_cfg->{bgcolor}
            if $bkground eq 'from_config';
        $bg_color = $self->scrobj($page)->get_bgcolor
            if $bkground eq 'disabled_bgcolor';

        # Special case for find mode and fields with 'findtype' set to none
        if ( $state eq 'find' ) {
            if ( $fld_cfg->{findtype} eq 'none' ) {
                $ctrl_state = 'disabled';
                $bg_color   = $self->scrobj($page)->get_bgcolor();
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

# sub controls_det_state_set {
#     my ( $self, $state ) = @_;

#     $self->_log->info("Screen 'det' controls state is '$state'");

#     return unless $self->scrobj('det');

#     my $ctrl_ref = $self->scrobj('det')->get_controls();
#     return unless scalar keys %{$ctrl_ref};

#     my $control_states = $self->control_states($state);

#     return unless defined $self->scrcfg('det');

#     foreach my $field ( keys %{ $self->scrcfg('det')->main_table_columns } ) {
#         my $fld_cfg = $self->scrcfg('det')->main_table_column($field);

#         # Skip for some control types
#         # next if $fld_cfg->{ctrltype} = '';

#         my $ctrl_state = $control_states->{state};
#         $ctrl_state = $fld_cfg->{state}
#             if $ctrl_state eq 'from_config';

#         my $bkground = $control_states->{background};
#         my $bg_color = $bkground;
#         $bg_color = $fld_cfg->{bgcolor}
#             if $bkground eq 'from_config';
#         $bg_color = $self->scrobj('rec')->get_bgcolor()
#             if $bkground eq 'disabled_bgcolor';

#         # Special case for find mode and fields with 'findtype' set to none
#         if ( $state eq 'find' ) {
#             if ( $fld_cfg->{findtype} eq 'none' ) {
#                 $ctrl_state = 'disabled';
#                 $bg_color   = $self->scrobj('rec')->get_bgcolor();
#             }
#         }

#         # Configure controls
#         eval {
#             $ctrl_ref->{$field}[1]->configure( -state => $ctrl_state, );
#             $ctrl_ref->{$field}[1]->configure( -background => $bg_color, );
#         };
#         if ($@) {
#             # print "Problems with '$field'\n";
#         }
#     }

#     return;
# }

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

    # TODO: Bindings for Checkbox
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

=head2 record_load_new

Load a new record.

The (primary) key field value is col0 from the selected item in the
list control on the I<List> page.

=cut

sub record_load_new {
    my ($self, $pk_val) = @_;

    $self->screen_set_pk_val($pk_val); # save PK value

    $self->tmatrix_set_selected();     # initialize selector

    $self->record_load();

    if ( $self->_model->is_loaded ) {
        $self->_view->set_status('Record loaded','ms','blue');
    }

    return;
}

=head2 record_reload

Reload the curent record.

Reads the contents of the (primary) key field, retrieves the record from
the database table and loads the record data in the controls.

=cut

sub record_reload {
    my $self = shift;

    my $page = $self->_view->get_nb_current_page();

    # Save PK-value
    my $pk_val = $self->screen_get_pk_val; # get old pk-val

    $self->record_clear;

    # Restore PK-value
    $self->screen_set_pk_val($pk_val);

    # Set parameters for record load (pk, fk)
    $self->get_selected_and_set_fk_val if $page eq 'det';

    $self->record_load();

    $self->toggle_detail_tab;

    $self->_view->set_status("Record reloaded",'ms','blue');

    $self->_model->set_scrdata_rec(0); # false = loaded,  true = modified,
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

    $self->screen_write($record);

    #- Dependent table(s), (if any)

    foreach my $tm_ds ( keys %{ $self->scrobj($page)->get_tm_controls() } ) {
        my $tm_params = $self->dep_table_metadata($tm_ds, 'qry');

        my $records = $self->_model->table_batch_query($tm_params);

        $self->tmatrix_clear($tm_ds);
        $self->tmatrix_write($records, $tm_ds);

        $self->tmatrix_make_selector($tm_ds); # if configured
    }

    # Save record as witness reference for comparison
    $self->save_screendata( $self->storable_file_name('orig') );

    $self->_model->set_scrdata_rec(0); # false = loaded,  true = modified,
                                       # undef = unloaded

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
    push @record, $record;         # rec data at index 0

    #-  Dependent table(s), if any

    my $deprec = {};
    my $tm_dss = $self->scrobj->get_tm_controls(); #

    foreach my $tm_ds ( keys %{$tm_dss} ) {
        $deprec->{$tm_ds}{metadata} =
            $self->dep_table_metadata($tm_ds, 'del');
    }
    push @record, $deprec if scalar keys %{$deprec}; # det data at index 1

    $self->_model->store_record_delete(\@record);

    $self->set_app_mode('idle');

    $self->_model->unset_scrdata_rec(); # false = loaded,  true = modified,
                                        # undef = unloaded

    return;
}

=head2 record_clear

Clear the screen.

=cut

sub record_clear {
    my $self = shift;

    $self->screen_write(undef, 'clear'); # clear the controls

    $self->screen_set_pk_val();

    $self->_model->unset_scrdata_rec();  # false = loaded,  true = modified,
                                         # undef = unloaded
    return;
}

=head2 ask_to_save

If in I<add> or I<edit> mode show dialog and ask to save or
cancel. Reset modified status.

=cut

sub ask_to_save {
    my $self = shift;

    if (   $self->_model->is_mode('edit')
        or $self->_model->is_mode('add') ) {

        if ( $self->record_changed ) {

            # Using a dialog defined on site because the one defined
            # in View.pm, shows up behind the main window in KDE
            my $db = $self->_view->DialogBox(
                -title   => 'Dialog',
                -buttons => [qw{Da Renunt Nu}],
            );
            $db->geometry('300x150');
            $db->bind(
                '<Escape>',
                sub { $db->Subwidget('B_Renunt')->invoke }
            );

            #
            my $dialog_text = "Inregistarea a fost modificata.\n\n";
            $dialog_text   .= "Doriti sa salvati inregistrarea?";
            my $scrolled = $db->Label(
                -text => $dialog_text,
            )->pack(
                -side => 'bottom',
                -padx => 20,
                -pady => 20,
            );
            #

            # Position buttons to the right
            # Source: PM by lamprecht on Apr 22, 2011 at 22:09 UTC
            # my $bframe = $db->Subwidget('bottom');
            # for ($bframe->children) {
            #     $_->packForget;
            #     $_->pack(-side => 'right',
            #              -padx => 3,
            #              -pady => 3,
            #          );
            # }

            # Does'n work as expected :(
            # Rise and Show dialog by qumsieh on Oct 08, 2004
            # $self->_view->after(50, sub {$self->_view->{asksave}->raise});
            # my $answer = $self->_view->{asksave}->Show();
            my $answer = $db->Show();
            if ( $answer eq q{Da} ) {
                $self->record_save();
            }
            elsif ( $answer eq q{Nu} ) {
                $self->_view->set_status( 'Not saved!', 'ms', 'blue' );
            }
            else {
                $self->_view->set_status( 'Canceled', 'ms', 'blue' );
                return;
            }
        }
    }

    return 1;
}

sub ask_to {
    my ($self, $for_action) = @_;

    # Using a dialog defined on site because the one defined
    # in View.pm, shows up behind the main window in KDE
    my $db = $self->_view->DialogBox(
        -title   => 'Dialog',
        -buttons => [qw{Da Renunt Nu}],
    );
    $db->geometry('300x150');
    $db->bind(
        '<Escape>',
        sub { $db->Subwidget('B_Renunt')->invoke }
    );

    #
    my $dialog_text = '';
    if ($for_action eq 'save') {
        $dialog_text = "Inregistarea a fost modificata.\n\n";
        $dialog_text   .= "Doriti sa salvati inregistrarea?";
    }
    elsif ($for_action eq 'save_insert') {
        $dialog_text = "Inregistare noua.\n\n";
        $dialog_text   .= "Doriti sa salvati inregistrarea?";
    }
    #

    my $scrolled = $db->Label(
        -text => $dialog_text,
    )->pack(
        -side => 'bottom',
        -padx => 20,
        -pady => 20,
    );

    # $self->_view->after(50, sub {$self->_view->{asksave}->raise});
    # my $answer = $self->_view->{asksave}->Show();
    my $answer = $db->Show();
    if ( $answer eq q{Da} ) {
        return 'yes';
    }
    elsif ( $answer eq q{Nu} ) {
        return 'no';
    }
    else {
        return 'cancel';
    }
}

=head2

Save record.  Different procedures for different modes.

=cut

sub record_save {
    my $self = shift;

    if ( $self->_model->is_mode('add') ) {
        my $record = $self->get_screen_data_record('ins');

        my $answer = $self->ask_to('save_insert');

        return if $answer eq 'cancel';
        print "answer is $answer\n";

        $self->record_save_insert($record) if $answer eq 'yes';

        $self->record_reload;
    }
    elsif ( $self->_model->is_mode('edit') ) {
        if ( !$self->is_record ) {
            $self->_view->set_status('Empty screen','ms','orange' );
            return;
        }

        my $record = $self->get_screen_data_record('upd');

        $self->_model->store_record_update($record);
    }
    else {
        $self->_view->set_status( 'Not in edit|add mode!', 'ms', 'darkred' );
        return;
    }

    $self->_model->set_scrdata_rec(0); # false = loaded,  true = modified,
                                       # undef = unloaded

    $self->toggle_detail_tab;

    return;
}

=head2 record_save_insert

Insert record.

=cut

sub record_save_insert {
    my ($self, $record) = @_;

    # Ask first
    # my $answer = $self->_view->{dialog2}->Show();
    # if ( $answer !~ /Ok/i ) {
    #     $self->_view->set_status( 'Canceled', 'ms', 'blue' );
    #     return;
    # }

    my $pk_val = $self->_model->store_record_insert($record);

    if ($pk_val) {
        my $pk_col = $record->[0]{metadata}{pkcol};
        $self->screen_write( { $pk_col => $pk_val }, 'fields' );
        $self->set_app_mode('edit');
        $self->_view->set_status( 'New record', 'ms', 'darkgreen' );
        $self->screen_set_pk_val($pk_val); # save PK value
    }
    else {
        $self->_view->set_status( 'Failed', 'ms', 'darkred' );
        return;
    }

    # TODO: Insert in List

    return;
}

=head2 record_changed

Retrieve the witness data structure from disk and the current data
structure read from the screen widgets and compare them.

=cut

sub record_changed {
    my ($self, ) = @_;

    my $witness_file = $self->storable_file_name('orig');
    unless (-f $witness_file) {
        $self->_view->set_status( 'Error!','ms','orange' );
        croak "Can't find saved data for comparison!\n";
        return;
    }

    my $witness = retrieve($witness_file);

    my $record = $self->get_screen_data_record('upd');

    return $self->_model->record_compare($witness, $record);
}

=head2 take_note

Save record to a temporary file on disk.  Can be restored into a new
record.  An easy way of making multiple records based on a template.

=cut

sub take_note {
    my $self = shift;

    my $msg = $self->save_screendata( $self->storable_file_name )
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

    my $msg = $self->restore_screendata( $self->storable_file_name )
            ? 'Note restored'
            : 'Note restore failed';

    $self->_view->set_status( $msg, 'ms','blue' );

    return;
}

=head2 storable_file_name

Note file name defaults to the name of the screen with a I<dat>
extension.

=cut

sub storable_file_name {
    my ($self, $orig) = @_;

    my $suffix = q{};
    $suffix = '-orig' if $orig;

    # Store record data to file
    my $data_file = catfile(
        $self->_cfg->cfapps,
        $self->_cfg->cfname,
        $self->screen_string . $suffix . q{.dat},
    );

    return $data_file;
}

=head2 get_screen_data_record

Make a record from screen data.  The data structure is an AoH where at
index 0 there is the main record meta-data and data and at index 1 the
dependent table(s) data and meta-data.

=cut

sub get_screen_data_record {
    my ($self, $for_sql) = @_;

    $self->screen_read('all_fields');

    my @record;

    #-  Main table

    #-- Metadata
    my $record = {};
    $record->{metadata} = $self->main_table_metadata($for_sql);

    #-- Data
    while ( my ( $field, $value ) = each( %{$self->{_scrdata} } ) ) {
        $record->{data}{$field} = $value;
    }
    push @record, $record;         # rec data at index 0

    #-  Dependent table(s), if any

    my $deprec = {};
    my $tm_dss = $self->scrobj->get_tm_controls(); #

    foreach my $tm_ds ( keys %{$tm_dss} ) {
        $deprec->{$tm_ds}{metadata} =
          $self->dep_table_metadata($tm_ds, $for_sql);
        ( $deprec->{$tm_ds}{data}, undef ) = $self->tmatrix_read($tm_ds);

        # TableMatrix data doesn't contain pk_col=>pk_val, add it
        my $pk_ref = $record->{metadata}{where};
        foreach my $rec ( @{ $deprec->{$tm_ds}{data} } ) {
            @{$rec}{ keys %{$pk_ref} } = values %{$pk_ref};
        }
    }
    push @record, $deprec if scalar keys %{$deprec}; # det data at index 1

    return \@record;
}

=head2 main_table_metadata

Retrieve main table meta-data from the screen configuration.

=cut

sub main_table_metadata {
    my ($self, $for_sql) = @_;

    my $metadata = {};

    #- Get PK field name and value and FK if exists
    my $pk_col = $self->screen_get_pk_col;
    my $pk_val = $self->screen_get_pk_val;
    my ($fk_col, $fk_val);
    my $has_dep = 0;
    if ($self->scrcfg->screen->{style} eq 'dependent') {
        $has_dep = 1;
        $fk_col = $self->screen_get_fk_col;
        $fk_val = $self->screen_get_fk_val;
    }

    if ($for_sql eq 'qry') {
        $metadata->{table} = $self->scrcfg->main_table_view;
        $metadata->{where}{$pk_col} = $pk_val; # pk
        $metadata->{where}{$fk_col} = $fk_val if $has_dep;
    }
    elsif ($for_sql eq 'upd' or $for_sql eq 'del') {
        $metadata->{table} = $self->scrcfg->main_table_name;
        $metadata->{where}{$pk_col} = $pk_val; # pk
        $metadata->{where}{$fk_col} = $fk_val if $has_dep;
    }
    elsif ($for_sql eq 'ins') {
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
    my ($self, $tm_ds, $for_sql) = @_;

    my $metadata = {};

    #- Get PK field name and value
    my $pk_col = $self->screen_get_pk_col;
    my $pk_val = $self->screen_get_pk_val;

    if ($for_sql eq 'qry') {
        $metadata->{table} = $self->scrcfg->dep_table_view($tm_ds);
        $metadata->{where}{$pk_col} = $pk_val; # pk
    }
    elsif ($for_sql eq 'upd' or $for_sql eq 'del') {
        $metadata->{table} = $self->scrcfg->dep_table_name($tm_ds);
        $metadata->{where}{$pk_col} = $pk_val; # pk
    }
    elsif ($for_sql eq 'ins') {
        $metadata->{table} = $self->scrcfg->dep_table_name($tm_ds);
    }
    else {
        warn "Wrong parameter: $for_sql\n";
        return;
    }

    my $columns = $self->scrcfg->dep_table_columns($tm_ds);

    $metadata->{pkcol}    = $pk_col;
    $metadata->{fkcol}    = $self->scrcfg->dep_table_fkcol($tm_ds);
    $metadata->{order}    = $self->scrcfg->dep_table_orderby($tm_ds);
    $metadata->{colslist} = Tpda3::Utils->sort_hash_by_id($columns);
    $metadata->{updstyle} = $self->scrcfg->dep_table_updatestyle($tm_ds);

    return $metadata;
}

=head2 save_screendata

Save screen data to temp file with Storable.

=cut

sub save_screendata {
    my ($self, $data_file) = @_;

    my $mode = $self->_model->get_appmode;

    my $record = $self->get_screen_data_record('upd');

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
        warn "Unable to retrieve from $data_file!\n";
        return;
    }

    #- Main table

    my $mainrec = $rec->[0];                 # main record is first

    # Dont't want to restore the Id field, remove it
    my $where = $mainrec->{metadata}{where};
    delete $mainrec->{data}{$_} for keys %{$where};

    $self->screen_write( $mainrec->{data}, 'record' );

    #- Dependent table(s), if any

    my $deprec = $rec->[1];                 # dependent records follow

    foreach my $tm_ds ( keys %{ $self->scrobj('rec')->get_tm_controls() } ) {
        $self->tmatrix_write($deprec->{$tm_ds}{data}, $tm_ds);
    }

    return 1;
}

=head2 embeded_buttons

Embeded windows

=cut

sub embeded_buttons {
    my ($self, $tmx, $row, $col) = @_;

    $tmx->windowConfigure(
        "$row,$col",
        -sticky => 's',
        -window => $self->build_rbbutton($row, $col),
    );

    return;
}

=head2 build_rbbutton

Build Radiobutton.

=cut

sub build_rbbutton {
    my ( $self, $row, $col ) = @_;

    my $button = $self->_view->Radiobutton(
        -width       => 3,
        -variable    => \$self->{_tm_sel},
        -value       => $row,
        -indicatoron => 0,
        -selectcolor => 'lightblue',
        -state       => 'normal',
    );

    # Default selected row == 1
    $self->tmatrix_set_selected($row) if $row == 1;

    return $button;
}

#-- PK

sub screen_get_pk_col {
    my $self = shift;

    return $self->scrcfg('rec')->main_table_pkcol();
}

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

sub screen_set_pk_val {
    my ($self, $pk_val) = @_;

    my $pk_col = $self->screen_get_pk_col;

    if ($pk_col) {
        $self->{_tblkeys}{$pk_col} = $pk_val;
    }
    else {
        croak "ERR: Unknown PK column name!\n";
    }

    return;
}

sub screen_get_pk_val {
    my $self = shift;

    my $pk_col = $self->screen_get_pk_col;

    return $self->{_tblkeys}{$pk_col};
}

#-- FK

sub screen_get_fk_col {
    my $self = shift;

    return $self->scrcfg('det')->main_table_fkcol();
}

sub screen_set_fk_col {
    my $self = shift;

    my $fk_col = $self->screen_get_fk_col;

    if ($fk_col) {
        $self->{_tblkeys}{$fk_col} = undef;
    }
    else {
        croak "ERR: Unknown FK column name!\n";
    }

    return;
}

sub screen_set_fk_val {
    my ($self, $fk_val) = @_;

    my $fk_col = $self->screen_get_fk_col;

    if ($fk_col) {
        $self->{_tblkeys}{$fk_col} = $fk_val;
    }
    else {
        croak "ERR: Unknown FK column name!\n";
    }

    return;
}

sub screen_get_fk_val {
    my $self = shift;

    my $fk_col = $self->screen_get_fk_col;

    return $self->{_tblkeys}{$fk_col};
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
