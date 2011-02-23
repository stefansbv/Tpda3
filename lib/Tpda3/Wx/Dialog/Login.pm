package Tpda3::Wx::Dialog::Login;

use strict;
use warnings;

use Wx qw{:everything};
use base qw{Wx::Dialog};

use Tpda3::Config;

sub new {
    my ( $class, $frame ) = @_;

    my $self = $class->SUPER::new(
        $frame,
        -1,
        q{Login},
        [-1, -1],
        [-1, -1],
        wxDEFAULT_DIALOG_STYLE | wxCAPTION,
    );

    # A top-level sizer
    my $topSizer = Wx::BoxSizer->new( wxVERTICAL );

    # A second box sizer to give more space around the controls
    my $boxSizer = Wx::BoxSizer->new( wxVERTICAL );
    $topSizer->Add($boxSizer, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5);

    # Spacer
    $boxSizer->Add(5, 5, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5);

    # Message
    my $message = Wx::StaticText->new(
        $self,
        -1,
        qq{-- Please enter your user name and password --\n},
        [ -1, -1 ],
        [ -1, -1 ],
        0,
    );
    $boxSizer->Add( $message, 0, wxALIGN_LEFT | wxALL, 5 );

    # Spacer
    # $boxSizer->Add(5, 5, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5);

    # Label for the name text control
    my $user_label = Wx::StaticText->new(
        $self,
        -1,
        q{User:},
        [ -1, -1 ],
        [ -1, -1 ],
        0,
    );
    $boxSizer->Add($user_label, 0, wxALIGN_LEFT | wxALL, 5);

    # A text control for the user’s name
    $self->{user_ctrl} = Wx::TextCtrl->new(
        $self,
        -1,
        q{},
        [ -1, -1 ],
        [ -1, -1 ],
        0,
    );
    $boxSizer->Add($self->{user_ctrl}, 0, wxGROW | wxALL, 5);

    # Label for the name text control
    my $pass_label = Wx::StaticText->new(
        $self,
        -1,
        q{Password:},
        [ -1, -1 ],
        [ -1, -1 ],
        0,
    );
    $boxSizer->Add($pass_label, 0, wxALIGN_LEFT | wxALL, 5);

    # A text control for the user’s name
    $self->{pass_ctrl} = Wx::TextCtrl->new(
        $self,
        -1,
        q{},
        [ -1, -1 ],
        [ -1, -1 ],
        wxTE_PASSWORD,
    );
    $boxSizer->Add($self->{pass_ctrl}, 0, wxGROW | wxALL, 5);

    # A dividing line before the OK and Cancel buttons
    my $line = Wx::StaticLine->new(
        $self,
        -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxLI_HORIZONTAL,
    );
    $boxSizer->Add($line, 0, wxGROW | wxALL, 5);

    # A horizontal box sizer to contain OK, Cancel
    my $okCancelBox = Wx::BoxSizer->new(wxHORIZONTAL);
    $boxSizer->Add($okCancelBox, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5);

    # The OK button
    my $ok = Wx::Button->new(
        $self,
        wxID_OK,
        q{&OK},
        [ -1, -1 ],
        [ -1, -1 ],
        0,
    );
    $okCancelBox->Add($ok, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);

    # The Cancel button
    my $cancel = Wx::Button->new(
        $self,
        wxID_CANCEL,
        q{&Cancel},
        [ -1, -1 ],
        [ -1, -1 ],
        0,
    );
    $okCancelBox->Add($cancel, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);

    $self->SetSizer($topSizer);
    $self->Fit;

    $self->{user_ctrl}->SetFocus();

    return $self;
}

sub dialog_login {
    my $self = shift;

    if ( $self->ShowModal == wxID_CANCEL ) {
        print " cancelled\n";
        return;
    }

    my $user = $self->{user_ctrl}->GetValue();
    my $pass = $self->{pass_ctrl}->GetValue();

    if ( $user && $pass ) {
        my $cfg = Tpda3::Config->instance();
        $cfg->user($user);
        $cfg->pass($pass);
    }

    print "user is $user\n";
    $self->Destroy;
}

# Event handler for wxID_CANCEL
sub OnCancel {
    my $self = shift;

    print "login OnCancel called\n";
    $self->EndModal(wxID_CANCEL);
}

=head1 AUTHOR

Stefan Suciu, C<< <stefbv70 at gmail com> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of Tpda3::Wx::Dialog::Login
