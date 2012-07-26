package Tpda3::Tk::Controller;

use strict;
use warnings;
use utf8;
use English;

use Tk;
use Tk::Font;

require Tpda3::Tk::View;

use base qw{Tpda3::Controller};

=head1 NAME

Tpda3::Tk::Controller - The Controller

=head1 VERSION

Version 0.56

=cut

our $VERSION = 0.56;

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

    my $loglevel_old = $self->_log->level();

    $self->_log->trace('Controller new');

    $self->_control_states_init();

    $self->_set_event_handlers();
    $self->_set_event_handlers_keys();

    $self->_set_menus_enable('disabled');    # disable find mode menus

    $self->_check_app_menus();               # disable if no screen

    $self->_log->level($loglevel_old);     # restore default log level

    return $self;
}

=head2 _init

Init App.

=cut

sub _init {
    my $self = shift;

    my $view = Tpda3::Tk::View->new($self->_model);
    $self->{_app}  = $view;                  # an alias as for Wx ...
    $self->{_view} = $view;

    return;
}

=head2 dialog_login

Login dialog.

=cut

sub dialog_login {
    my $self = shift;

    require Tpda3::Tk::Dialog::Login;
    my $pd = Tpda3::Tk::Dialog::Login->new;

    return $pd->login( $self->_view );
}

=head2 application_class

Main application class name.

TODO: This should go to Config?

=cut

sub application_class {
    my $self = shift;

    my $app_name  = $self->_cfg->application->{module};

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

=head2 _set_event_handlers_keys

Setup event handlers for the interface.

=cut

sub _set_event_handlers_keys {
    my $self = shift;

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
                : $self->_view->set_status(
                    $self->localize( 'status', 'not-edit' ),
                    'ms', 'orange' );
        }
    );

    #-- Toggle find mode - F7
    $self->_view->bind(
        '<F7>' => sub {

            # From add mode forbid find mode
            $self->toggle_mode_find()
                if $self->{_rscrcls}
                    and !$self->_model->is_mode('add')
                    and $self->scrcfg()->screen_style() ne 'report';
        }
    );

    #-- Execute find - F8
    $self->_view->bind(
        '<F8>' => sub {
            ( $self->{_rscrcls} and $self->_model->is_mode('find') )
                ? $self->record_find_execute
                : $self->_view->set_status(
                    $self->localize( 'status', 'not-find' ),
                    'ms', 'orange' );
        }
    );

    #-- Execute count - F9
    $self->_view->bind(
        '<F9>' => sub {
            ( $self->{_rscrcls} and $self->_model->is_mode('find') )
                ? $self->record_find_count
                : $self->_view->set_status(
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

=head2 about

About application dialog.

=cut

sub about {
    my $self = shift;

    my $gui = $self->_view;

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

    my $gui = $self->_view;

    require Tpda3::Tk::Dialog::Help;
    my $gd = Tpda3::Tk::Dialog::Help->new;

    $gd->help_dialog($gui);

    return;
}

=head2 repman

Report Manager application dialog.

=cut

sub repman {
    my $self = shift;

    my $gui = $self->_view;

    require Tpda3::Tk::Dialog::Repman;
    my $gd = Tpda3::Tk::Dialog::Repman->new('repman');

    $gd->run_screen($gui);

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
                    unless $self->_model->is_mode('add')
                        or $self->_model->is_mode('edit')
                        or $self->scrcfg()->screen_style() eq 'report';

                $scrobj->$method( $btn_group, $self );
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
