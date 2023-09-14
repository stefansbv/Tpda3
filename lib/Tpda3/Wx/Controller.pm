package Tpda3::Wx::Controller;

# ABSTRACT: The Controller, specific for the Wx interface

use strict;
use warnings;
use utf8;
use English;

use Wx q{:everything};
use Wx::Event qw(EVT_CLOSE EVT_CHOICE EVT_MENU EVT_TOOL EVT_TIMER
    EVT_TEXT_ENTER EVT_AUINOTEBOOK_PAGE_CHANGED
    EVT_LIST_ITEM_ACTIVATED);

require Tpda3::Wx::App;
require Tpda3::Config::Utils;

use base qw{Tpda3::Controller};

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->_init;
    $self->_log->trace('Controller new');
    $self->_control_states_init();
    $self->_set_event_handlers();
    $self->_set_event_handlers_keys();
    $self->_set_menus_state('disabled');    # disable find mode menus
    $self->_check_app_menus();               # disable if no screen
    return $self;
}

sub _init {
    my $self = shift;
    my $app = Tpda3::Wx::App->create($self->model);
    $self->{_app}  = $app;
    $self->{_view} = $app->{_view};
    return;
}

sub start_delay {
    my $self = shift;
    $self->connect_dialog();
    return;
}

sub dialog_login {
    my $self = shift;
    require Tpda3::Wx::Dialog::Login;
    my $pd = Tpda3::Wx::Dialog::Login->new();
    my $return_string = '';
    my $dialog = $pd->login( $self->view );
    if ( $dialog->ShowModal != &Wx::wxID_CANCEL ) {
        $return_string = $dialog->get_login();
    }
    else {
        $return_string = 'shutdown';
    }
    return $return_string;
}

sub screen_module_class {
    my ( $self, $module, $from_tools ) = @_;
    my $module_class;
    if ($from_tools) {
        $module_class = "Tpda3::Wx::Tools::${module}";
    }
    else {
        $module_class = $self->cfg->application_class() . "::${module}";
    }
    ( my $module_file = "$module_class.pm" ) =~ s{::}{/}g;
    return ( $module_class, $module_file );
}

sub _set_event_handlers_keys {
    my $self = shift;
    #-- Make some key bindings
    #   Not implemented
    return;
}

sub _set_event_handler_nb {
    my $self = shift;

    $self->_log->trace('Setup event handler on NoteBook');

    #- NoteBook events

    $self->view->on_notebook_page_changed(
        sub {
            my $page = $self->view->get_nb_current_page;
            $self->view->set_nb_current($page);

          SWITCH: {
                $page eq 'lst'
                    && do { $self->on_page_lst_activate; last SWITCH; };
                $page eq 'rec'
                    && do { $self->on_page_rec_activate; last SWITCH; };
                $page eq  'det'
                    && do { $self->on_page_det_activate; last SWITCH; };
                print "EE: \$page is not in (lst rec det)\n";
            }
        }
    );

    #-- Enter on list item activates record page
    $self->view->on_list_item_activated(
        sub {
            $self->view->get_notebook->SetSelection(0);    # 'rec'
        }
    );

    return;
}

sub set_event_handler_screen {
    my ( $self, $btn_group ) = @_;

    return;
}

sub about {
    my $self = shift;

    # Framework version
    my $PROGRAM_NAME = ' Tpda3 ';
    my $PROGRAM_DESC = 'Tiny Perl Database Application 3';
    my $PROGRAM_VER  = $Tpda3::VERSION || 'development';
    my $LICENSE = Tpda3::Config::Utils->get_license();

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

    my $about = Wx::AboutDialogInfo->new;

    $about->SetName($PROGRAM_NAME);
    $about->SetVersion($PROGRAM_VER);
    $about->SetDescription("$PROGRAM_DESC\nDatabase application framework and run-time");
    $about->SetCopyright('(c) 2010-2023 Ştefan Suciu>');
    $about->SetLicense($LICENSE);
    $about->SetWebSite( 'http://stefansuciu.ro/', 'The Tpda3 home site');
    $about->AddDeveloper( 'Ştefan Suciu' );

    Wx::AboutBox( $about );

    return;
}

sub guide {
    my $self = shift;

    require Tpda3::Wx::Dialog::Help;
    my $gd = Tpda3::Wx::Dialog::Help->new( $self->view );

    $gd->show_html_help('tpda3-manual.htb');

    return;
}

1;

=head1 SYNOPSIS

    use Tpda3::Wx::Controller;

    my $controller = Tpda3::Wx::Controller->new();

    $controller->start();

=head2 new

Constructor method.

=head2 _init

Init App.

=head2 start_delay

Show message, delay the database connection. Delay not yet
implemented.

=head2 dialog_login

Login dialog.

=head2 screen_module_class

Return screen module class and file name.

=head2 _set_event_handlers_keys

Setup event handlers for the interface.

=head2 _set_event_handler_nb

Separate event handler for NoteBook because must be initialized only
after the NoteBook is (re)created and that happens when a new screen is
required (selected from the applications menu) to load.

=head2 set_event_handler_screen

Setup event handlers for the toolbar buttons configured in the
C<scrtoolbar> section of the current screen configuration.

Default usage is for the I<add> and I<delete> buttons attached to the
TableMatrix widget.

 tmatrix_add_row

 tmatrix_remove_row

=head2 about

The About dialog

=head2 guide

Quick help dialog.

=cut
