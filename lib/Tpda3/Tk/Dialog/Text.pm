package Tpda3::Tk::Dialog::Text;

# ABSTRACT: Dialog for messages

use strict;
use warnings;
use utf8;
use Locale::TextDomain 1.20 qw(Tpda3);
use Tk::DialogBox;
use Tk::Text;

#require Tpda3::Utils;

sub new {
    my ($class, $view, $opts) = @_;
    my $self = {
        view   => $view,
        dialog => $opts,
    };
    bless( $self, $class );
    return $self;
}

sub message_text {
    my ( $self, $text ) = @_;

    #--- Dialog Box

    my $dlg = $self->{view}->DialogBox(
        -title   => __ 'Dialog',
        -buttons => [ __ 'Close' ],
    );

    #--- Frame top

    my $frame_top = $dlg->Frame()->pack(
        -side   => 'left',
        -expand => 1,
        -fill   => 'both',
        -anchor => 'w',
        -padx   => 15,
        -pady   => 10,
    );

    #-- text_entry

    my $ttext_entry = $frame_top->Scrolled(
        'Text',
        -width      => 80,
        -height     => 5,
        -wrap       => 'word',
        -scrollbars => 'e',
        -background => 'white',
    );
    $ttext_entry->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    my $control = $ttext_entry;

    my $state = $control->cget('-state');
    $text = q{} unless defined $text;    # Empty
    $control->delete( '1.0', 'end' );
    $control->insert( '1.0', $text ) if defined $text;
    $control->configure( -state => $state );

    my $result = $dlg->Show;

    return;
}


1;

=head1 SYNOPSIS

    require Tpda3::Tk::Dialog::Text;

    my $dlg = Tpda3::Tk::Dialog::Text->new($self->view);

    $dlg->message_text($message, $details);

=head2 new

Constructor method

=head2 message_text

Define and show message dialog.  MsgBox doesn't allow to change the
button labels.

=cut
