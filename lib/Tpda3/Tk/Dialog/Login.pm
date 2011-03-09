package Tpda3::Tk::Dialog::Login;

use strict;
use warnings;

use Tk;

use Tpda3::Config;

=head1 NAME

Tpda3::Tk::Dialog::Login - Dialog for user name and password

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

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
    my ( $self, $mw ) = @_;

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
        -padx  => 10, -pady  => 10,
        -ipadx => 5,  -ipady => 5,
    );

    #-- User

    my $luser = $frame->Label(
        -text => 'User:',
    );
    $luser->form(
        -top  => [ %0, 0 ],
        -left => [ %0, 0 ],
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

    my $lpass = $frame->Label(
        -text => 'Password:',
    );
    $lpass->form(
        -top  => [ $luser, 8 ],
        -left => [ %0,     0 ],
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

    my $cfg = Tpda3::Config->instance();

    # User from parameter
    if ( $cfg->user ) {
        $euser->delete( 0, 'end' );
        $euser->insert( 0, $cfg->user );
        $euser->xview('end');
        $epass->focus;
    }

    my $answer = $self->{dlg}->Show();

    if ( $answer eq 'Accept' ) {
        my $user = $euser->get;
        my $pass = $epass->get;

        if ( $user && $pass ) {
            my $cfg = Tpda3::Config->instance();
            $cfg->user($user);
            $cfg->pass($pass);
            # $self->{dlg}{selected_button} = 'Accept';
        }
        else {
            return;
        }
    }
    else {
        $mw->destroy;
    }
}

1; # End of Tpda3::Tk::Dialog::Login
