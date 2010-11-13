package Tpda3::Tk::ToolBar;

use strict;
use warnings;

use Tk;
use base qw{Tk::ToolBar};

=head1 NAME

Tpda3::Tk::ToolBar - Create a toolbar

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Tk::ToolBar;


=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $self, $gui ) = @_;

    # Frame for toolbar
    my $tbf = $gui->Frame->pack(
        -side   => 'top',
        -anchor => 'nw',
        -fill   => 'x',
    );

    $self = $self->SUPER::new(
        $tbf,
        -movable       => 0,
        -side          => 'top',
        -cursorcontrol => 0,       # Problems with cursorcontrol in tests
    );

    return $self;
}

=head2 make_toolbar_buttons

Make main toolbar buttons.

=cut

sub make_toolbar_buttons {
    my ($self, $toolbars, $attribs) = @_;

    # Create buttons in ID order; use sub defined by 'type'
    foreach my $name (@{$toolbars}) {
        my $type = $attribs->{$name}{type};
        $self->$type( $name, $attribs->{$name} );

        # Initial state disabled, except quit and attach button
        next if $name eq 'tb_qt';
        next if $name eq 'tb_at';
        $self->toggle_tool( $name, 'disabled' );
    }

    return;
}

=head2 item_normal

Create a normal toolbar button

=cut

sub _item_normal {
    my ( $self, $name, $attribs ) = @_;

    $self->separator if $attribs->{sep} =~ m{before};

    $self->{$name} = $self->ToolButton(
        -image => $attribs->{icon},
        -tip   => $attribs->{tooltip},
    );

    $self->separator if $attribs->{sep} =~ m{after};

    return;
}

=head2 item_check

Create a check toolbar button

=cut

sub _item_check {
    my ( $self, $name, $attribs ) = @_;

    $self->separator if $attribs->{sep} =~ m{before};

    $self->{$name} = $self->ToolButton(
        -image       => $attribs->{icon},
        -type        => 'Checkbutton',
        -indicatoron => 0,
        -tip         => $attribs->{tooltip},
    );

    $self->separator if $attribs->{sep} =~ m{after};

    return;
}

=head2 get_toolbar_btn

Return a toolbar button when we know the its name

=cut

sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{$name};
}

=head2 toggle_tool

Toggle tool bar button.  If state is defined then set to state do not
toggle.

State can come as 0 | 1 and normal | disabled.

=cut

sub toggle_tool {
    my ($self, $btn_name, $state) = @_;

    my $tb_btn = $self->get_toolbar_btn($btn_name);

    my $other;
    if ($state) {
        if ( $state =~ m{norma|disabled}x ) {
            $other = $state;
        }
        else {
            $other = $state ? 'normal' : 'disabled';
        }
    }
    else {
        $state = $tb_btn->cget(-state);
        $other = $state eq 'normal' ? 'disabled' : 'normal';
    }

    $tb_btn->configure( -state => $other );

    return;
}

=head2 toggle_tool_check

Toggle a toolbar checkbutton.

=cut

sub toggle_tool_check {
    my ($self, $btn_name, $state) = @_;

    my $tb_btn = $self->get_toolbar_btn($btn_name);

    if ($state) {
        $tb_btn->select;
    }
    else {
        $tb_btn->deselect;
    }

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Tk::ToolBar
