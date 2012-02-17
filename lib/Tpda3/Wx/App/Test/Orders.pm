package Tpda3::Wx::App::Test::Orders;

use strict;
use warnings;

use Wx qw{:everything};
use base 'Tpda3::Wx::Screen';

=head1 NAME

Tpda3::App::Test::Orders screen

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    require Tpda3::App::Test::Orders;

    my $scr = Tpda3::App::Test::Orders->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $nb ) = @_;

    my $rec_page = $nb->page_widget('rec');
    my $det_page = $nb->page_widget('det');
    $self->{view} = $nb->GetGrandParent;
    $self->{bg}   = $nb->GetBackgroundColour();

    # TODO: use Wx::Perl::TextValidator

    #- Controls

    #-- customername + customernumber
    my $lcustomername = Wx::StaticText->new( $rec_page, -1, 'Name' );
    my $ecustomername
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );
    my $ecustomernumber
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    #-- ordernumber
    my $lordernumber = Wx::StaticText->new( $rec_page, -1, 'Last name' );
    my $eordernumber
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    #-- orderdate
    my $lorderdate = Wx::StaticText->new( $rec_page, -1, 'First name' );
    my $eorderdate
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    #-- requireddate
    my $lrequireddate = Wx::StaticText->new( $rec_page, -1, 'requireddate' );
    my $erequireddate
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    #-- shippeddate
    my $lshippeddate = Wx::StaticText->new( $rec_page, -1, 'shippeddate' );
    my $eshippeddate
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    #-- statuscode
    my $lstatuscode = Wx::StaticText->new( $rec_page, -1, 'statuscode' );
    my $estatuscode
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    #-- comments
    my $lcomments = Wx::StaticText->new( $rec_page, -1, 'comments' );
    my $ecomments
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    #-- ordertotal
    my $lordertotal = Wx::StaticText->new( $rec_page, -1, 'ordertotal' );
    my $eordertotal
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

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
        $lordernumber,
        gbpos( 2, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $eordernumber,
        gbpos( 2, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add(
        $lorderdate,
        gbpos( 3, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $eorderdate,
        gbpos( 3, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add( 0, 3, gbpos( 13, 0 ), gbspan( 1, 2 ), );    # spacer

    $grid->AddGrowableCol(1);

    $sbox_sz->Add( $grid, 0, wxALL | wxGROW, 0 );
    $top_sz->Add( $sbox_sz, 0, wxALL | wxGROW, 5 );

    $rec_page->SetSizer($top_sz);

    # Entry objects: var_asoc, var_obiect
    # Other configurations in 'orders.conf'
    $self->{controls} = {
        customername   => [ undef, $ecustomername ],
        customernumber => [ undef, $ecustomernumber ],
        ordernumber    => [ undef, $eordernumber ],
        orderdate      => [ undef, $eorderdate ],
        requireddate   => [ undef, $erequireddate ],
        shippeddate    => [ undef, $eshippeddate ],
        statuscode     => [ undef, $estatuscode ],
        comments       => [ undef, $ecomments ],
        ordertotal     => [ undef, $eordertotal ],
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

1;    # End of Tpda3::Wx::App::Test::Orders
