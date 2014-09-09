package Tpda3::Tk::TB;

# ABSTRACT: Create a tool-bar

use strict;
use warnings;

use Tk;
use base qw{Tk::Derived Tk::ToolBar};

Tk::Widget->Construct('TB');


sub Populate {
    my ( $self, $args ) = @_;

    $self->SUPER::Populate($args);

    return;
}


sub make_toolbar_buttons {
    my ( $self, $toolbars, $attribs ) = @_;

    # Create buttons in ID order; use sub defined by 'type'
    foreach my $name ( @{$toolbars} ) {
        my $type = $attribs->{$name}{type};
        $self->$type( $name, $attribs->{$name} );

        # Initial state disabled, except quit and attach button
        next if $name eq 'tb_qt';
        next if $name eq 'tb_at';

        # Skip buttons from Help window
        next if $name eq 'tb3gd';
        next if $name eq 'tb3gp';
        next if $name eq 'tb3qt';
        # And from RepMan window
        next if $name eq 'tb4pr';
        next if $name eq 'tb4qt';

        $self->enable_tool( $name, 'disabled' );
    }

    return;
}


sub _item_normal {
    my ( $self, $name, $attribs ) = @_;

    $self->separator if $attribs->{sep} =~ m{before};

    my $callback = ref $attribs->{method} eq 'CODE' ? $attribs->{method} : '';

    $self->{$name} = $self->ToolButton(
        -tip => $attribs->{tooltip},
    );

    $attribs->{text}
        ? $self->{$name}->configure( -text  => $attribs->{text} )
        : $self->{$name}->configure( -image => $attribs->{icon} )
        ;

    $self->{$name}->configure( -command => $callback) if $callback;

    $self->separator if $attribs->{sep} =~ m{after};

    return;
}


sub _item_check {
    my ( $self, $name, $attribs ) = @_;

    $self->separator if $attribs->{sep} =~ m{before};

    my $callback = ref $attribs->{method} eq 'CODE' ? $attribs->{method} : '';

    $self->{$name} = $self->ToolButton(
        -image       => $attribs->{icon},
        -type        => 'Checkbutton',
        -tip         => $attribs->{tooltip},
        -indicatoron => 0,
    );

    $self->{$name}->configure( -command => $callback) if $callback;

    $self->separator if $attribs->{sep} =~ m{after};

    return;
}


sub _item_legend {
    my ( $self, $name, $attribs ) = @_;

    $self->separator if $attribs->{sep} =~ m{before};

    my $label = $attribs->{label} || 'row';
    my $color = $attribs->{color} || 'white';

    $self->{$name} = $self->ToolLabel(
        -text => $label,
        -bg   => $color,
    );

    $self->separator if $attribs->{sep} =~ m{after};

    return;
}


sub get_toolbar_btn {
    my ( $self, $name ) = @_;

    return $self->{$name};
}


sub enable_tool {
    my ( $self, $btn_name, $state ) = @_;

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
        $state = $tb_btn->cget('-state');
        $other = $state eq 'normal' ? 'disabled' : 'normal';
    }

    $tb_btn->configure( -state => $other );

    return;
}


sub toggle_tool_check {
    my ( $self, $btn_name, $state ) = @_;

    my $tb_btn = $self->get_toolbar_btn($btn_name);

    if ($state) {
        $tb_btn->select;
    }
    else {
        $tb_btn->deselect;
    }

    return;
}

1;

=head1 SYNOPSIS

    use Tpda3::Tk::TB;

    $self->{_tb} = $self->TB(qw/-movable 0 -side top -cursorcontrol 0/);

    $self->{_tb}->make_toolbar_buttons( $toolbars, $attribs );

=head2 Populate

Constructor method.

=head2 make_toolbar_buttons

Make main toolbar buttons.

=head2 _item_normal

Create a normal toolbar button.

A callback can be defined in the attribs data structure like a
methodname string or a code reference.

A text attribute takes precedence over an icon attribute.

=head2 _item_check

Create a check toolbar button.

A callback can be defined in the attribs data structure like a
methodname string or a code reference.

=head2 _item_legend

Create a label toolbar button used as a color legend for a table.

=head2 get_toolbar_btn

Return a toolbar button when we know the its name

=head2 enable_tool

Toggle tool bar button.  If state is defined then set to state do not
toggle.

State can come as 0 | 1 and normal | disabled.

=head2 toggle_tool_check

Toggle a toolbar checkbutton.

=cut
