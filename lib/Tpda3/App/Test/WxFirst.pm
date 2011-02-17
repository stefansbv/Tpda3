package Tpda3::App::Test::WxFirst;

use strict;
use warnings;

use Wx qw{:everything};
use base 'Tpda3::Wx::Screen';

=head1 NAME

Tpda3::App::Test::Customers screen

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    require Tpda3::App::Test::WxFirst;

    my $scr = Tpda3::App::Test::WxFirst->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $inreg_p ) = @_;

    my $gui     = $inreg_p->GetGrandParent;
    my $main_p  = $inreg_p->GetParent;
    # $self->{bg} = $gui->cget('-background');

    #-- Controls

    my $repo_lbl1 = Wx::StaticText->new( $inreg_p, -1, 'Title', );
    $self->{title} =
        Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $repo_lbl2 = Wx::StaticText->new( $inreg_p, -1, 'Query file', );
    $self->{filename} =
        Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $repo_lbl3 = Wx::StaticText->new( $inreg_p, -1, 'Output file', );
    $self->{output} =
        Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $repo_lbl4 = Wx::StaticText->new( $inreg_p, -1, 'Sheet name', );
    $self->{sheet} =
        Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    $self->{description} =
        Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, 40 ],
                           wxTE_MULTILINE, );

    #--- Layout

    my $repo_main_sz = Wx::FlexGridSizer->new( 4, 1, 5, 5 );

    #-- Middle

    my $repo_mid_sz =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $inreg_p, -1, ' Header ', ), wxVERTICAL, );

    my $repo_mid_fgs = Wx::FlexGridSizer->new( 4, 2, 5, 10 );

    $repo_mid_fgs->Add( $repo_lbl1, 0, wxTOP | wxLEFT,  5 );
    $repo_mid_fgs->Add( $self->{title},    0, wxEXPAND | wxTOP, 5 );

    $repo_mid_fgs->Add( $repo_lbl2, 0, wxLEFT,   5 );
    $repo_mid_fgs->Add( $self->{filename}, 0, wxEXPAND, 0 );

    $repo_mid_fgs->Add( $repo_lbl3, 0, wxLEFT,   5 );
    $repo_mid_fgs->Add( $self->{output},   0, wxEXPAND, 0 );

    $repo_mid_fgs->Add( $repo_lbl4, 0, wxLEFT,   5 );
    $repo_mid_fgs->Add( $self->{sheet},    0, wxEXPAND, 0 );

    # $repo_mid_fgs->AddGrowableRow( 1, 1 );
    $repo_mid_fgs->AddGrowableCol( 1, 1 );

    $repo_mid_sz->Add( $repo_mid_fgs, 0, wxALL | wxGROW, 0 );

    #-- Bottom

    my $repo_bot_sz =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $inreg_p, -1, ' Description ', ),
        wxVERTICAL, );

    $repo_bot_sz->Add( $self->{description}, 1, wxEXPAND );

    #--

    $repo_main_sz->Add( $repo_mid_sz, 0, wxALL | wxGROW, 5 );
    $repo_main_sz->Add( $repo_bot_sz, 0, wxALL | wxGROW, 5 );

    $repo_main_sz->AddGrowableRow(0);
    $repo_main_sz->AddGrowableCol(0);

    $inreg_p->SetSizer($repo_main_sz);

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Tpda3::App::Test::WxFirst
