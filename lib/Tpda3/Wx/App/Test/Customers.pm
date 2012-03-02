package Tpda3::Wx::App::Test::Customers;

use strict;
use warnings;

use Wx qw{:everything};
use base 'Tpda3::Wx::Screen';

=head1 NAME

Tpda3::App::Test::Customers screen

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    require Tpda3::App::Test::Customers;

    my $scr = Tpda3::App::Test::Customers->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $nb ) = @_;

    # my $rec_page = $nb->page_widget('rec');
    # my $det_page = $nb->page_widget('det');
    my $rec_page = $nb->GetPage(0);
    my $det_page = $nb->GetPage(2);
    $self->{view} = $nb->GetGrandParent;
    $self->{bg}   = $nb->GetBackgroundColour();

    # TODO: use Wx::Perl::TextValidator

    #--- Controls

    my $lcustomername = Wx::StaticText->new( $rec_page, -1, 'Name' );
    my $ecustomername
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );
    my $ecustomernumber
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $lcontactlastname = Wx::StaticText->new( $rec_page, -1, 'Last name' );
    my $econtactlastname
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $lcontactfirstname = Wx::StaticText->new( $rec_page, -1, 'First name' );
    my $econtactfirstname
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $lphone = Wx::StaticText->new( $rec_page, -1, 'Phone' );
    my $ephone
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $laddressline1 = Wx::StaticText->new( $rec_page, -1, 'Address line1' );
    my $eaddressline1
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $laddressline2 = Wx::StaticText->new( $rec_page, -1, 'Address line2' );
    my $eaddressline2
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $lcity = Wx::StaticText->new( $rec_page, -1, 'City' );
    my $ecity
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $lstate = Wx::StaticText->new( $rec_page, -1, 'State' );
    my $estate
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $lcountryname = Wx::StaticText->new( $rec_page, -1, 'Country' );
    my $ecountryname = Wx::TextCtrl->new(
        $rec_page, -1, q{},
        [ -1, -1 ],
        [ -1, -1 ],
        wxTE_PROCESS_ENTER,
    );
    my $ecountrycode
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lsalesrepemployee
        = Wx::StaticText->new( $rec_page, -1, 'Sales repres.' );
    my $esalesrepemployee = Wx::TextCtrl->new(
        $rec_page, -1, q{},
        [ -1, -1 ],
        [ -1, -1 ],
        wxTE_PROCESS_ENTER,
    );
    my $eemployeenumber
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lcreditlimit = Wx::StaticText->new( $rec_page, -1, 'Credit limit' );
    my $ecreditlimit
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    my $lpostalcode = Wx::StaticText->new( $rec_page, -1, 'Postal code' );
    my $epostalcode
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    #--- Layout

    my $top_sz = Wx::BoxSizer->new(wxVERTICAL);

    my $sbox_sz = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $rec_page, -1, ' Customer ', ), wxVERTICAL );

    my $grid = Wx::GridBagSizer->new( 5, 0 );

    $grid->Add( 0, 3, gbpos( 0, 0 ), gbspan( 1, 2 ), );    # spacer

    $grid->Add(
        $lcustomername,
        gbpos( 1, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $ecustomername,
        gbpos( 1, 1 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $ecustomernumber,
        gbpos( 1, 2 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxRIGHT, 5
    );

    $grid->Add(
        $lcontactlastname,
        gbpos( 2, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $econtactlastname,
        gbpos( 2, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add(
        $lcontactfirstname,
        gbpos( 3, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $econtactfirstname,
        gbpos( 3, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add( $lphone, gbpos( 4, 0 ), gbspan( 1, 1 ), wxLEFT | wxRIGHT, 5 );
    $grid->Add(
        $ephone,
        gbpos( 4, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add(
        $laddressline1,
        gbpos( 5, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $eaddressline1,
        gbpos( 5, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add(
        $laddressline2,
        gbpos( 6, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $eaddressline2,
        gbpos( 6, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add( $lcity, gbpos( 7, 0 ), gbspan( 1, 1 ), wxLEFT | wxRIGHT, 5 );
    $grid->Add(
        $ecity,
        gbpos( 7, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add( $lstate, gbpos( 8, 0 ), gbspan( 1, 1 ), wxLEFT | wxRIGHT, 5 );
    $grid->Add(
        $estate,
        gbpos( 8, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add(
        $lcountryname,
        gbpos( 9, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $ecountryname,
        gbpos( 9, 1 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $ecountrycode,
        gbpos( 9, 2 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxRIGHT, 5
    );

    $grid->Add(
        $lsalesrepemployee,
        gbpos( 10, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $esalesrepemployee,
        gbpos( 10, 1 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $eemployeenumber,
        gbpos( 10, 2 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxRIGHT, 5
    );

    $grid->Add(
        $lcreditlimit,
        gbpos( 11, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $ecreditlimit,
        gbpos( 11, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add(
        $lpostalcode,
        gbpos( 12, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $epostalcode,
        gbpos( 12, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add( 0, 3, gbpos( 13, 0 ), gbspan( 1, 2 ), );    # spacer

    $grid->AddGrowableCol(1);

    $sbox_sz->Add( $grid, 0, wxALL | wxGROW, 0 );
    $top_sz->Add( $sbox_sz, 0, wxALL | wxGROW, 5 );

    $rec_page->SetSizer($top_sz);

    # Entry objects: var_asoc, var_obiect
    # Other configurations in 'customers.conf'
    $self->{controls} = {
        customername     => [ undef, $ecustomername ],
        customernumber   => [ undef, $ecustomernumber ],
        contactlastname  => [ undef, $econtactlastname ],
        contactfirstname => [ undef, $econtactfirstname ],
        phone            => [ undef, $ephone ],
        addressline1     => [ undef, $eaddressline1 ],
        addressline2     => [ undef, $eaddressline2 ],
        city             => [ undef, $ecity ],
        state            => [ undef, $estate ],
        countryname      => [ undef, $ecountryname ],
        countrycode      => [ undef, $ecountrycode ],
        salesrepemployee => [ undef, $esalesrepemployee ],
        employeenumber   => [ undef, $eemployeenumber ],
        creditlimit      => [ undef, $ecreditlimit ],
        postalcode       => [ undef, $epostalcode ],
    };

    return;
}

sub gbpos { Wx::GBPosition->new(@_) }

sub gbspan { Wx::GBSpan->new(@_) }

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

1;    # End of Tpda3::Wx::App::Test::Customers
