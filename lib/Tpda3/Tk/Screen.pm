package Tpda3::Tk::Screen;

use strict;
use warnings;
use Ouch;

use Tpda3::Tk::Entry;

#use Tpda3::Tk::Text;

use Tpda3::Utils;
use Tpda3::Tk::TB;
use Tpda3::Config::Screen;

require Tpda3::Tk::Validation;

=head1 NAME

Tpda3::Tk::Screen - Tpda3 Screen base class.

=head1 VERSION

Version 0.56

=cut

our $VERSION = 0.56;

=head1 SYNOPSIS

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my ( $class, $args ) = @_;

    my $self = {};

    bless $self, $class;

    $self->{scrcfg} = Tpda3::Config::Screen->new($args);

    return $self;
}

=head2 run_screen

The screen layout.

=cut

sub run_screen {
    my ( $self, $nb ) = @_;

    print 'run_screen not implemented in ', __PACKAGE__, "\n";

    return;
}

=head2 get_controls

Get a data structure containing references to the widgets.

=cut

sub get_controls {
    my ($self, $field) = @_;

    # croak "'get_controls' not implemented.\n"
    #     unless exists $self->{controls}
    #         and scalar %{ $self->{controls} };

    if ($field) {
        return $self->{controls}{$field};
    }
    else {
        return $self->{controls};
    }
}

=head2 get_tm_controls

Get a data structure containing references to table matrix widgets.
If TM Id parameter is provided return a reference to that TM object.

=cut

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

=head2 get_rq_controls

Get a HoA reference data structure with the field names that are
required to have values as keys and labels as values.

Usually all fields from the table marked in the I<SQL> structure as
I<NOT NULL>.

=cut

sub get_rq_controls {
    my $self = shift;

    return {} if !exists $self->{rq_controls};

    return $self->{rq_controls};
}

=head2 get_toolbar_btn

Return a toolbar button when we know its name.

=cut

sub get_toolbar_btn {
    my ( $self, $tm_ds, $name ) = @_;

    return $self->{tb}{$tm_ds}->get_toolbar_btn($name);
}

=head2 enable_tool

Toggle tool bar button.  If state is defined then set to state do not
toggle.  State can come as 0 | 1 and normal | disabled.

=cut

sub enable_tool {
    my ( $self, $tm_ds, $btn_name, $state ) = @_;

    ouch 'NoTbButton', "No ToolBar '$tm_ds' ($btn_name)"
        if not defined $self->{tb}{$tm_ds};

    $self->{tb}{$tm_ds}->enable_tool( $btn_name, $state );

    return;
}

=head2 get_bgcolor

Return the background color of the main window.

Must be setup like this in run_screen method of every screen

 my $gui     = $inreg_p->toplevel;
 $self->{bg} = $gui->cget('-background');

=cut

sub get_bgcolor {
    my $self = shift;

    return $self->{bg};
}

=head2 make_toolbar_for_table

Make toolbar for TableMatrix widget, usually with I<add> and I<remove>
buttons.

=cut

sub make_toolbar_for_table {
    my ( $self, $name, $tb_frame ) = @_;

    $self->{tb}{$name} = $tb_frame->TB();

    my ($toolbars) = $self->{scrcfg}->scr_toolbar_names($name);
    my $attribs    = $self->{scrcfg}->app_toolbar_attribs($name);

    $self->{tb}{$name}->make_toolbar_buttons( $toolbars, $attribs );

    return;
}

=head2 tmatrix_add_row

Add new row to the Tk::TableMatrix widget.

=cut

sub tmatrix_add_row {
    my ( $self, $tm_ds ) = @_;

    my $tmx = $self->get_tm_controls($tm_ds);

    $tmx->add_row();

    $self->screen_update();

    return;
}

=head2 tmatrix_remove_row

Remove row to the Tk::TableMatrix widget.

=cut

sub tmatrix_remove_row {
    my ( $self, $tm_ds ) = @_;

    my $tmx = $self->get_tm_controls($tm_ds);

    my $row = $tmx->get_active_row();

    $tmx->remove_row($row) if $row;

    $self->screen_update();

    return;
}

=head2 app_toolbar_names

Configuration for toolbar buttons.

Get Toolbar names as array reference from screen config.

=cut

sub app_toolbar_names {
    my ($self, $name) = @_;

    my ($toolbars) = $self->{scrcfg}->scr_toolbar_names($name);
    my $attribs    = $self->{scrcfg}->app_toolbar_attribs;

    return ( $toolbars, $attribs );
}

=head2 screen_update

Update method. To be overridden in the screen module.

Now called only by L<tmatrix_add_row> and L<tmatrix_remove_row>
methods.

=cut

sub screen_update {
    my $self = shift;

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

1;    # End of Tpda3::Tk::Screen
