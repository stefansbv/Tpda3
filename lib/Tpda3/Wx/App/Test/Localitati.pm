package Tpda3::Wx::App::Test::Localitati;

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

    require Tpda3::App::Test::Localitati;

    my $scr = Tpda3::App::Test::Localitati->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $inreg_p ) = @_;

    my $gui    = $inreg_p->GetGrandParent;
    my $main_p = $inreg_p->GetParent;
    $self->{bg} = $inreg_p->GetBackgroundColour();

    my $lcod_p = Wx::StaticText->new( $inreg_p, -1, 'Cod', );
    my $ecod_p
        = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $llocalitate = Wx::StaticText->new( $inreg_p, -1, 'Localitate', );
    my $elocalitate
        = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $ljudet = Wx::StaticText->new( $inreg_p, -1, 'Judet', );
    my $ejudet
        = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lid_judet = Wx::StaticText->new( $inreg_p, -1, 'Cod judet', );
    my $eid_judet
        = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $tprim_adresa = Wx::TextCtrl->new(
        $inreg_p, -1, q{},
        [ -1, -1 ],
        [ -1, 40 ],
        wxTE_MULTILINE,
    );

    #--- Layout

    my $loco_main_sz = Wx::FlexGridSizer->new( 2, 1, 5, 5 );

    #-- Middle

    my $loco_mid_sz = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $inreg_p, -1, ' Localitate ', ), wxVERTICAL, );

    my $loco_mid_fgs = Wx::FlexGridSizer->new( 2, 2, 5, 10 );

    $loco_mid_fgs->Add( $lcod_p, 0, wxTOP | wxLEFT,   5 );
    $loco_mid_fgs->Add( $ecod_p, 0, wxEXPAND | wxTOP, 5 );

    $loco_mid_fgs->Add( $llocalitate, 0, wxLEFT,   5 );
    $loco_mid_fgs->Add( $elocalitate, 0, wxEXPAND, 0 );

    $loco_mid_fgs->Add( $ljudet, 0, wxLEFT,   5 );
    $loco_mid_fgs->Add( $ejudet, 0, wxEXPAND, 0 );

    $loco_mid_fgs->Add( $lid_judet, 0, wxLEFT,   5 );
    $loco_mid_fgs->Add( $eid_judet, 0, wxEXPAND, 0 );

    #- Layout

    $loco_mid_fgs->AddGrowableCol( 1, 1 );
    $loco_mid_sz->Add( $loco_mid_fgs, 0, wxALL | wxGROW, 0 );

    #-- Bottom

    my $loco_bot_sz
        = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $inreg_p, -1, ' Adresa primarie ', ), wxVERTICAL,
        );

    $loco_bot_sz->Add( $tprim_adresa, 1, wxEXPAND );

    #--

    $loco_main_sz->Add( $loco_mid_sz, 0, wxALL | wxGROW, 5 );
    $loco_main_sz->Add( $loco_bot_sz, 0, wxALL | wxGROW, 5 );

    $loco_main_sz->AddGrowableRow(1);
    $loco_main_sz->AddGrowableCol(0);

    $inreg_p->SetSizer($loco_main_sz);

    # No visual effect with this:
    # $inreg_p->SetSizerAndFit($loco_main_sz);
    # $inreg_p->FitInside();
    # $gui->SetClientSize($inreg_p->GetSize());
    #$gui->Fit();
    #$gui->SetAutoLayout( 1 );

    # Entry objects: var_asoc, var_obiect
    # Other configurations in 'products.conf'
    $self->{controls} = {
        localitate  => [ undef, $elocalitate ],
        judet       => [ undef, $ejudet ],
        id_judet    => [ undef, $eid_judet ],
        cod_p       => [ undef, $ecod_p ],
        prim_adresa => [ undef, $tprim_adresa ],
    };

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::App::Test::Localitati
