package Tpda3::Wx::App;

# ABSTRACT: The Wx Perl application class

use strict;
use warnings;

use Wx q(:everything);
use base qw(Wx::App);

require Tpda3::Wx::View;

sub create {
    my $self  = shift->new;
    my $model = shift;

    $self->{_view} = Tpda3::Wx::View->new(
        $model, undef, -1, 'Tpda3::wxPerl',
        [ -1, -1 ],
        [ -1, -1 ],
        wxDEFAULT_FRAME_STYLE,
    );

    $self->{_view}->Show(1);

    return $self;
}

sub OnInit {1}

1;

=head1 SYNOPSIS

    use Tpda3::Wx::App;
    use Tpda3::Wx::Controller;

    $gui = Tpda3::Wx::App->create();

    $gui->MainLoop;

=head2 create

Constructor method.

=head2 OnInit

Override OnInit from WxPerl

=cut
