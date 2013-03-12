package Tpda3::Tk::Controller;

use strict;
use warnings;
use utf8;
use English;

use Tk;
use Tk::Font;
use Hash::Merge qw(merge);
use Log::Log4perl qw(get_logger :levels);

require Tpda3::Tk::View;

use base qw{Tpda3::Controller};

=head1 NAME

Tpda3::Tk::Controller - The Controller

=head1 VERSION

Version 0.64

=cut

our $VERSION = 0.64;

=head1 SYNOPSIS

    use Tpda3::Tk::Controller;

    my $controller = Tpda3::Tk::Controller->new();

    $controller->start();

=head1 METHODS


=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new();

    $self->_init;

    #$self->_log->level($TRACE);                     # set log level

    $self->_log->trace('Controller new');

    $self->_control_states_init();

    $self->_set_event_handlers();
    $self->_set_event_handlers_keys();

    $self->_set_menus_enable('disabled');    # disable find mode menus

    $self->_check_app_menus();               # disable if no screen

    return $self;
}

=head2 start_delay

Show message, delay the database connection.

=cut

sub start_delay {
    my $self = shift;

    $self->{_view}->after(
        500,
        sub {
            $self->connect_dialog();
        }
    );

    return;
}

=head2 _init

Init App.

=cut

sub _init {
    my $self = shift;

    my $view = Tpda3::Tk::View->new($self->model);
    $self->{_app}  = $view;                  # an alias as for Wx ...
    $self->{_view} = $view;

    return;
}

=head2 dialog_login

Login dialog.

=cut

sub dialog_login {
    my ($self, $error) = @_;

    require Tpda3::Tk::Dialog::Login;
    my $pd = Tpda3::Tk::Dialog::Login->new;

    return $pd->login( $self->view, $error );
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
        $module_class = $self->cfg->application_class() . "::${module}";
    }

    ( my $module_file = "$module_class.pm" ) =~ s{::}{/}g;

    return ( $module_class, $module_file );
}

=head2 _set_event_handlers_keys

Setup event handlers for the interface.

=cut

sub _set_event_handlers_keys {
    my $self = shift;

    #-- Make some key bindings

    #-- Quit Ctrl-q
    $self->view->bind(
        '<Control-q>' => sub {
            return if !defined $self->ask_to_save;
            $self->view->on_close_window;
        }
    );

    #-- Reload - F5
    $self->view->bind(
        '<F5>' => sub {
            $self->model->is_mode('edit')
                ? $self->record_reload()
                : $self->view->set_status(
                    $self->localize( 'status', 'not-edit' ),
                    'ms', 'orange' );
        }
    );

    #-- Toggle find mode - F7
    $self->view->bind(
        '<F7>' => sub {

            # From add mode forbid find mode
            $self->toggle_mode_find()
                if $self->{_rscrcls}
                    and !$self->model->is_mode('add')
                    and $self->scrcfg()->screen('style') ne 'report';
        }
    );

    #-- Execute find - F8
    $self->view->bind(
        '<F8>' => sub {
            ( $self->{_rscrcls} and $self->model->is_mode('find') )
                ? $self->record_find_execute
                : $self->view->set_status(
                    $self->localize( 'status', 'not-find' ),
                    'ms', 'orange' );
        }
    );

    #-- Execute count - F9
    $self->view->bind(
        '<F9>' => sub {
            ( $self->{_rscrcls} and $self->model->is_mode('find') )
                ? $self->record_find_count
                : $self->view->set_status(
                    $self->localize( 'status', 'not-find' ),
                    'ms', 'orange' );
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

    my $nb = $self->view->get_notebook();

    $nb->pageconfigure(
        $page,
        -raisecmd => sub {
            $self->view->set_nb_current($page);

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
        },
    );

    #- Enter on list item activates record page
    $self->view->get_recordlist()->bind(
        '<Return>',
        sub {
            $self->view->get_notebook->raise('rec');
            Tk->break;
        }
    );

    return;
}

=head2 set_event_handler_screen

Setup event handlers for the toolbar buttons configured in the
C<scrtoolbar> section of the current screen configuration.

Default usage is for the I<add> and I<delete> buttons attached to the
TableMatrix widget.

 tmatrix_add_row

 tmatrix_remove_row

=cut

sub set_event_handler_screen {
    my ( $self, $btn_group ) = @_;

    # Get ToolBar button atributes
    my ( $toolbars, $attribs ) = $self->scrcfg->scr_toolbar_names($btn_group);
    foreach my $tb_btn ( @{$toolbars} ) {
        my $method = $attribs->{$tb_btn};
        next unless $method;                 # skip if no method

        $self->_log->info("Handler for $tb_btn: $method ($btn_group)");

        # Check current screen if 'can' method, or fallback to methods
        # in controlller
        my $scrobj
            = $self->scrobj('rec')->can($method)
            ? $self->scrobj('rec')
            : $self;

        $self->scrobj('rec')->get_toolbar_btn( $btn_group, $tb_btn )->bind(
            '<ButtonRelease-1>' => sub {
                return
                    unless $self->model->is_mode('add')
                        or $self->model->is_mode('edit')
                        or $self->scrcfg()->screen('style') eq 'report';

                $scrobj->$method( $btn_group, $self );
                # TODO: what styles can be used?
                if ($self->scrcfg()->screen('style') ne 'report') {
                    $self->model->set_scrdata_rec(1);    # modified
                    $self->toggle_detail_tab;
                }
            }
        );
    }

    return;
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

    foreach my $tm_ds ( keys %{ $self->scrobj('rec')->get_tm_controls } ) {

        my $bindings = $self->scrcfg('rec')->tablebindings->{$tm_ds};

        my $dispatch = {};
        foreach my $bind_type ( keys %{$bindings} ) {
            next unless $bind_type;            # skip if just an empty tag

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

            $self->_log->trace("Setup binding '$bind_type' for '$tm_ds' with:");
            $self->_log->trace( sub { Dumper($bindings) } );
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

=head2 about

About application dialog.

=cut

sub about {
    my $self = shift;

    my $gui = $self->view;

    # Create a dialog.
    my $dbox = $gui->DialogBox(
        -title   => 'Despre ... ',
        -buttons => ['Close'],
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
    my $app_class = $self->cfg->application_class();
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
    $text->insert( 'end', "Author: Ștefan Suciu\n", 'normal' );
    $text->insert( 'end', "Copyright 2010-2012\n", 'normal' );
    $text->insert( 'end', "GNU General Public License (GPL)\n", 'normal' );
    $text->insert( 'end', 'stefan@s2i2.ro',
        'italic' );
    $text->insert( 'end', "\n\n" );
    $text->insert( 'end', "$APP_NAME\n", 'normal' );
    $text->insert( 'end', "Version " . $APP_VER . "\n", 'normal' );
    $text->insert( 'end', "\n\n" );
    $text->insert( 'end', "Perl " . $PERL_VERSION . "\n", 'normal' );
    $text->insert( 'end', "Tk v" . $Tk::VERSION . "\n", 'normal' );

    $text->configure( -state => 'disabled' );
    $text->pack(
        -expand => 1,
        -fill   => 'both'
    );
    $dbox->Show();
}

=head2 guide

Quick help dialog.

=cut

sub guide {
    my $self = shift;

    if ($^O eq 'Win32') {
        system("cmd /c start guide.chm");
    }
    else {
        my $gui = $self->view;
        require Tpda3::Tk::Dialog::Help;
        my $gd = Tpda3::Tk::Dialog::Help->new;
        $gd->help_dialog($gui);
    }

    return;
}

=head2 repman

Report Manager application dialog.

=cut

sub repman {
    my $self = shift;

    my $gui = $self->view;

    require Tpda3::Tk::Dialog::Repman;
    my $gd = Tpda3::Tk::Dialog::Repman->new('repman');

    $gd->run_screen($gui);

    return;
}

=head2 tmshr_fill_table

Fill Table Matrix widget for I<report> style screens.

The field with the attribute 'datasource == !count!' is used to number
the rows and also as an index to the I<expand data>.

Builds a tree with the C<Tpda::Tree> module, a subclass of
C<Tree::DAG_Node>.

=cut

sub tmshr_fill_table {
    my $self = shift;

    my $tm_ds  = 'tm1';                      # hardwired configuration
    my $header = $self->scrcfg('rec')->dep_table_header_info($tm_ds);

    #- Make a tree

    require Tpda3::Tree;
    my $tree = Tpda3::Tree->new({});
    $tree->name('root');

    my $columns  = $self->scrcfg()->deptable($tm_ds, 'columns');
    my $colnames = Tpda3::Utils->sort_hash_by_id($columns);
    $tree->set_header($colnames);

    #-- Get data

    my $level = 0;                           # maintable level

    my $levels = $self->scrcfg()->deptable( $tm_ds, 'datasources', 'level' );
    my $last_level = $#{$levels};

    my $tmx = $self->scrobj('rec')->get_tm_controls($tm_ds);

    my $mainmeta = $self->report_table_metadata( $tm_ds, $level );
    my $nodename = $mainmeta->{pkcol};
    my $countcol = $mainmeta->{rowcount};
    my $sum_up_cols = $self->get_table_sumup_cols( $tm_ds, $level );

    my ($records, $levelmeta) = $self->model->report_data($mainmeta);

    #- Add main records to the tree

    foreach my $rec ( @{$records} ) {
        my $record = $self->tmshr_format_record( $level, $rec, $header );
        $tree->by_name('root')->new_daughter($record)
            ->name( $nodename . ':' . $rec->{$countcol} );
    }

    $level++;                                # next level

    #-- Add detail records to the tree

    my $uplevelmeta = $levelmeta;
    while ( $level <= $last_level ) {
        my $metadata = $self->report_table_metadata( $tm_ds, $level );
        my $levelmeta
            = $self->tmshr_process_level( $level, $uplevelmeta, $metadata,
            $countcol, $header, $tree );
        $uplevelmeta = $levelmeta;
        $level++;
    }

    #- Fill TMSHR widget

    #print map "$_\n", @{ $tree->draw_ascii_tree }; # for debug
    $tree->clear_totals($sum_up_cols, 2); # hardwired numeric scale
    $tree->sum_up($sum_up_cols, 2);
    $tree->format_numbers($sum_up_cols, 2);
    #$tree->print_wealth($sum_up_cols->[0]); # for debug

    my ($maindata, $expdata) = $tree->get_tree_data();
    $tmx->clear_all;
    $tmx->fill_main($maindata, $countcol);
    $tmx->fill_details($expdata);

    return;
}

=head2 tmshr_process_level

For each record of the upper level (meta) data, make new daughter
nodes in the tree. The node names are created from the tables primary
column name and the I<rowcount> column value.

=cut

sub tmshr_process_level {
    my ($self, $level, $uplevelds, $metadata, $countcol, $header, $tree) = @_;

    my $nodebasename = $metadata->{pkcol};

    my $newleveldata = {};
    while ( my ( $parent_row, $uplevelrecord ) = each( %{$uplevelds} ) ) {
        foreach my $uprec ( @{$uplevelrecord} ) {
            while ( my ( $row, $mdrec ) = each( %{$uprec} ) ) {
                $metadata->{where} = $mdrec;
                my ( $records, $leveldata )
                    = $self->model->report_data( $metadata, $row );
                foreach my $rec ( @{$records} ) {
                    my $nodename0 = ( keys %{$mdrec} )[0] . ':' . $row;
                    my $record
                        = $self->tmshr_format_record( $level, $rec, $header );
                    $tree->by_name($nodename0)->new_daughter($record)
                        ->name( $nodebasename . ':' . $rec->{$countcol} );
                }
                $newleveldata = merge( $newleveldata, $leveldata );
            }
        }
    }

    return $newleveldata;
}

=head2 tmshr_format_record

TMSHR format record.

=cut

sub tmshr_format_record {
    my ($self, $level, $rec, $header) = @_;

    my $record = $self->record_merge_columns( $rec, $header );
    foreach my $field ( keys %{$record} ) {
        my $attribs = $self->flatten_cfg($level, $header->{columns}{$field});
        $rec->{$field}
            = $self->tmshr_compute_value( $field, $record, $attribs );
    }

    return $rec;
}

=head2 tmshr_compute_value

TODO

=cut

sub tmshr_compute_value {
    my ($self, $field, $record, $attribs) = @_;

    die "$field field's config is EMPTY" unless %{$attribs};

    my ( $col, $validtype, $width, $numscale, $datasource )
        = @$attribs{ 'id', 'datatype', 'width', 'numscale', 'datasource' };

    my $value;
    if ( $datasource =~ m{=count|=sumup} ) {

        # Count or Sum Up
        $value = $record->{$field};
    }
    elsif ( $datasource =~ m{=(.*)} ) {
        my $funcdef = $1;
        if ($funcdef) {

            # Formula
            my $ret = $self->tmshr_get_function( $field, $funcdef );
            my ( $func, $vars ) = @{$ret};

            # Function args are numbers, avoid undef
            my @args = map {
                defined( $record->{$_} ) ? $record->{$_} : 0
            } @{$vars};

            $value = $func->(@args); # computed value
        }
    }
    else {
        $value = $record->{$field};
    }

    $value = q{} unless defined $value;    # empty value
    $value =~ s/[\n\t]//g;                 # delete control chars

    if ( $validtype eq 'numeric' ) {
        $value = 0 unless $value;
        if ( defined $numscale ) {
            $value = sprintf( "%.${numscale}f", $value );
        }
        else {
            $value = sprintf( "%.0f", $value );
        }
    }

    return $value;
}

=head2 tmshr_get_function

Make a reusable anonymous function to compute a field's value, using
the definition from the screen configuration and the Math::Symbolic
module.

It's intended use is for simple functions, like in this example:

  datasource => '=quantityordered*priceeach'

Supported operations: arithmetic (-+/*).

=cut

sub tmshr_get_function {
    my ($self, $field, $funcdef) = @_;

    return $self->{$field} if exists $self->{$field}; # don't recreate it

    unless ($field and $funcdef) {
        die "$field field's compute is EMPTY" unless $funcdef;
    }

    # warn "new function for: $field = ($funcdef)\n";

    ( my $varsstr = $funcdef ) =~ s{[-+/*]}{ }g; # replace operator with space

    my $tree = Math::Symbolic->parse_from_string($funcdef);
    my @vars = split /\s+/, $varsstr; # extract the names of the variables
    unless ($self->tmshr_check_varnames(\@vars) ) {
        die "Computed variable names don't match field names!";
    }

    my ($sub) = Math::Symbolic::Compiler->compile_to_sub( $tree, \@vars );

    $self->{$field} = [$sub, \@vars];        # save for later use

    return $self->{$field};
}

=head2 tmshr_check_varnames

Check if arguments variable names match field names.

=cut

sub tmshr_check_varnames {
    my ( $self, $vars ) = @_;

    my $tm_ds = 'tm1';
    my $header = $self->scrcfg('rec')->dep_table_header_info($tm_ds);

    my $check = 1;
    foreach my $field ( @{$vars} ) {
        unless ( exists $header->{columns}{$field} ) {
            $check = 0;
            last;
        }
    }

    return $check;
}

=head2 set_mnemonic

Dialog to set the default mnemonic - application configuration to be
used when none is specified.

=cut

sub set_mnemonic {
    my $self = shift;

    require Tpda3::Tk::Dialog::AppList;
    my $dal = Tpda3::Tk::Dialog::AppList->new();
    $dal->show_app_list($self->view);

    return;
}

=head2 set_app_configs

Dialog to set runtime configurations for Tpda3.

=cut

sub set_app_configs {
    my $self = shift;

    require Tpda3::Tk::Dialog::Configs;
    my $dc = Tpda3::Tk::Dialog::Configs->new();
    $dc->show_cfg_dialog($self->view);

    return;
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

1;    # End of Tpda3::Tk::Controller
