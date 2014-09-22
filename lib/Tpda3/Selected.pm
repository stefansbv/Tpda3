package Tpda3::Selected;

# ABSTRACT: Selected field values in dictionary like tables

use strict;
use warnings;
use utf8;

sub new {
    my ($type, $opts) = @_;

    my $self = {};

    bless( $self, $type );

    my $cfg = Tpda3::Config->instance();
    my $ws  = $cfg->application->{widgetset};
    $self->{_ws} = $ws;

    if ( $ws =~ m{wx}i ) {
        # require Tpda3::Wx::Dialog::Select;
        # $self->{dlg} = Tpda3::Wx::Dialog::Select->new($opts);
    }
    elsif ( $ws =~ m{tk}i ) {
        require Tpda3::Tk::Dialog::Select;
        $self->{dlg} = Tpda3::Tk::Dialog::Select->new($opts);
    }
    else {
        warn "Unknown widget set!\n";
        exit;
    }

    return $self;
}

sub selected {
    my ( $self, $view, $para ) = @_;

    my $record;
    if ( $self->{_ws} =~ m{tk}ix ) {
        $record = $self->{dlg}->select_dialog( $view, $para );
    }
    elsif ( $self->{_ws} =~ m{wx}ix ) {
        # my $dialog = $self->{dlg}->select_dialog( $view, $para );
        # if ( $dialog->ShowModal == &Wx::wxID_CANCEL ) {
        #     print "Dialog cancelled\n";
        # }
        # else {
        #     $record = $self->{dlg}->get_selected_item();
        # }
    }

    return $record;
}

1;

=head1 SYNOPSIS

    use Tpda3::Selected;

=head2 new

Constructor method.

=head2 selected

Show dialog and return selected record.

=cut
