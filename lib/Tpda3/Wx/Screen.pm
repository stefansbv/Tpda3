package Tpda3::Wx::Screen;

# ABSTRACT: The Tpda3 application's screen base class

use strict;
use warnings;
use Carp;

use Wx qw(:misc :frame :toolbar :textctrl :aui);
use Wx::Event qw();
use Wx::ArtProvider qw(:artid);

require Tpda3::Utils;
require Tpda3::Config::Screen;

sub new {
    my ( $class, $args ) = @_;

    my $self = {};

    bless $self, $class;

    $self->{scrcfg} = Tpda3::Config::Screen->new($args);

    return $self;
}

sub run_screen {
    my ( $self, $nb ) = @_;

    print 'run_screen not implemented in ', __PACKAGE__, "\n";

    return;
}

sub get_controls {
    my ($self, $field) = @_;

    if ($field) {
        return $self->{controls}{$field};
    }
    else {
        return $self->{controls};
    }
}

sub get_tm_controls {
    my ( $self, $tm_ds ) = @_;

    return {} if !exists $self->{tm_controls};

    if ($tm_ds) {
        return ${ $self->{tm_controls}{rec}{$tm_ds} };
    }
    else {
        return $self->{tm_controls}{rec};
    }
}

sub get_rq_controls {
    my $self = shift;

    return {} if !exists $self->{rq_controls};

    return $self->{rq_controls};
}

sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{tb}->get_toolbar_btn($name);
}

sub enable_tool {
    my ( $self, $btn_name, $state ) = @_;

    return if not defined $self->{tb};

    $self->{tb}->enable_tool( $btn_name, $state );

    return;
}

sub get_bgcolor {
    my $self = shift;

    return $self->{bg};
}

sub app_toolbar_names {
    my ($self, $name) = @_;

    my ($toolbars) = $self->{scrcfg}->scr_toolbar_names($name);
    my $attribs    = $self->{scrcfg}->app_toolbar_attribs;

    return ( $toolbars, $attribs );
}

sub make_toolbar_for_table {
    my ( $self, $name, $tb_frame, $article_sbs ) = @_;

    # $self->{tb}{$name} = $tb_frame->TB();

    # my ($toolbars) = $self->{scrcfg}->scr_toolbar_names($name);
    # my $attribs    = $self->{scrcfg}->app_toolbar_attribs($name);

    # $self->{tb}{$name}->make_toolbar_buttons( $toolbars, $attribs );

    my $tb1 = Wx::ToolBar->new(
        $tb_frame, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxTB_HORIZONTAL | wxNO_BORDER | wxTB_FLAT, 5050,
    );
    # $tb1->AddTool( -1, "Test", Wx::ArtProvider::GetBitmap(wxART_ERROR) );
    # $tb1->AddTool( -1, "Test", Wx::ArtProvider::GetBitmap(wxART_ERROR) );
    # $tb1->AddTool( -1, "Test", Wx::ArtProvider::GetBitmap(wxART_ERROR) );
    $tb1->Realize;

    return $tb1;
}

1;

=head1 SYNOPSIS

=head2 new

Constructor method.

=head2 run_screen

The screen layout

=head2 get_controls

Get a data structure containing references to the widgets.

=head2 get_tm_controls

Get a data structure containing references to table (grid) widgets.
If TM Id parameter is provided return a reference to that TM object.

=head2 get_rq_controls

Get a HoA reference data structure with the field names that are
required to have values as keys and labels as values.

Usually all fields from the table marked in the I<SQL> structure as
I<NOT NULL>.

=head2 get_toolbar_btn

Return a toolbar button when we know the its name

=head2 enable_tool

Toggle toolbar button.  If state is defined then set to state do not
toggle.  State can come as 0 | 1 and normal | disabled.

=head2 get_bgcolor

Return the background color of the main window.

Must be setup like this in run_screen method of every screen

...

=head2 app_toolbar_names

Configuration for toolbar buttons.

Get Toolbar names as array reference from screen config.

=head2 make_toolbar_for_table

Make toolbar for Table control, usually with I<add> and I<remove>
buttons.

=cut
