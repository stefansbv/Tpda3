package Tpda3::Wx::App::Test::Products;

use strict;
use warnings;

use Wx qw{:everything};
use base 'Tpda3::Wx::Screen';

=head1 NAME

Tpda3::App::Test::Products screen

=head1 VERSION

Version 0.58

=cut

our $VERSION = 0.58;

=head1 SYNOPSIS

    require Tpda3::App::Test::Products;

    my $scr = Tpda3::App::Test::Products->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $nb ) = @_;

    my $rec_page = $nb->GetPage(0);
    my $det_page = $nb->GetPage(2);
    $self->{view} = $nb->GetGrandParent;
    $self->{bg}   = $nb->GetBackgroundColour();

    # TODO: use Wx::Perl::TextValidator

    #--- Controls

    my $lproductcode = Wx::StaticText->new( $rec_page, -1, 'Code' );
    my $eproductcode
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $lproductname = Wx::StaticText->new( $rec_page, -1, 'Name' );
    my $eproductname
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $lproductline = Wx::StaticText->new( $rec_page, -1, 'Line' );
    my $eproductline = Wx::TextCtrl->new(
        $rec_page, -1, q{},
        [ -1, -1 ],
        [ -1, -1 ],
        wxTE_PROCESS_ENTER,
    );
    my $eproductlinecode
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $lproductscale = Wx::StaticText->new( $rec_page, -1, 'Scale' );
    my $eproductscale
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $lproductvendor = Wx::StaticText->new( $rec_page, -1, 'Vendor' );
    my $eproductvendor
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $lquantityinstock = Wx::StaticText->new( $rec_page, -1, 'Stock' );
    my $equantityinstock = Wx::TextCtrl->new(
        $rec_page, -1, q{},
        [ -1, -1 ],
        [ -1, -1 ],
        wxALIGN_RIGHT,
    );

    my $lbuyprice = Wx::StaticText->new( $rec_page, -1, 'Buy price' );
    my $ebuyprice = Wx::TextCtrl->new(
        $rec_page, -1, q{},
        [ -1, -1 ],
        [ -1, -1 ],
        wxALIGN_RIGHT,
    );

    my $lmsrp = Wx::StaticText->new( $rec_page, -1, 'MSRP' );
    my $emsrp = Wx::TextCtrl->new(
        $rec_page, -1, q{},
        [ -1, -1 ],
        [ -1, -1 ],
        wxALIGN_RIGHT,
    );

    # Description

    my $eproductdescription = Wx::TextCtrl->new(
        $rec_page,
        -1, q{},
        [ -1, -1 ],
        [ -1, -1 ],
        wxTE_MULTILINE,
    );

    #--- Layout

    my $top_sz = Wx::BoxSizer->new(wxVERTICAL);

    my $sbox1_sz = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $rec_page, -1, ' Product ', ), wxVERTICAL );

    my $grid = Wx::GridBagSizer->new( 5, 0 );

    $grid->Add( 0, 3, gbpos( 0, 0 ), gbspan( 1, 2 ), );    # spacer

    $grid->Add(
        $lproductcode,
        gbpos( 1, 0 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxRIGHT, 5
    );
    $grid->Add(
        $eproductcode,
        gbpos( 1, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add(
        $lproductname,
        gbpos( 2, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $eproductname,
        gbpos( 2, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add(
        $lproductline,
        gbpos( 3, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $eproductline,
        gbpos( 3, 1 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $eproductlinecode,
        gbpos( 3, 2 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxRIGHT, 5
    );

    $grid->Add(
        $lproductscale,
        gbpos( 4, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $eproductscale,
        gbpos( 4, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add(
        $lproductvendor,
        gbpos( 5, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $eproductvendor,
        gbpos( 5, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add(
        $lquantityinstock,
        gbpos( 6, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $equantityinstock,
        gbpos( 6, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add(
        $lbuyprice,
        gbpos( 7, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $ebuyprice,
        gbpos( 7, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add(
        $lmsrp,
        gbpos( 8, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5 );
    $grid->Add(
        $emsrp,
        gbpos( 8, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->AddGrowableCol(1);

    $sbox1_sz->Add( $grid, 0, wxALL | wxGROW, 0 );

    $top_sz->Add( $sbox1_sz, 0, wxALL | wxGROW, 5 );

    #--

    my $descr_vbox = Wx::BoxSizer->new(wxVERTICAL);

    my $descr_sb  = Wx::StaticBox->new( $rec_page, -1, ' Description ' );
    my $descr_sbs = Wx::StaticBoxSizer->new( $descr_sb, wxHORIZONTAL, );

    $descr_sbs->Add( $eproductdescription, 1, wxEXPAND, 0 );

    $top_sz->Add( $descr_sbs, 1, wxALL | wxEXPAND, 5 );

    #--

    $rec_page->SetSizer($top_sz);

    # Entry objects: var_asoc, var_obiect
    # Other configurations in 'customers.conf'
    $self->{controls} = {
        productname        => [ undef, $eproductname ],
        productcode        => [ undef, $eproductcode ],
        productline        => [ undef, $eproductline ],
        productlinecode    => [ undef, $eproductlinecode ],
        productscale       => [ undef, $eproductscale ],
        productvendor      => [ undef, $eproductvendor ],
        quantityinstock    => [ undef, $equantityinstock ],
        buyprice           => [ undef, $ebuyprice ],
        msrp               => [ undef, $emsrp ],
        productdescription => [ undef, $eproductdescription ],
    };

    return;
}

sub gbpos { Wx::GBPosition->new(@_) }

sub gbspan { Wx::GBSpan->new(@_) }

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::App::Test::Products
