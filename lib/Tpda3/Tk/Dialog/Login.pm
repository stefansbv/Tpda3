package Tpda3::Tk::Dialog::Login;

use strict;
use warnings;

use Tk;

require Tpda3::Config;
require Tpda3::Utils;

=head1 NAME

Tpda3::Tk::Dialog::Login - Dialog for user name and password

=head1 VERSION

Version 0.67

=cut

our $VERSION = 0.67;

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::Login;

    my $fd = Tpda3::Tk::Dialog::Login->new;

    $fd->login($self);

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

=head2 login

Show dialog

=cut

sub login {
    my ( $self, $mw, $message ) = @_;

    $self->{bg}  = $mw->cget('-background');
    $self->{dlg} = $mw->DialogBox(
        -title   => 'Login',
        -buttons => [qw/Accept Cancel/],
    );

    #- Frame

    my $frame = $self->{dlg}->LabFrame(
        -foreground => 'blue',
        -label      => 'Login',
        -labelside  => 'acrosstop',
    );
    $frame->pack(
        -padx  => 10,
        -pady  => 10,
        -ipadx => 7,
        -ipady => 5,
    );

    #-- User

    my $luser = $frame->Label( -text => 'User', );
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

    my $lpass = $frame->Label( -text => 'Password', );
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

    #-- Message

    my ( $text, $color )
        = $message ? Tpda3::Utils->parse_message($message) : q{};
    $color ||= 'black';

    my $lmessage = $self->{dlg}->Label(
        -text       => $text,
        -width      => 44,
        -relief     => 'groove',
        -foreground => $color,
    )->pack(
        -padx => 0,
        -pady => 0,
    );

    $euser->focus;

    my $cfg = Tpda3::Config->instance();

    # User from parameter
    if ( $cfg->user ) {
        $euser->delete( 0, 'end' );
        $euser->insert( 0, $cfg->user );
        $euser->xview('end');
        $epass->focus;
    }

    my $answer = $self->{dlg}->Show();
    my $return_choice = '';

    if ( $answer eq 'Accept' ) {
        my $user = $euser->get;
        my $pass = $epass->get;

        my $cfg = Tpda3::Config->instance();
        $cfg->user($user) if $user;
        $cfg->pass($pass) if $pass;
    }
    else {
        $return_choice = 'cancel';
    }

    return $return_choice;
}

1;    # End of Tpda3::Tk::Dialog::Login
