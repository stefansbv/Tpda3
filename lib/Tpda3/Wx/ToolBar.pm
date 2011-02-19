package Tpda3::Wx::ToolBar;

use strict;
use warnings;

use Wx qw(:everything);
use base qw{Wx::ToolBar};

=head1 NAME

Tpda3::Wx::ToolBar - Create a toolbar

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Tpda3::Wx::ToolBar;
    $self->SetToolBar( Tpda3::Wx::ToolBar->new( $self, wxADJUST_MINSIZE ) );
    $self->{_tb} = $self->GetToolBar;
    $self->{_tb}->Realize;

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $self, $gui ) = @_;

    $self = $self->SUPER::new(
        $gui,
        -1,
        [-1, -1],
        [-1, -1],
        wxTB_HORIZONTAL | wxNO_BORDER | wxTB_FLAT | wxTB_DOCKABLE,
        5050,
    );

    $self->SetToolBitmapSize( Wx::Size->new( 16, 16 ) );
    $self->SetMargins( 4, 4 );

    return $self;
}

=head2 make_toolbar_buttons

Make main toolbar buttons.

=cut

sub make_toolbar_buttons {
    my ($self, $toolbars, $attribs, $ico_path) = @_;

    # Create buttons in ID order; use sub defined by 'type'
    foreach my $name (@{$toolbars}) {
        my $type = $attribs->{$name}{type};
        $self->$type( $name, $attribs->{$name}, $ico_path );

        # Initial state disabled, except quit and attach button
        next if $name eq 'tb_qt';
        next if $name eq 'tb_at';
        $self->enable_tool( $name, 0 );      # 0 = disabled
    }

    return;
}

=head2 _item_normal

Create a normal toolbar button

=cut

sub _item_normal {
    my ($self, $name, $attribs, $ico_path) = @_;

    $self->AddSeparator if $attribs->{sep} =~ m{before};

    # Add the button
    $self->{$name} = $self->AddTool(
        $attribs->{id},
        $self->make_bitmap( $ico_path, $attribs->{icon} ),
        wxNullBitmap,
        wxITEM_NORMAL,
        undef,
        $attribs->{tooltip},
        $attribs->{help},
    );

    $self->AddSeparator if $attribs->{sep} =~ m{after};

    return;
}

=head2 _item_check

Create a check toolbar button

=cut

sub _item_check {
    my ($self, $name, $attribs, $ico_path) = @_;

    $self->AddSeparator if $attribs->{sep} =~ m{before};

    # Add the button
    $self->{$name} = $self->AddTool(
        $attribs->{id},
        $self->make_bitmap( $ico_path, $attribs->{icon} ),
        wxNullBitmap,
        wxITEM_CHECK,
        undef,
        $attribs->{tooltip},
        $attribs->{help},
    );

    $self->AddSeparator if $attribs->{sep} =~ m{after};

    return;
}

=head2 get_toolbar_btn

Return a toolbar button by name.

=cut

sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{$name};
}

=head2 make_bitmap

Create and return a bitmap object, of any type.

TODO: Put (replace) full path to the iconfile to attribs

=cut

sub make_bitmap {
    my ($self, $ico_path, $icon) = @_;

    my $bmp = Wx::Bitmap->new(
        $ico_path . "/$icon.gif",
        wxBITMAP_TYPE_ANY,
    );

    return $bmp;
}

=head2 _item_list

Create a list toolbar button. Not used.

=cut

sub _item_list {

    my ($self, $name, $attribs) = @_;

    # 'sep' must be at least empty string in config;
    $self->AddSeparator if $attribs->{sep} =~ m{before};

    my $output =  Wx::Choice->new(
        $self,
        $attribs->{id},
        [-1,  -1],
        [100, -1],
        $self->{options},
        # wxCB_SORT,
    );

    $output->SetStringSelection($self->{options}[0]); # Explicit default

    $self->AddControl( $output );

    $self->AddSeparator if $attribs->{sep} =~ m{after};

    return;
}

=head2 get_choice_options

Return all options or the name of the option with index

=cut

sub get_choice_options {
    my ($self, $index) = @_;

    # Options for Wx::Choice from the ToolBar
    # Default is Excel with idx = 0
    $self->{options} = [ 'Calc', 'CSV', 'Excel' ];

    if (defined $index) {
        return $self->{options}[$index];
    }
    else {
        return $self->{options};
    }
}

=head2 enable_tool

Toggle tool bar button.  If state is defined then set to state, do not
toggle.

State can come as 0 | 1 and normal | disabled.  Because toolbar.yml is
used for both Tk and Wx, this sub is more complex that is should be.

=cut

sub enable_tool {
    my ($self, $btn_name, $state) = @_;

    # print " $btn_name, $state\t";

    my $tb_btn_id = $self->get_toolbar_btn($btn_name)->GetId;

    my $new_state;
    if ( defined $state ) {

      SWITCH: for ($state) {
            /^$/        && do { $new_state = 0; last SWITCH; };
            /normal/i   && do { $new_state = 1; last SWITCH; };
            /disabled/i && do { $new_state = 0; last SWITCH; };

            # If other value like 1 | 0
            $new_state = $state ? 1 : 0;
        }
    }
    else {
        # Undef state: toggle
        # print " toggle ";
        $new_state = !$self->GetToolState($tb_btn_id);
    }

    # print "set to $new_state\n";
    $self->EnableTool($tb_btn_id, $new_state);

    return;
}

=head2 toggle_tool_check

Toggle a toolbar checkbutton.  State can come as 0 | 1.

=cut

sub toggle_tool_check {
    my ($self, $btn_name, $state) = @_;

    my $tb_btn_id = $self->get_toolbar_btn($btn_name)->GetId;

    $self->ToggleTool($tb_btn_id, $state);

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 - 2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of Tpda3::Wx::App
