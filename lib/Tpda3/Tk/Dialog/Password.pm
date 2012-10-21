package Tpda3::Tk::Dialog::Password;

use strict;
use warnings;

use Tk;

=head1 NAME

Tpda3::Tk::Dialog::Password - Dialog for user name and password

=head1 VERSION

Version 0.58

=cut

our $VERSION = 0.58;

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::Password;

    my $fd = Tpda3::Tk::Dialog::Password->new;

    $fd->get_password($self);

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my $type = shift;

    my $self = {};

    bless( $self, $type );

    return $self;
}

=head2 get_password

Show dialog

=cut

sub get_password {
    my ( $self, $mw, $user ) = @_;

    $self->{bg}  = $mw->cget('-background');
    $self->{dlg} = $mw->DialogBox(
        -title   => 'Password',
        -buttons => [qw/Accept Cancel/],
    );

    #- Frame

    my $frame = $self->{dlg}->LabFrame(
        -foreground => 'blue',
        -label      => 'Password',
        -labelside  => 'acrosstop',
    );
    $frame->pack(
        -padx  => 10,
        -pady  => 10,
        -ipadx => 5,
        -ipady => 5,
    );

    #-- User

    my $luser = $frame->Label( -text => 'User:', );
    $luser->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 5,
    );
    my $euser = $frame->Entry(
        -width              => 30,
        -background         => 'white',
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $euser->form(
        -top  => [ '&', $luser, 0 ],
        -left => [ %0,  90 ],
    );

    #-- Pass

    my $lpass = $frame->Label( -text => 'Password:', );
    $lpass->form(
        -top     => [ $luser, 8 ],
        -left    => [ %0,     0 ],
        -padleft => 5,
    );
    my $epass = $frame->Entry(
        -width              => 30,
        -background         => 'white',
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
        -show               => '*',
    );
    $epass->form(
        -top  => [ '&', $lpass, 0 ],
        -left => [ %0,  90 ],
    );

    $euser->focus;

    if ( $user ) {
        $euser->delete( 0, 'end' );
        $euser->insert( 0, $user );
        $euser->xview('end');
        $epass->focus;
    }

    my $answer = $self->{dlg}->Show();

    if ( $answer eq 'Accept' ) {
        my $pass = $epass->get;

        if ( $pass ) {
            return $pass;
        }
    }

    return;
}

1;    # End of Tpda3::Tk::Dialog::Password
