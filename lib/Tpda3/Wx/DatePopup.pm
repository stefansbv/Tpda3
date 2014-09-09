package Tpda3::Wx::DatePopup;

# ABSTRACT: A custom, Calendar popup for Wx::ComboDate

use strict;
use warnings;

use Wx;
use Wx::Event qw(EVT_CALENDAR_SEL_CHANGED);
use Wx::Calendar;
use base qw(Wx::PlComboPopup);


sub Init {
    my( $self ) = @_;

    $self->{value} = "";
}


sub Create {
    my( $self, $parent ) = @_;

    my $date = Wx::DateTime->new;
    my $ctrl = Wx::CalendarCtrl->new( $parent, -1, $date );

    EVT_CALENDAR_SEL_CHANGED(
        $ctrl, $ctrl,
        sub {
            $self->{value} = $_[1]->GetDate->FormatDate();
            $self->Dismiss;
        }
    );

    $self->{ctrl} = $ctrl;

    return 1;
}

sub GetControl {
    my $self = shift;

    return $self->{ctrl};
}

sub SetStringValue {
    my( $self, $string ) = @_;

    print "SetStringValue = $string\n";
    $self->{value} = $string;
    #$self->{ctrl}->SetStringSelection( $string );???
}

sub GetStringValue {
    my $self = shift;

    return $self->{ctrl}->GetDate->FormatDate();
}

sub GetAdjustedSize {
    my( $self, $min_width, $pref_height, $max_height ) = @_;

    return $self->{ctrl}->GetBestSize;
}

# sub OnPopup {
#     my $self = shift;

#     # Wx::LogMessage( "Popping up" ); OS block!!
# }

# sub OnDismiss {
#     my $self = shift;

#     Wx::LogMessage( "Being dismissed on " . $self->GetStringValue() );
# }

1;

=head1 SYNOPSIS

=head2 Init

Init value.

=head2 Create

Create :)

=head1 ACKNOWLEDGEMENTS

Inspired from Wx/DemoModules/wxComboCtrl.pm
Copyright (c) 2007 Mattia Barbon

=cut
