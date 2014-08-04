package Tpda3::Wx::ComboDate;

# ABSTRACT: Wx::ComboCtrl with a Calendar popup

use strict;
use warnings;

use Wx qw{wxTE_PROCESS_ENTER};
use Tpda3::Wx::DatePopup;
use base qw{Tpda3::Wx::ComboCtrl};

=head1 SYNOPSIS

    use Tpda3::Wx::ComboDate;
    ...

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $parent, $id, $pos, $size, $style ) = @_;

    my $self = $class->SUPER::new(
        $parent,
        $id || -1,
        q{},
        $pos  || [ -1, -1 ],
        $size || [ -1, -1 ],
        ( $style || 0 ) | wxTE_PROCESS_ENTER
    );
    my $popup = Tpda3::Wx::DatePopup->new();
    $self->SetPopupControl( $popup );

    return $self;
}

1;
