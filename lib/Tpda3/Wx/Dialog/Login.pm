package Tpda3::Wx::Dialog::Login;

use strict;
use warnings;

use Wx qw{:everything};
use Wx::Event qw(EVT_TEXT_ENTER);

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

    $self->{_view} = $frame;

    $self->{_cfg} = Tpda3::Config->instance();
    my $user = $self->{_cfg}->user || q{};

    my $top_sz = Wx::BoxSizer->new( wxVERTICAL );

    my $vbox_sz = Wx::BoxSizer->new( wxVERTICAL );
    $top_sz->Add($vbox_sz, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5);

    # Spacer
    $vbox_sz->Add(5, 5, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5);

    # Message
    my $message = Wx::StaticText->new(
        $self,
        -1,
        qq{ ->[ Please enter your user name and password ]<- \n},
        [ -1, -1 ],
        [ -1, -1 ],
        0,
    );
    $vbox_sz->Add( $message, 0, wxALIGN_LEFT | wxALL, 5 );

    # Label - user
    my $user_label = Wx::StaticText->new(
        $self,
        -1,
        q{User:},
        [ -1, -1 ],
        [ -1, -1 ],
        0,
    );
    $vbox_sz->Add($user_label, 0, wxALIGN_LEFT | wxALL, 5);

    # Text control - user
    $self->{user_ctrl} = Wx::TextCtrl->new(
        $self,
        -1,
        $user,
        [ -1, -1 ],
        [ -1, -1 ],
        wxTE_PROCESS_ENTER,
    );
    $vbox_sz->Add($self->{user_ctrl}, 0, wxGROW | wxALL, 5);

    # Label - password
    my $pass_label = Wx::StaticText->new(
        $self,
        -1,
        q{Password:},
        [ -1, -1 ],
        [ -1, -1 ],
        0,
    );
    $vbox_sz->Add($pass_label, 0, wxALIGN_LEFT | wxALL, 5);

    # Text control - password
    $self->{pass_ctrl} = Wx::TextCtrl->new(
        $self,
        -1,
        q{},
        [ -1, -1 ],
        [ -1, -1 ],
        wxTE_PASSWORD | wxTE_PROCESS_ENTER,
    );
    $vbox_sz->Add($self->{pass_ctrl}, 0, wxGROW | wxALL, 5);

    # Line
    my $line = Wx::StaticLine->new(
        $self,
        -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxLI_HORIZONTAL,
    );
    $vbox_sz->Add($line, 0, wxGROW | wxALL, 5);

    my $ok_cancel_box = Wx::BoxSizer->new(wxHORIZONTAL);
    $vbox_sz->Add($ok_cancel_box, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5);

    # Button - OK
    my $ok = Wx::Button->new(
        $self,
        wxID_OK,
        q{&OK},
        [ -1, -1 ],
        [ -1, -1 ],
        0,
    );
    $ok_cancel_box->Add($ok, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);

    # Button - Cancel
    my $cancel = Wx::Button->new(
        $self,
        wxID_CANCEL,
        q{&Cancel},
        [ -1, -1 ],
        [ -1, -1 ],
        0,
    );
    $ok_cancel_box->Add($cancel, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);

    $self->SetSizerAndFit($top_sz);

    $self->{user_ctrl}->SetFocus();
    $self->{pass_ctrl}->SetFocus if $user;

    EVT_TEXT_ENTER(
        $self,
        -1,
        sub { $self->login() },
    );

    return $self;
}

sub login {
    my $self = shift;

    if ( $self->ShowModal == wxID_CANCEL ) {
        print "Cancelled, quiting ...\n";
        $self->EndModal(1);
        return wxID_CANCEL;
    }

    my $user = $self->{user_ctrl}->GetValue();
    my $pass = $self->{pass_ctrl}->GetValue();

    if ( $user && $pass ) {
        $self->{_cfg}->user($user);
        $self->{_cfg}->pass($pass);
    }

    $self->EndModal(1);

    return wxID_OK;
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
