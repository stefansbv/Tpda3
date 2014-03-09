package Tpda3::Wx::DatePopup;

use strict;
use warnings;

use Wx;
use Wx::Event qw(EVT_CALENDAR_SEL_CHANGED);
use Wx::Calendar;
use base qw(Wx::PlComboPopup);

=head1 NAME

Tpda3::Wx::DatePopup - A custom, Calendar popup for Tpda3::Wx::ComboDate.

=head1 VERSION

Version 0.80

=cut

our $VERSION = 0.80;

=head1 SYNOPSIS

=head1 METHODS

=head2 Init

Init value.

=cut

sub Init {
    my( $self ) = @_;

    $self->{value} = "";
}

=head2 Create

Create :)

=cut

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

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Inspired from Wx/DemoModules/wxComboCtrl.pm
Copyright (c) 2007 Mattia Barbon

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::DatePopup
