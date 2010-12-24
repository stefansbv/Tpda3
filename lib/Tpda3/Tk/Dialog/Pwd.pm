package Tpda3::Tk::Dialog::Pwd;

use strict;
use warnings;

use Tk;

use Tpda3::Config;

=head1 NAME

Tpda3::Tk::Dialog::Pwd - Dialog for user name and password

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::Pwd;

    my $fd = Tpda3::Tk::Dialog::Pwd->new;

    $fd->run_dialog($self);

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

=head2 run_dialog

Show dialog

=cut

sub run_dialog {
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
        -padx  => 10,
        -pady  => 10,
        -ipadx => 5,
    );

    #-- User

    my $luser = $frame->Label(
        -text => 'User:',
    );
    $luser->form(
        -left => [ %0, 0 ],
        -top  => [ %0, 0 ],
        -padx => 5,
        -pady => 5,
    );
    my $euser = $frame->Entry(
        -width => 30,
        -bg    => 'white',
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
        -left => [ %0,     0 ],
        -top  => [ $luser, 0 ],
        -padx => 5,
        -pady => 5,
    );
    my $epass = $frame->Entry(
        -width => 30,
        -bg    => 'white',
        -show  => '*',
    );
    $epass->form(
        -top  => [ '&', $lpass, 0 ],
        -left => [ %0,  90 ],
    );

    # $self->{dlg}->Subwidget('B_Accept')->configure(
    #     -command => [ \&ok_command, $self, \$euser, \$epass ],
    # );

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
        $mw->on_quit;
    }
}

1; # End of Tpda3::Tk::Dialog::Pwd
