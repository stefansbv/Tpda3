package Tpda3::Wx::App::Test::Orders;

use strict;
use warnings;

use Wx qw{:everything};
use base 'Tpda3::Wx::Screen';

use Wx::Event qw(EVT_DATE_CHANGED);
use Wx::Calendar;
use Tpda3::Wx::ComboBox;

=head1 NAME

Tpda3::App::Test::Orders screen

=head1 VERSION

Version 0.49

=cut

our $VERSION = 0.49;

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

    my $rec_page = $nb->GetPage(0);
    my $det_page = $nb->GetPage(2);
    $self->{view} = $nb->GetGrandParent;
    $self->{bg}   = $rec_page->GetBackgroundColour();

    # TODO: use Wx::Perl::TextValidator

    #- Controls

    #-- customername + customernumber
    my $lcustomername = Wx::StaticText->new( $rec_page, -1, 'Customer, No' );
    my $ecustomername
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );
    my $ecustomernumber
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    #-- ordernumber
    my $lordernumber = Wx::StaticText->new( $rec_page, -1, 'Order ID' );
    my $eordernumber
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    #-+ orderdate
    my $lorderdate = Wx::StaticText->new( $rec_page, -1, 'Order date' );
    my $vorderdate = Wx::DateTime->new();
    my $dorderdate = Wx::DatePickerCtrl->new(
        $rec_page,
        -1,
        $vorderdate,
        [-1, -1], [-1, -1],
        wxDP_ALLOWNONE,
    );
    $dorderdate->SetValue($vorderdate);      # required for empty date

    #-- requireddate
    my $lrequireddate = Wx::StaticText->new( $rec_page, -1, 'Required date' );
    my $vrequireddate = Wx::DateTime->new();
    my $drequireddate = Wx::DatePickerCtrl->new(
        $rec_page,
        -1,
        $vrequireddate,
        [-1, -1], [-1, -1],
        wxDP_ALLOWNONE,
    );
    $drequireddate->SetValue($vrequireddate);      # required for empty date

    #-+ shippeddate
    my $lshippeddate = Wx::StaticText->new( $rec_page, -1, 'Shipped date' );
    my $vshippeddate = Wx::DateTime->new();
    my $dshippeddate = Wx::DatePickerCtrl->new(
        $rec_page,
        -1,
        $vshippeddate,
        [-1, -1], [-1, -1],
        wxDP_ALLOWNONE,
    );
    $dshippeddate->SetValue($vshippeddate);      # required for empty date

    #-- statuscode
    my $lstatuscode = Wx::StaticText->new( $rec_page, -1, 'Status' );
    my $bstatuscode = Tpda3::Wx::ComboBox->new( $rec_page );

    #--- Layout

    my $top_sz = Wx::BoxSizer->new(wxHORIZONTAL);

    my $left_sz = Wx::BoxSizer->new(wxVERTICAL);

    my $sbox_sz = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $rec_page, -1, ' Order ', ), wxVERTICAL );

    my $grid = Wx::GridBagSizer->new( 5, 0 );

    $grid->Add( 0, 3, gbpos( 0, 0 ), gbspan( 1, 2 ), );    # spacer

    #-- customername + customernumber
    $grid->Add(
        $lcustomername,
        gbpos( 1, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $ecustomername,
        gbpos( 1, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $ecustomernumber,
        gbpos( 1, 3 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxRIGHT, 5
    );

    #-- ordernumber
    $grid->Add(
        $lordernumber,
        gbpos( 2, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $eordernumber,
        gbpos( 2, 1 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    #-+ orderdate
    $grid->Add(
        $lorderdate,
        gbpos( 2, 2 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $dorderdate,
        gbpos( 2, 3 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    #-- requireddate
    $grid->Add(
        $lrequireddate,
        gbpos( 3, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $drequireddate,
        gbpos( 3, 1 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    #-+ shippeddate
    $grid->Add(
        $lshippeddate,
        gbpos( 3, 2 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $dshippeddate,
        gbpos( 3, 3 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    #-- statuscode
    $grid->Add(
        $lstatuscode,
        gbpos( 4, 0 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid->Add(
        $bstatuscode,
        gbpos( 4, 1 ),
        gbspan( 1, 2 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    $grid->Add( 0, 3, gbpos( 13, 0 ), gbspan( 1, 2 ), );    # spacer

    $grid->AddGrowableCol(1);
    $grid->AddGrowableCol(2);
    $grid->AddGrowableCol(3);

    $sbox_sz->Add( $grid, 0, wxALL | wxGROW, 0 );
    $left_sz->Add( $sbox_sz, 0, wxALL | wxGROW, 5 );

    #--- Comment

    my $ecomments = Wx::TextCtrl->new(
        $rec_page,
        -1,
        q{},
        [ -1, -1 ],
        [ -1, -1 ],
        wxTE_MULTILINE,
    );

    my $right_sz = Wx::BoxSizer->new(wxVERTICAL);

    my $sbox_sz_comment = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $rec_page, -1, ' Comment ', ), wxVERTICAL );

    $sbox_sz_comment->Add( $ecomments, 0, wxEXPAND );
    $right_sz->Add( $sbox_sz_comment, 0, wxALL | wxGROW, 5 );

    $top_sz ->Add( $left_sz, 3, wxALL | wxGROW, 5 );
    $top_sz ->Add( $right_sz, 1, wxALL | wxGROW, 5 );

    $rec_page->SetSizer($top_sz);

    # Entry objects: var_asoc, var_obiect
    # Other configurations in 'orders.conf'
    $self->{controls} = {
        customername   => [ undef, $ecustomername ],
        customernumber => [ undef, $ecustomernumber ],
        ordernumber    => [ undef, $eordernumber ],
        orderdate      => [ undef, $dorderdate ],
        requireddate   => [ undef, $drequireddate ],
        shippeddate    => [ undef, $dshippeddate ],
        statuscode     => [ undef, $bstatuscode ],
        comments       => [ undef, $ecomments ],
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

Copyright 2010-2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::App::Test::Orders
