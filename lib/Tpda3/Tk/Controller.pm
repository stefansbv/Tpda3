package Tpda3::Tk::Controller;

use strict;
use warnings;

use Data::Dumper;
use Carp;

use Tk;
use Tk::Font;
use Tk::DialogBox;

use Scalar::Util qw(blessed);
use Class::Unload;
use Log::Log4perl qw(get_logger :levels);
use Storable qw (store retrieve);

use Tpda3::Utils;
use Tpda3::Config;
use Tpda3::Model;
use Tpda3::Tk::View;
use Tpda3::Tk::Dialog::Login;
use Tpda3::Tk::Dialog::Help;
use Tpda3::Tk::Dialog::Repman;
use Tpda3::Lookup;
use Tpda3::Generator;

use File::Basename;
use File::Spec::Functions qw(catfile);

=head1 NAME

Tpda3::Tk::Controller - The Controller

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

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

=item _dscrcls  - class name of the current I<detail> screen

=item _dscrobj  - current I<detail> screen object

=item _tblkeys  - primary and foreign keys and values record

=item _scrdata  - current screen data

=back

=cut

sub new {
    my $class = shift;

    my $model = Tpda3::Model->new();

    my $view = Tpda3::Tk::View->new($model);

    my $self = {
        _model   => $model,
        _app     => $view,                       # an alias as for Wx ...
        _view    => $view,
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

=head2 guide

Quick help dialog.

=cut

sub guide {
    my $self = shift;

    my $gui = $self->_view;

    my $gd = Tpda3::Tk::Dialog::Help->new;

    $gd->help_dialog($gui);

    return;
}

sub repman {
    my $self = shift;

    my $gui = $self->_view;

    my $gd = Tpda3::Tk::Dialog::Repman->new('repman');

    $gd->run_screen($gui);

    return;
}

=head2 about

About application dialog.

=cut

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
        -height     => 15,
        -width      => 35,
        -background => $bg
    );

    # Define some fonts.
    my $textfont = $text->cget('-font')->Clone( -family => 'Helvetica' );
    my $italicfont = $textfont->Clone( -slant => 'italic' );
    $text->tag(
        'configure', 'italic',
        -font    => $italicfont,
        -justify => 'center',
    );
    $text->tag(
        'configure', 'normal',
        -font    => $textfont,
        -justify => 'center',
    );

    # Framework version
    my $PROGRAM_NAME = 'Tiny Perl Database Application 3';
    my $PROGRAM_VER  = $Tpda3::VERSION;

    # Get application version
    my $app_class = $self->application_class;
    ( my $app_file = "$app_class.pm" ) =~ s{::}{/}g;
    my ( $APP_VER, $APP_NAME ) = ( '', '' );
    eval {
        require $app_file;
        $app_class->import();
    };
    if ($@) {
        print "WW: Can't load '$app_file'\n";
        return;
    }
    else {
        $APP_VER  = $app_class->VERSION;
        $APP_NAME = $app_class->application_name();
    }

    # Add the about text.
    $text->insert( 'end', "\n" );
    $text->insert( 'end', $PROGRAM_NAME . "\n", 'normal' );
    $text->insert( 'end', "Version " . $PROGRAM_VER . "\n", 'normal' );
    $text->insert( 'end', "Author: Stefan Suciu\n", 'normal' );
    $text->insert( 'end', "Copyright 2010-2011\n", 'normal' );
    $text->insert( 'end', "GNU General Public License (GPL)\n", 'normal' );
    $text->insert( 'end', "stefansbv at users . sourceforge . net",
        'italic' );
    $text->insert( 'end', "\n\n" );
    $text->insert( 'end', "$APP_NAME\n", 'normal' );
    $text->insert( 'end', "Version " . $APP_VER . "\n", 'normal' );

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

    #-- Toggle find mode - Menu
    $self->_view->get_menu_popup_item('mn_fm')->configure(
        -command => sub {
            return if !defined $self->ask_to_save;

            # From add mode forbid find mode
            $self->toggle_mode_find() if !$self->_model->is_mode('add');

        }
    );

    #-- Toggle execute find - Menu
    $self->_view->get_menu_popup_item('mn_fe')->configure(
        -command => sub {
            $self->_model->is_mode('find')
                ? $self->record_find_execute
                : $self->_view->set_status( 'Not find mode', 'ms', 'orange' );
        }
    );

    #-- Toggle execute count - Menu
    $self->_view->get_menu_popup_item('mn_fc')->configure(
        -command => sub {
            $self->_model->is_mode('find')
                ? $self->record_find_count
                : $self->_view->set_status( 'Not find mode', 'ms', 'orange' );
        }
    );

    #-- Exit
    $self->_view->get_menu_popup_item('mn_qt')->configure(
        -command => sub {
            return if !defined $self->ask_to_save;
            $self->_view->on_quit;
        }
    );

    #-- Help
    $self->_view->get_menu_popup_item('mn_gd')->configure(
        -command => sub {
            $self->guide;
        }
    );

    #-- About
    $self->_view->get_menu_popup_item('mn_ab')->configure(
        -command => sub {
            $self->about;
        }
    );

    #-- Preview RepMan report
    $self->_view->get_menu_popup_item('mn_pr')->configure(
        -command => sub { $self->repman; }
    );

    #-- Edit RepMan report metadata
    $self->_view->get_menu_popup_item('mn_er')->configure(
        -command => sub { $self->screen_module_load('Reports','tools'); }
    );

    #-- Save geometry
    $self->_view->get_menu_popup_item('mn_sg')->configure(
        -command => sub {
            $self->save_geometry();
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
            $self->save_geometry();
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
                : $self->_view->set_status( 'Not find mode', 'ms', 'orange' );
        }
    );

    #-- Find count
    $self->_view->get_toolbar_btn('tb_fc')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('find')
                ? $self->record_find_count
                : $self->_view->set_status( 'Not find mode', 'ms', 'orange' );
        }
    );

    #-- Print (preview) default report button
    $self->_view->get_toolbar_btn('tb_pr')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('edit')
                ? $self->screen_report_print()
                : $self->_view->set_status( 'Not edit mode', 'ms', 'orange' );
        }
    );

    #-- Generate default document button
    $self->_view->get_toolbar_btn('tb_gr')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('edit')
                ? $self->screen_document_generate()
                : $self->_view->set_status( 'Not edit mode', 'ms', 'orange' );
        }
    );

    #-- Take note
    $self->_view->get_toolbar_btn('tb_tn')->bind(
        '<ButtonRelease-1>' => sub {
            (          $self->_model->is_mode('edit')
                    or $self->_model->is_mode('add')
                )
                ? $self->take_note()
                : $self->_view->set_status( 'Not add|edit mode',
                'ms', 'orange' );
        }
    );

    #-- Restore note
    $self->_view->get_toolbar_btn('tb_tr')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('add')
                ? $self->restore_note()
                : $self->_view->set_status( 'Not add mode', 'ms', 'orange' );
        }
    );

    #-- Clear screen
    $self->_view->get_toolbar_btn('tb_cl')->bind(
        '<ButtonRelease-1>' => sub {
            (          $self->_model->is_mode('edit')
                    or $self->_model->is_mode('add')
                )
                ? $self->screen_clear()
                : $self->_view->set_status( 'Not add|edit mode',
                'ms', 'orange' );
        }
    );

    #-- Reload
    $self->_view->get_toolbar_btn('tb_rr')->bind(
        '<ButtonRelease-1>' => sub {
            $self->_model->is_mode('edit')
                ? $self->record_reload()
                : $self->_view->set_status( 'Not edit mode', 'ms', 'orange' );
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
            $self->event_record_delete();
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
            return if !defined $self->ask_to_save;
            $self->_view->on_quit;
        }
    );

    #-- Make some key bindings

    #-- Quit Ctrl-q
    $self->_view->bind(
        '<Control-q>' => sub {
            return if !defined $self->ask_to_save;
            $self->_view->on_quit;
        }
    );

    #-- Reload - F5
    $self->_view->bind(
        '<F5>' => sub {
            $self->_model->is_mode('edit')
                ? $self->record_reload()
                : $self->_view->set_status( 'Not edit mode', 'ms', 'orange' );
        }
    );

    #-- Toggle find mode - F7
    $self->_view->bind(
        '<F7>' => sub {

            # From add mode forbid find mode
            $self->toggle_mode_find()
                if $self->{_rscrcls} and !$self->_model->is_mode('add');
        }
    );

    #-- Execute find - F8
    $self->_view->bind(
        '<F8>' => sub {
            ( $self->{_rscrcls} and $self->_model->is_mode('find') )
                ? $self->record_find_execute
                : $self->_view->set_status( 'Not find mode', 'ms', 'orange' );
        }
    );

    #-- Execute count - F9
    $self->_view->bind(
        '<F9>' => sub {
            ( $self->{_rscrcls} and $self->_model->is_mode('find') )
                ? $self->record_find_count
                : $self->_view->set_status( 'Not find mode', 'ms', 'orange' );
        }
    );

    return;
}

=head2 _set_event_handler_nb

Separate event handler for NoteBook because must be initialized only
after the NoteBook is (re)created and that happens when a new screen is
required (selected from the applications menu) to load.

Known limitation: Doesn't ask to save the record when the user changes
from the I<Detail> page to the I<Record> page.

Note: Tried to emulate L<on_page_leave>using I<raisecmd> but without
success, for (now) obvious reasons.

=cut

sub _set_event_handler_nb {
    my ( $self, $page ) = @_;

    $self->_log->trace("Setup event handler on NoteBook for '$page'");

    #- NoteBook events

    my $nb = $self->_view->get_notebook();

    $nb->pageconfigure(
        $page,
        -raisecmd => sub {
            $self->_view->set_nb_current($page);

        #-- On page activate

        SWITCH: {
                $page eq 'lst'
                    && do { $self->on_page_lst_activate; last SWITCH; };
                $page eq 'rec'
                    && do { $self->on_page_rec_activate; last SWITCH; };
                $page eq 'det'
                    && do { $self->on_page_det_activate; last SWITCH; };
                print "EE: \$page is not in (lst rec det)\n";
            }

            $self->_view->set_status( '', 'ms' );    # clear status message
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

Toggle state of the 'I<Detail> tab.

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

When the L<Record> page is activated, do:

If the previous page is L<List>, then get the selected item from the
L<List> widget and load the corresponding record from the database in
the I<rec> screen, but only if it is not already loaded.

If the previous page is L<Details>, toggle toolbar buttons state for
the current page.

=cut

sub on_page_rec_activate {
    my $self = shift;

    if ( $self->_model->is_mode('sele') ) {
        $self->set_app_mode('edit');
    }
    else {
        $self->toggle_interface_controls;
        # $self->toggle_screen_interface_controls;            EXPERIMENT
    }

    $self->_view->nb_set_page_state( 'lst', 'normal');

    return unless $self->_view->get_nb_previous_page eq 'lst';

    my $selected = $self->_view->list_read_selected();    # array reference
    unless ($selected) {
        $self->_view->set_status( 'Nothing selected', 'ms', 'orange' );
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
    $self->_view->get_recordlist->focus;

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
        print "Not selected\n";
        return;
    }

    $self->get_selected_and_set_fk_val;

    $self->record_load();                    # load detail record

    $self->_view->set_status( 'Record loaded (d)', 'ms', 'blue' );
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
        print "Loading detail screen ($dsm)\n";
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

    foreach my $mnu (qw(mn_fm mn_fe mn_fc)) {
        $self->_view->get_menu_popup_item($mnu)
            ->configure( -state => $state, );
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
        my ( $class, $module_file ) = $self->screen_module_class($menu_item);
        eval { require $module_file };
        if ($@) {
            $menu->entryconfigure( $menu_item, -state => 'disabled' );
        }
    }

    return;
}

=head2 setup_lookup_bindings_entry

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
    my ( $self, $page ) = @_;

    my $dict     = Tpda3::Lookup->new;
    my $ctrl_ref = $self->scrobj('rec')->get_controls();

    my $bindings = $self->scrcfg('rec')->bindings;

    $self->_log->trace("Setup binding for configured widgets ($page)");

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

        my $filter;
        $ctrl_ref->{$column}[1]->bind(
            '<Return>' => sub {
                my $record = $dict->lookup( $self->_view, $para, $filter );
                $self->screen_write($record);
            }
        );
    }

    return;
}

=head2 setup_bindings_table

Creates column bindings for table widgets created with
L<Tk::TableMatrix> using the information from the I<tablebindings>
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
            next unless $bind_type;    # skip if just an empty tag

            my $bnd = $bindings->{$bind_type};
            if ( $bind_type eq 'lookup' ) {
                foreach my $bind_name ( keys %{$bnd} ) {
                    next unless $bind_name;    # skip if just an empty tag
                    my $lk_bind = $bnd->{$bind_name};
                    my $lookups = $self->add_dispatch_for_lookup($lk_bind);
                    @{$dispatch}{ keys %{$lookups} } = values %{$lookups};
                }
            }
            elsif ( $bind_type eq 'method' ) {
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
            'Tpda3::Tk::TM',
            '<Return>',
            sub {
                my $r = $tm->index( 'active', 'row' );
                my $c = $tm->index( 'active', 'col' );

                # Table refresh
                $tm->activate('origin');
                $tm->activate("$r,$c");
                $tm->reread();

                my $ci = $tm->cget( -cols ) - 1;    # max col index
                my $sc = $self->method_for( $dispatch, $bindings, $r, $c,
                    $tm_ds );
                my $ac = $c;
                $sc ||= 1;                          # skip cols
                $ac += $sc;                         # new active col
                $tm->activate("$r,$ac");
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
    my ( $self, $bnd ) = @_;

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
    my ( $self, $dispatch, $bindings, $r, $c, $tm_ds ) = @_;

    my $skip_cols;
    my $proc = "colsub$c";
    if ( exists $dispatch->{$proc} ) {
        $skip_cols = $dispatch->{$proc}->( $self, $bindings, $r, $c, $tm_ds );
    }

    return $skip_cols;
}

=head2 lookup

Activates the L<Tpda3::Tk::Dialog::Search> module, to look-up value
key translations from a database table and fill the configured cells
with the results.

=cut

sub lookup {
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

    my $dict = Tpda3::Lookup->new;
    my $record = $dict->lookup( $self->_view, $lk_para, $filter );

    $tmx->write_row( $r, $c, $record, $tm_ds );

    my $skip_cols = scalar @{ $lk_para->{columns} };  # skip ahead cols number

    return $skip_cols;
}

=head2 method

Call a method from the Screen module on I<Return> key.

=cut

sub method {
    my ( $self, $bnd, $r, $c ) = @_;

    # Filter on bindcol = $c
    my @names = grep { $bnd->{method}{$_}{bindcol} == $c }
        keys %{ $bnd->{method} };
    my $bindings = $bnd->{method}{ $names[0] };

    my $method = $bindings->{subname};
    if ( $self->scrobj('rec')->can($method) ) {
        $self->scrobj('rec')->$method($r);
    }
    else {
        print "WW: '$method' not implemented!\n";
    }

    return 1;    # skip_cols
}

=head2 get_lookup_setings

Return the data structure used by the L<Tpda3::Tk::Dialog::Search>
module.  Uses the I<tablebindings> section of the screen configuration
and the related field attributes from the I<dep_table> section.

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
        width => $field_cfg->{width},
        label => $field_cfg->{label},
        order => $field_cfg->{order},
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
            width => $field_cfg->{width},
            label => $field_cfg->{label},
            order => $field_cfg->{order},
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
        my $scr_field = $bindings->{field}{$lookup_field}{name};
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

    my $nb = $self->_view->get_notebook();
    $nb->pageconfigure( 'det', -state => 'disabled' );
    $nb->pageconfigure( 'lst', -state => 'normal' );

    return;
}

=head2 on_screen_mode_add

When in I<add> mode set status to I<normal> and clear all controls
content in the I<Screen> and change the background to the default
color as specified in the configuration.

Create an empty record and write it to the controls. If default values
are defined for some fileds, then fill in that value.

=cut

sub on_screen_mode_add {
    my ( $self, ) = @_;

    $self->record_clear;           # empty the main controls and TM
    $self->tmatrix_set_selected(); # initialize selector

    foreach my $tm_ds ( keys %{ $self->scrobj('rec')->get_tm_controls() } ) {
        $self->scrobj('rec')->get_tm_controls($tm_ds)->clear_all();
    }

    $self->controls_state_set('edit');

    # Fill in the default values
    my $record = $self->get_screen_data_record('ins');
    $self->screen_write( $record->[0]{data} );

    my $nb = $self->_view->get_notebook();
    $nb->pageconfigure( 'lst', -state => 'disabled' );
    $nb->pageconfigure( 'det', -state => 'disabled' );

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
    $nb->pageconfigure( 'lst', -state => 'normal' );

    return;
}

=head2 on_screen_mode_sele

Noting to do here.

=cut

sub on_screen_mode_sele {
    my $self = shift;

    my $nb = $self->_view->get_notebook();
    $nb->pageconfigure( 'det', -state => 'disabled' );

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

=head2 application_class

Main application class name.

=cut

sub application_class {
    my $self = shift;

    my $app_name = $self->_cfg->application->{module};

    return "Tpda3::Tk::App::${app_name}";
}

=head2 screen_module_class

Return screen module class and file name.

=cut

sub screen_module_class {
    my ( $self, $module, $from_tools ) = @_;

    my $module_class;
    if ($from_tools) {
        $module_class = "Tpda3::Tk::Tools::${module}";
    }
    else {
        $module_class = $self->application_class . "::${module}";
    }

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
    $self->_set_event_handler_nb('rec');
    $self->_set_event_handler_nb('lst');

    my ( $class, $module_file )
        = $self->screen_module_class( $module, $from_tools );
    eval { require $module_file };
    if ($@) {

        # TODO: Decide what is optimal to do here?
        print "WW: Can't load '$module_file'\n";
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

    # Details page
    my $has_det = $self->scrcfg('rec')->has_screen_detail;
    if ($has_det) {
        $self->_view->create_notebook_panel( 'det', 'Details' );
        $self->_set_event_handler_nb('det');
    }

    # Show screen
    my $nb = $self->_view->get_notebook();
    $self->{_rscrobj}->run_screen($nb);

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

    $self->set_app_mode('idle');

    # List header
    my $header_look = $self->scrcfg('rec')->list_header->{lookup};
    my $header_cols = $self->scrcfg('rec')->list_header->{column};
    my $fields      = $self->scrcfg('rec')->main_table_columns;
    $self->_view->make_list_header( $header_look, $header_cols, $fields );

    #- Event handlers

    foreach my $tm_ds ( keys %{ $self->scrobj('rec')->get_tm_controls() } ) {
        $self->set_event_handler_screen($tm_ds);
    }

    $self->_set_menus_enable('normal');

    $self->_view->set_status( '', 'ms' );

    $self->_model->unset_scrdata_rec();

    # Change application title
    my $descr = $self->scrcfg('rec')->screen_description;
    $self->_view->title(' Tpda3 - ' . $descr) if $descr;

    # Update window geometry
    $self->set_geometry();

    # Export message dictionary to Model
    my $dict = $self->scrobj()->get_msg_strings();
    $self->_model->message_dictionary($dict);

    # Load lists into JComboBox widgets (JBrowseEntry not supported)
    $self->screen_init();

    return 1;    # to make ok from Test::More happy
                 # probably missing something :) TODO!
}

=head2 set_event_handler_screen

Setup event handlers for the toolbar buttons configured in the
L<deptable> section of the current screen configuration.

Default usage is for the I<add> and I<delete> buttons attached to the
TableMatrix widget.

=cut

sub set_event_handler_screen {
    my ( $self, $tm_ds ) = @_;

    # Get ToolBar button atributes
    my $attribs = $self->scrcfg->dep_table_toolbars($tm_ds);

    foreach my $tb_btn ( keys %{$attribs} ) {
        my $method = $attribs->{$tb_btn}{method};
        $self->_log->trace("Handler for $tb_btn: $method ($tm_ds)");

        # Check current screen for method for binding
        my $scrobj;
        if ( $self->scrobj('rec')->can($method) ) {
            $scrobj = $self->scrobj('rec');
        }
        else {

            # Fallback to $self
            $scrobj = $self;
        }

        $self->scrobj('rec')->get_toolbar_btn( $tm_ds, $tb_btn )->bind(
            '<ButtonRelease-1>' => sub {
                return
                    unless $self->_model->is_mode('add')
                        or $self->_model->is_mode('edit')
                        or $self->scrcfg()->screen_style() eq 'report';

                $scrobj->$method( $tm_ds, $self );
                # TODO: what styles can be used?
                if ($self->scrcfg()->screen_style() ne 'report') {
                    $self->_model->set_scrdata_rec(1);    # modified
                    $self->toggle_detail_tab;
                }
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
        croak "EE: Can't load '$module_file'\n";
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

    #-- Lookup bindings for Tk::Entry widgets
    $self->setup_lookup_bindings_entry('det');

    #-- Lookup bindings for tables (TableMatrix)
    $self->setup_bindings_table();

    # Load lists into JComboBox widgets (JBrowseEntry not supported)
    $self->screen_init();

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

        #- List tab
        $status = 'disabled' if $page eq 'lst';

        #- Set status for toolbar buttons

        $self->_view->enable_tool( $name, $status );
    }

    return;
}

=head2 toggle_screen_interface_controls

Toggle screen controls (toolbar buttons) appropriate for different
states of the application.

Used to fine tune the configuration for screens, enable disable
toolbar buttons per screen.

Also used by the toolbar buttons attached to the TableMatrix widget in
some screens.

=cut

sub toggle_screen_interface_controls {
    my $self = shift;

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

    #- TableMatrix

    foreach my $tm_ds ( keys %{ $self->scrobj($page)->get_tm_controls() } ) {

        # Get ToolBar button atributes
        my $attribs = $self->scrcfg->dep_table_toolbars($tm_ds);

        my $toolbars = Tpda3::Utils->sort_hash_by_id($attribs);

        foreach my $name ( @{$toolbars} ) {
            my $status = $attribs->{$name}{state}{$page}{$mode};
            $self->scrobj($page)->enable_tool( $tm_ds, $name, $status );
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

=head2 screen_clear

Clear the screen: empty all controls.

=cut

sub screen_clear {
    my $self = shift;

    return unless ref $self->scrobj('rec');    # check if screen loaded

    $self->record_clear;

    # TODO: Don't change mode at all?
    # # Don't change mode if 'det' page
    # my $page = $self->_view->get_nb_current_page();
    # if ( $self->_model->is_mode('edit') ) {
    #     $self->set_app_mode('idle') unless $page eq 'det';
    # }

    $self->_view->set_status( 'Cleared', 'ms', 'orange' );

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

=item allstr   - field = I<searchstring>

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

    $self->_log->info("Report tool: $report_exe");
    $self->_log->info("Report file: $report_file");

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
        $self->_view->set_status( 'Report failed!', 'ms' );
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

    print Dumper( $record );

    my $model_file = $self->scrcfg()->get_defaultdocument_file();
    unless (-f $model_file) {
        $self->_view->set_status( 'Template not found', 'ms' );
        return;
    }

    my $output_path = $self->_cfg->config_tex_output_path();
    unless (-d $output_path) {
        $self->_view->set_status( 'Output path not found', 'ms' );
        return;
    }

    my $gen = Tpda3::Generator->new();

    #-- Generate LaTeX document from template

    my $tex_file = $gen->tex_from_template($record, $model_file, $output_path);
    unless (-f $tex_file) {
        $self->_view->set_status( 'Failed: template -> LaTeX', 'ms' );
        return;
    }

    #-- Generate PDF from LaTeX

    my $pdf_file = $gen->pdf_from_latex($tex_file);
    unless (-f $pdf_file) {
        $self->_view->set_status( 'Failed: LaTeX -> PDF', 'ms' );
        return;
    }

    $self->_view->set_status( "PDF: $pdf_file", 'ms' );

    return;
}

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

Read screen controls (widgets) and save in a Perl data stucture.

Returns different data for different application modes.

=over

=item I<Find> mode

Read the fields that have the configured I<rw> attribute set to I<rw>
and I<ro> ignoring the fields with I<r>, but also ignoring the fields
with no values.


=item I<Edit> mode

Read the fields that have the configured I<rw> attribute set to I<rw>,
ignoring the rest (I<r> and I<ro>), but incuding the fields with no
values as I<undef> for the value.

=item I<Add>  mode

Read the fields that have the configured I<rw> attribute set to I<rw>,
ignoring the rest (I<r> and I<ro>), but also ignoring the fields with
no values.

=back

Option to read all fields regardles of the configured I<rw> attribute.

TODO: Find a better attribute name than I<rw>.

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

Read contents of a Tk::Entry control.

=cut

sub control_read_e {
    my ( $self, $field ) = @_;

    my $control = $self->scrobj()->get_controls($field)->[1];

    my $value = $control->get;

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
    my ( $self, $field ) = @_;

    my $control = $self->scrobj()->get_controls($field)->[1];

    my $value = $control->get( '0.0', 'end' );

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
    my ( $self, $field ) = @_;

    my $control = $self->scrobj()->get_controls($field)->[0];

    # Value from variable or empty string
    my $value = ${$control} || q{};

    # Get configured date style and format accordingly
    my $date_format = $self->_cfg->application->{dateformat} || 'iso';

    if ( $date_format and $value ) {

        # Skip date formatting for find mode
        if ( !$self->_model->is_mode('find') ) {

            # Date should go to database in ISO format
            my ( $y, $m, $d )
                = Tpda3::Utils
                ->dateentry_parse_date( $date_format, $value );

            $value
                = Tpda3::Utils->dateentry_format_date( 'iso', $y, $m, $d );
        }
    }
    else {

        # defaults to ISO
    }

    # Add value if not empty
    if ( $value =~ /\S+/ ) {

        # Delete '\n' from end
        $value =~ s/\n$//mg;    # m=multiline

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
    my ( $self, $field ) = @_;

    my $control = $self->scrobj()->get_controls($field)->[0];

    my $value = ${$control};    # value from variable

    # Add value if not empty
    if ( $value =~ /\S+/ ) {

        # Delete '\n' from end
        $value =~ s/\n$//mg;                    # m=multiline

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
    my ( $self, $field ) = @_;

    my $control = $self->scrobj()->get_controls($field)->[1];

    my $value = $control->get_selected_value() || q{};

    # Add value if not empty
    if ( $value =~ /\S+/ ) {

        # Delete '\n' from end
        $value =~ s/\n$//mg;    # m=multiline

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
    my ( $self, $field ) = @_;

    my $control = $self->scrobj()->get_controls($field)->[0];

    my $value = ${$control};

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
    my ( $self, $field ) = @_;

    my $control = $self->scrobj()->get_controls($field)->[0];

    my $value = ${$control} || q{};

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

        # Skip for some control types
        # next if $fld_cfg->{ctrltype} = '';

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
            $ctrl_ref->{$field}[1]->configure( -state      => $ctrl_state, );
            $ctrl_ref->{$field}[1]->configure( -background => $bg_color, );
        };
        print "WW: '$field': $@\n" if $@;
    }

    return;
}

=head2 formated

Return trimed and formated value if places is greater than 0.

TODO: Should make $value = 0, than format as number?

=cut

sub format_as_number {
    my ( $self, $value, $places ) = @_;

    # If places > 0, format as number
    if ( $places and ( $places > 0 ) ) {
        $value = sprintf( "%.${places}f", $value );
    }

    return $value;
}

=head2 control_write_e

Write to a Tk::Entry widget.  If I<$value> not true, than only delete.

=cut

sub control_write_e {
    my ( $self, $field, $value, $state ) = @_;

    my $control = $self->scrobj()->get_controls($field)->[1];

    $state = $state || $control->cget ('-state');

    $value = q{} unless defined $value;    # Empty

    $control->configure( -state => 'normal' );

    $control->delete( 0, 'end' );
    $control->insert( 0, $value ) if $value;

    $control->configure( -state => $state );

    return;
}

=head2 control_write_t

Write to a Tk::Text widget.  If I<$value> not true, than only delete.

=cut

sub control_write_t {
    my ( $self, $field, $value, $state ) = @_;

    my $control = $self->scrobj()->get_controls($field)->[1];

    $state = $state || $control->cget ('-state');

    $value = q{} unless defined $value;    # Empty

    # Tip TextEntry 't'
    $control->delete( '1.0', 'end' );
    $control->insert( '1.0', $value ) if $value;

    $control->configure( -state => $state );

    return;
}

=head2 control_write_d

Write to a Tk::DateEntry widget.  If I<$value> not true, than only delete.

=cut

sub control_write_d {
    my ( $self, $field, $value, $state ) = @_;

    my $control = $self->scrobj()->get_controls($field);

    $state = $state || $control->[1]->cget ('-state');

    $value = q{} unless defined $value;    # Empty

    if ($value) {

        # Date should come from database in ISO format
        my ( $y, $m, $d )
            = Tpda3::Utils->dateentry_parse_date( 'iso', $value );

        # Get configured date style and format accordingly
        my $date_format = $self->_cfg->application->{dateformat} || 'iso';

        if ( $date_format and $value ) {
            $value = Tpda3::Utils->dateentry_format_date( $date_format,
                $y, $m, $d );
        }
        else {

            # default to ISO
        }
    }

    ${ $control->[0] } = $value;

    $control->[1]->configure( -state => $state );

    return;
}

=head2 control_write_m

Write to a Tk::JComboBox widget.  If I<$value> not true, than only
delete.

=cut

sub control_write_m {
    my ( $self, $field, $value, $state ) = @_;

    my $control = $self->scrobj()->get_controls($field);

    $state = $state || $control->[1]->cget ('-state');

    if ($value) {
        $control->[1]->setSelected( $value, -type => 'value' );
    }
    else {
        ${ $control->[0] } = q{};    # Empty
    }

    $control->[1]->configure( -state => $state );

    return;
}

=head2 control_write_l

Write to a Tk::MatchingBE widget.  Warning: cant write an empty value,
must test with a key -> value pair like 'not set' => '?empty?'.

=cut

sub control_write_l {
    my ( $self, $field, $value, $state ) = @_;

    return unless defined $value;    # Empty

    my $control = $self->scrobj()->get_controls($field)->[1];

    $state = $state || $control->cget ('-state');

    $control->set_selected_value($value);

    $control->configure( -state => $state );

    return;
}

=head2 control_write_c

Write to a Tk::Checkbox widget.

=cut

sub control_write_c {
    my ( $self, $field, $value, $state ) = @_;

    my $control = $self->scrobj()->get_controls($field)->[1];

    $state = $state || $control->cget ('-state');

    $value = 0 unless $value;
    if ( $value == 1 ) {
        $control->select;
    }
    else {
        $control->deselect;
    }

    # Execute method bound to radiobutton if defined in screen.
    # Name must be: 'toggle_' + 'field_name'.
    my $sub_name = "toggle_$field";
    if ( $self->scrobj()->can($sub_name) ) {
        $self->scrobj()->$sub_name($value);
    }

    $control->configure( -state => $state );

    return;
}

=head2 control_write_r

Write to a Tk::RadiobuttonGroup widget.

=cut

sub control_write_r {
    my ( $self, $field, $value, $state ) = @_;

    my $control = $self->scrobj()->get_controls($field);

    $state = $state || $control->[1]->cget('-state');

    if ($value) {
        ${ $control->[0] } = $value;
    }
    else {
        ${ $control->[0] } = undef;
    }

    # Execute method bound to radiobutton if defined in screen.
    # Name must be: 'toggle_' + 'field_name'.
    my $sub_name = "toggle_$field";
    if ( $self->scrobj()->can($sub_name) ) {
        $self->scrobj()->$sub_name($value);
    }

    $control->[1]->configure( -state => $state );

    return;
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
        $self->_view->set_status( 'Record loaded', 'ms', 'blue' );
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
    my $pk_val = $self->screen_get_pk_val;    # get old pk-val

    $self->record_clear;

    # Restore PK-value
    $self->screen_set_pk_val($pk_val);

    # Set parameters for record load (pk, fk)
    $self->get_selected_and_set_fk_val if $page eq 'det';

    $self->record_load();

    $self->toggle_detail_tab;

#    $self->_view->set_status( "Record reloaded", 'ms', 'blue' );

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

    return if $answer eq 'cancel' or $answer =~ /^N/i;

    $self->list_update_remove();    # first remove from list

    $self->record_delete();

    $self->_view->set_status( 'Sters', 'ms', 'darkgreen' ); # removed

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

            # Using a dialog defined on site because the one defined
            # in View.pm, shows up behind the main window in KDE
            my $db = $self->_view->DialogBox(
                -title   => 'Dialog',
                -buttons => [qw{Da Renunt Nu}],
            );
            $db->geometry('300x150');
            $db->bind( '<Escape>',
                sub { $db->Subwidget('B_Renunt')->invoke } );

            #
            my $dialog_text = "Inregistarea a fost modificata.\n\n";
            $dialog_text .= "Doriti sa salvati inregistrarea?";
            my $scrolled = $db->Label( -text => $dialog_text, )->pack(
                -side => 'bottom',
                -padx => 20,
                -pady => 20,
            );

            # Position buttons to the right
            # Source: PM by lamprecht on Apr 22, 2011 at 22:09 UTC
            my $bframe = $db->Subwidget('bottom');
            for ($bframe->children) {
                $_->packForget;
                $_->pack(-side => 'right',
                         -padx => 3,
                         -pady => 3,
                     );
            }

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

=head2 ask_to

Create a custom dialog to ask the user confirmation about the current
action.

=cut

sub ask_to {
    my ( $self, $for_action ) = @_;

    # Using a dialog defined on site because the one defined
    # in View.pm, shows up behind the main window in KDE
    my $db = $self->_view->DialogBox(
        -title   => 'Dialog',
        -buttons => [qw{Da Renunt Nu}],
    );
    $db->geometry('300x150');
    $db->bind( '<Escape>', sub { $db->Subwidget('B_Renunt')->invoke } );

    #- Dialog texts

    my $dialog_text = '';
    if ( $for_action eq 'save' ) {
        $dialog_text = "Inregistarea a fost modificata.\n\n";
        $dialog_text .= "Doriti sa salvati inregistrarea?";
    }
    elsif ( $for_action eq 'save_insert' ) {
        $dialog_text = "Inregistare noua.\n\n";
        $dialog_text .= "Doriti sa salvati inregistrarea?";
    }
    elsif ( $for_action eq 'delete' ) {
        $dialog_text = "Stergere inregistare.\n\n";
        $dialog_text .= "Doriti sa stergeti inregistrarea?";
    }

    my $scrolled = $db->Label( -text => $dialog_text, )->pack(
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
                $self->_view->set_status( "$pk_val salvat", 'ms', 'darkgreen' );
            }
        }
    }
    elsif ( $self->_model->is_mode('edit') ) {
        if ( !$self->is_record ) {
            $self->_view->set_status( 'Empty screen', 'ms', 'orange' );
            return;
        }

        my $record = $self->get_screen_data_record('upd');

        $self->_model->prepare_record_update($record);
        $self->_view->set_status( "Salvat", 'ms', 'darkgreen' );
    }
    else {
        $self->_view->set_status( 'Not in edit|add mode!', 'ms', 'darkred' );
        return;
    }

    # Save record as witness reference for comparison
    $self->save_screendata( $self->storable_file_name('orig') );

    $self->_model->set_scrdata_rec(0);    # false = loaded,  true = modified,
                                          # undef = unloaded

    $self->toggle_detail_tab;

    return;
}

=head2 required_data

Check if required data is present in the screen.

There are two list used in this method, the list of the non empty
fields from the screen and the list of the fields that require to have
a value.

This lists are compared and we build a new list with those items which
appear only in the second list, and build a message string with it.

Example I<Screen> data structure for the required field:

  $self->{rq_controls} = {
       productcode        => [ 0, '  Product code' ],
       productname        => [ 1, '  Product name' ],
       ...
  };

Returns I<true> if all required fields have values.

BUG: Dialog not always has focus in GNU/Linux.

=cut

sub if_check_required_data {
    my ($self, $record) = @_;

    unless ( scalar keys %{ $record->[0]{data} } > 0 ) {
        $self->_view->set_status( 'No data to save ...', 'ms', 'orange' );
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

    my @scr_fields = keys %{ $record->[0]{data} };

    my @req_fields = keys %{$ctrl_req};

    my $lc = List::Compare->new('--unsorted', \@scr_fields, \@req_fields);

    my @required = $lc->get_complement;

    # Build a sorted, by index 0, message data structure
    my $messages = [];
    foreach my $field (@required) {
        $messages->[ $ctrl_req->{$field}[0] ] = $ctrl_req->{$field}[1];
        $ok_to_save = 0;
    }

    my @message = grep { defined } @{$messages};    # remove undef elements

    if ( !$ok_to_save ) {
        my $textstr = "Required data:\n\n" . join( "\n", @message );
        $self->_view->{dialog1}->configure( -text => $textstr );
        $self->_view->{dialog1}->Show();
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

Compare the selected row in the I<List> with given Pk and optionaly Fk
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
        $self->_view->set_status( 'Error!', 'ms', 'orange' );
        croak "Can't find saved data for comparison!\n";
        return;
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
        ? 'Note taken'
        : 'Note take failed';

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
        ? 'Note restored'
        : 'Note restore failed';

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

    my $suffix = q{};
    $suffix = '-orig' if $orig;

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

=head2 report_table_metadata

Retrieve table meta-data for report screen style configurations from
the screen configuration.

=cut

sub report_table_metadata {
    my ( $self, $tm_ds, $ds ) = @_;

    my $metadata = {};

    $metadata->{table} = $ds;
    # $metadata->{where}{$pk_col} = $pk_val;    # pk

    my $columns = $self->scrcfg->dep_table_columns_by_ds($tm_ds, $ds);

    # $metadata->{pkcol}    = $pk_col;
    # $metadata->{fkcol}    = $self->scrcfg->dep_table_fkcol($tm_ds);
    # $metadata->{order}    = $self->scrcfg->dep_table_orderby($tm_ds);
    $metadata->{colslist} = Tpda3::Utils->sort_hash_by_id($columns);

    return $metadata;
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
        print "$data_file not found!\n";
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

=head2 fill_table

Fill Table Matrix widget for I<report> style screens.

=cut

sub fill_table {
    my $self = shift;

    print "fill table ...\n";

    my $tm_ds = 'tm1';

    my $tables = $self->scrcfg->dep_table_hierarchy($tm_ds);
    # print Dumper( $tables );

    print "processing ... $tables->{maintable}\n";
    my $tm_params
        = $self->report_table_metadata( $tm_ds, $tables->{maintable} );

    my $records = $self->_model->table_batch_query($tm_params);

    my $tmx = $self->scrobj('rec')->get_tm_controls($tm_ds);
    $tmx->clear_all();
    $tmx->fill($records);

    my $rex1 = [
        {fact_data => '01.08.2011', fact_scad => '31.08.2011'},
        {fact_data => '01.09.2011', fact_scad => '31.09.2011'},
    ];

    $tmx->fill_details($rex1, 1);

    my $rex2 = [
        {fact_data => '01.10.2011', fact_scad => '31.10.2011'},
        {fact_data => '01.11.2011', fact_scad => '31.11.2011'},
    ];

    $tmx->fill_details($rex2, 4);

    foreach my $table ( @{ $tables->{table} } ) {
        print "processing ... $table\n";
    }
    print " done\n";

    return;
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

1;    # End of Tpda3::Tk::Controller
