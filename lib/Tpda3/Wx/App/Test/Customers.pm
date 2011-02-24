package Tpda3::Wx::App::Test::Customers;

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

    require Tpda3::App::Test::Customers;

    my $scr = Tpda3::App::Test::Customers->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $inreg_p ) = @_;

    my $gui     = $inreg_p->GetGrandParent;
    my $main_p  = $inreg_p->GetParent;
    $self->{bg} = $inreg_p->GetBackgroundColour();

    # TODO: use Wx::Perl::TextValidator

    my $lcustomername = Wx::StaticText->new( $inreg_p, -1, 'Customer', );
    my $ecustomername =
        Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lcustomernumber = Wx::StaticText->new( $inreg_p, -1, 'Customernumber', );
    my $ecustomernumber =
        Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lcontactlastname = Wx::StaticText->new( $inreg_p, -1, 'Last name', );
    my $econtactlastname =
        Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lcontactfirstname = Wx::StaticText->new( $inreg_p, -1, 'First name', );
    my $econtactfirstname =
        Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lphone = Wx::StaticText->new( $inreg_p, -1, 'Phone', );
    my $ephone = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $laddressline1 = Wx::StaticText->new( $inreg_p, -1, 'Address line1', );
    my $eaddressline1 = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $laddressline2 = Wx::StaticText->new( $inreg_p, -1, 'Address line2', );
    my $eaddressline2 = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lcity = Wx::StaticText->new( $inreg_p, -1, 'City', );
    my $ecity = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lstate = Wx::StaticText->new( $inreg_p, -1, 'State', );
    my $estate = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lcountryname = Wx::StaticText->new( $inreg_p, -1, 'Country', );
    my $ecountryname = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lcountrycode = Wx::StaticText->new( $inreg_p, -1, 'cc', );
    my $ecountrycode = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lsalesrepemployee = Wx::StaticText->new( $inreg_p, -1, 'Sales repres.', );
    my $esalesrepemployee = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lemployeenumber = Wx::StaticText->new( $inreg_p, -1, 'Emp number', );
    my $eemployeenumber = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lcreditlimit = Wx::StaticText->new( $inreg_p, -1, 'Credit limit', );
    my $ecreditlimit = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $lpostalcode = Wx::StaticText->new( $inreg_p, -1, 'Postal code', );
    my $epostalcode = Wx::TextCtrl->new( $inreg_p, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    #--- Layout

    my $loco_main_sz = Wx::FlexGridSizer->new( 2, 1, 5, 5 );

    #-- Middle

    my $loco_mid_sz =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $inreg_p, -1, ' Customer ', ), wxVERTICAL, );

    my $loco_mid_fgs = Wx::FlexGridSizer->new( 2, 2, 5, 10 );

    $loco_mid_fgs->Add( $lcustomername, 0, wxTOP | wxLEFT,  5 );
    $loco_mid_fgs->Add( $ecustomername,    0, wxEXPAND | wxTOP, 5 );

    $loco_mid_fgs->Add( $lcustomernumber, 0, wxLEFT,   5 );
    $loco_mid_fgs->Add( $ecustomernumber, 0, wxEXPAND, 0 );

    $loco_mid_fgs->Add( $lcontactlastname, 0, wxLEFT,   5 );
    $loco_mid_fgs->Add( $econtactlastname,   0, wxEXPAND, 0 );

    $loco_mid_fgs->Add( $lcontactfirstname, 0, wxLEFT,   5 );
    $loco_mid_fgs->Add( $econtactfirstname,    0, wxEXPAND, 0 );

    $loco_mid_fgs->Add(  $lphone,    0, wxEXPAND, 0 );
    $loco_mid_fgs->Add(  $ephone,    0, wxEXPAND, 0 );

    $loco_mid_fgs->Add(  $laddressline1,    0, wxEXPAND, 0 );
    $loco_mid_fgs->Add(  $eaddressline1,    0, wxEXPAND, 0 );

    $loco_mid_fgs->Add(  $laddressline2,    0, wxEXPAND, 0 );
    $loco_mid_fgs->Add(  $eaddressline2,    0, wxEXPAND, 0 );

    $loco_mid_fgs->Add(  $lcity,    0, wxEXPAND, 0 );
    $loco_mid_fgs->Add(  $ecity,    0, wxEXPAND, 0 );

    $loco_mid_fgs->Add(  $lstate,    0, wxEXPAND, 0 );
    $loco_mid_fgs->Add(  $estate,    0, wxEXPAND, 0 );

    $loco_mid_fgs->Add(  $lcountryname,    0, wxEXPAND, 0 );
    $loco_mid_fgs->Add(  $ecountryname,    0, wxEXPAND, 0 );

    $loco_mid_fgs->Add(  $lcountrycode,    0, wxEXPAND, 0 );
    $loco_mid_fgs->Add(  $ecountrycode,    0, wxEXPAND, 0 );

    $loco_mid_fgs->Add(  $lsalesrepemployee,    0, wxEXPAND, 0 );
    $loco_mid_fgs->Add(  $esalesrepemployee,    0, wxEXPAND, 0 );

    $loco_mid_fgs->Add(  $lemployeenumber,    0, wxEXPAND, 0 );
    $loco_mid_fgs->Add(  $eemployeenumber,    0, wxEXPAND, 0 );

    $loco_mid_fgs->Add(  $lcreditlimit,    0, wxEXPAND, 0 );
    $loco_mid_fgs->Add(  $ecreditlimit,    0, wxEXPAND, 0 );

    $loco_mid_fgs->Add(  $lpostalcode,    0, wxEXPAND, 0 );
    $loco_mid_fgs->Add(  $epostalcode,    0, wxEXPAND, 0 );

    #- Layout

    $loco_mid_fgs->AddGrowableCol( 1, 1 );
    $loco_mid_sz->Add( $loco_mid_fgs, 0, wxALL | wxGROW, 0 );
    $loco_main_sz->Add( $loco_mid_sz, 0, wxALL | wxGROW, 5 );

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

1; # End of Tpda3::Wx::App::Test::Customers
