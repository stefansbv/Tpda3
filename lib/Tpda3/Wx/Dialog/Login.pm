package Tpda3::Wx::Dialog::Login;

use strict;
use warnings;

use Wx qw{:everything};
use Wx::Event qw(EVT_TEXT_ENTER);

use base qw{Wx::Dialog};

require Tpda3::Config;

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

    return $self;
}

=head2 login

Login dialog GUI.

=cut

sub login {
    my ( $class, $view ) = @_;

    my $dlg = $class->SUPER::new(
        $view, -1, q{Login},
        [ -1, -1 ],
        [ -1, -1 ],
        wxDEFAULT_DIALOG_STYLE | wxCAPTION,
    );

    $dlg->{_view} = $view;

    $dlg->{_cfg} = Tpda3::Config->instance();
    my $user = $dlg->{_cfg}->user || q{};

    my $top_sz = Wx::BoxSizer->new(wxVERTICAL);

    my $vbox_sz = Wx::BoxSizer->new(wxVERTICAL);
    $top_sz->Add( $vbox_sz, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 10 );

    # Line
    my $line0 = Wx::StaticLine->new(
        $dlg, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxLI_HORIZONTAL,
    );
    $vbox_sz->Add( $line0, 0, wxGROW | wxALL, 0 );

    $vbox_sz->Add( 5, 5, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5 );   # spacer

    my $flex_sz = Wx::FlexGridSizer->new( 2, 2, 5, 10 );

    # Label - user
    my $user_label
        = Wx::StaticText->new( $dlg, -1, q{User:}, [ -1, -1 ], [ -1, -1 ], 0,
        );
    $flex_sz->Add( $user_label, 0, wxTOP | wxLEFT, 5 );

    # Text control - user
    $dlg->{user_ctrl} = Wx::TextCtrl->new(
        $dlg, -1, $user,
        [ -1,  -1 ],
        [ 200, -1 ],
        wxTE_PROCESS_ENTER,
    );
    $flex_sz->Add( $dlg->{user_ctrl}, 0, wxEXPAND, 0 );

    # Label - password
    my $pass_label
        = Wx::StaticText->new( $dlg, -1, q{Password:}, [ -1, -1 ], [ -1, -1 ],
        );
    $flex_sz->Add( $pass_label, 0, wxTOP | wxLEFT, 5 );

    # Text control - password
    $dlg->{pass_ctrl} = Wx::TextCtrl->new(
        $dlg, -1, q{},
        [ -1,  -1 ],
        [ 200, -1 ],
        wxTE_PASSWORD | wxTE_PROCESS_ENTER,
    );
    $flex_sz->Add( $dlg->{pass_ctrl}, 0, wxEXPAND, 0 );

    $vbox_sz->Add( $flex_sz, 0, wxGROW, 0 );

    $vbox_sz->Add( 5, 5, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5 );   # spacer

    # Line
    my $line = Wx::StaticLine->new(
        $dlg, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxLI_HORIZONTAL,
    );
    $vbox_sz->Add( $line, 0, wxGROW | wxALL, 0 );

    my $ok_cancel_box = Wx::BoxSizer->new(wxHORIZONTAL);
    $vbox_sz->Add( $ok_cancel_box, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5 );

    # Button - OK
    my $ok_btn
        = Wx::Button->new( $dlg, wxID_OK, q{&OK}, [ -1, -1 ], [ -1, -1 ], 0,
        );
    $ok_cancel_box->Add( $ok_btn, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5 );

    # Button - Cancel
    my $cancel_btn = Wx::Button->new(
        $dlg, wxID_CANCEL, q{&Cancel},
        [ -1, -1 ],
        [ -1, -1 ], 0,
    );
    $ok_cancel_box->Add( $cancel_btn, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5 );

    $dlg->SetSizerAndFit($top_sz);

    $dlg->{user_ctrl}->SetFocus();
    $dlg->{pass_ctrl}->SetFocus if $user;

    EVT_TEXT_ENTER(
        $dlg, -1,
        sub {

            # Simulate button click (like Tk invoke)
            my $event
                = Wx::CommandEvent->new( &Wx::wxEVT_COMMAND_BUTTON_CLICKED,
                $ok_btn->GetId(), );
            $ok_btn->GetEventHandler->ProcessEvent($event);
        },
    );

    return $dlg;
}

sub gbpos { Wx::GBPosition->new(@_) }

sub gbspan { Wx::GBSpan->new(@_) }

sub get_login {
    my $self = shift;

    my $user = $self->{user_ctrl}->GetValue();
    my $pass = $self->{pass_ctrl}->GetValue();

    my $return_string = '';
    if ( $user && $pass ) {
        my $cfg = Tpda3::Config->instance();
        $cfg->user($user);
        $cfg->pass($pass);
    }
    else {
        $return_string = 'else';
    }

    return $return_string;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefbv70 at gmail com> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::Dialog::Login
