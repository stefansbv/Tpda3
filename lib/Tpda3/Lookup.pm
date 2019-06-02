package Tpda3::Lookup;

# ABSTRACT: Lookup field values in dictionary tables

use strict;
use warnings;
use utf8;

sub new {
    my ($class, $opts) = @_;

    my $self = {};

    bless( $self, $class );

    my $cfg = Tpda3::Config->instance();
    my $ws  = $cfg->application->{widgetset};
    $self->{_ws} = $ws;

    if ( $ws =~ m{wx}i ) {
        require Tpda3::Wx::Dialog::Search;
        $self->{dlg} = Tpda3::Wx::Dialog::Search->new($opts);
    }
    elsif ( $ws =~ m{tk}i ) {
        require Tpda3::Tk::Dialog::Search;
        $self->{dlg} = Tpda3::Tk::Dialog::Search->new($opts);
    }
    else {
        warn "Unknown widget set!\n";
        exit;
    }

    return $self;
}

sub lookup {
    my ( $self, $view, $para, $filter ) = @_;
    my $record;
    if ( $self->{_ws} =~ m{tk}ix ) {
        $record = $self->{dlg}->search_dialog( $view, $para, $filter );
    }
    elsif ( $self->{_ws} =~ m{wx}ix ) {
        my $dialog = $self->{dlg}->search_dialog( $view, $para, $filter );
        if ( $dialog->ShowModal == &Wx::wxID_CANCEL ) {
            print "Dialog cancelled\n";
        }
        else {
            $record = $self->{dlg}->get_selected_item();
        }
    }
    return $record;
}

1;

=head1 SYNOPSIS

Load the screen configuration.

    use Tpda3::Lookup;

    my $dict = Tpda3::Lookup->new($opts);

    my $record = $dict->lookup( $view, $para, $filter );

=head2 new

Constructor method.

The $opts parameter is passed to the dialog (not used).

=head2 lookup

TODO pod!

=cut
