package Tpda3::Tk::Screen;

use strict;
use warnings;
use Carp;

use Tpda3::Tk::Entry;
#use Tpda3::Tk::Text;

use Tpda3::Tk::ToolBar;
use Tpda3::Tk::Validation;

=head1 NAME

Tpda3::Tk::Screen - Tpda3 Screen base class.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my $class = shift;

    return bless {}, $class;
}

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $inreg_p ) = @_;

    print 'run_screen not implemented in ', __PACKAGE__, "\n";

    return;
}

=head2 get_controls

Get a data structure containing references to the widgets.

=cut

sub get_controls {
    my $self = shift;

    # croak "'get_controls' not implemented.\n"
    #     unless exists $self->{controls}
    #         and scalar %{ $self->{controls} };

    return $self->{controls};
}

=head2 get_tm_controls

Get a data structure containing references to table matrix widgets.
If TM Id parameter is provided return a reference to that TM object.

=cut

sub get_tm_controls {
    my ( $self, $tm ) = @_;

    return {} if ! exists $self->{tm_controls};

    if ($tm) {
        return ${ $self->{tm_controls}{rec}{$tm} }->Subwidget('scrolled');
    }
    else {
        return $self->{tm_controls}{rec};
    }
}

=head2 get_toolbar_btn

Return a toolbar button when we know its name.

=cut

sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{tb}->get_toolbar_btn($name);
}

=head2 enable_tool

Toggle tool bar button.  If state is defined then set to state do not
toggle.  State can come as 0 | 1 and normal | disabled.

=cut

sub enable_tool {
    my ($self, $btn_name, $state) = @_;

    return if not defined $self->{tb};

    $self->{tb}->enable_tool($btn_name, $state);

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

Make toolbar with add and remove buttons.

=cut

sub make_toolbar_for_table {
    my ($self, $tb_frame, $toolbar) = @_;

    $self->{tb} = Tpda3::Tk::ToolBar->new($tb_frame);

    my $cfg = Tpda3::Config->instance();

    my $attribs = $cfg->toolbar2;

    $self->{tb}->make_toolbar_buttons($toolbar, $attribs);

    return;
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

1; # End of Tpda3::Tk::Screen
