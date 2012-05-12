package Tpda3::Wx::App::Test::Orders;

use strict;
use warnings;

use Wx qw{:everything};
use base 'Tpda3::Wx::Screen';

use Wx::Event qw(EVT_DATE_CHANGED);
use Wx::Calendar;

use Tpda3::Wx::ComboBox;
use Tpda3::Wx::Grid;

=head1 NAME

Tpda3::App::Test::Orders screen

=head1 VERSION

Version 0.51

=cut

our $VERSION = 0.51;

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

    #--- Comment

    my $ecomments = Wx::TextCtrl->new(
        $rec_page,
        -1,
        q{},
        [ -1, -1 ],
        [ -1, -1 ],
        wxTE_MULTILINE,
    );

    #-- ordertotal
    my $lordertotal = Wx::StaticText->new( $rec_page, -1, 'Order total' );
    my $eordertotal
        = Wx::TextCtrl->new( $rec_page, -1, q{}, [ -1, -1 ], [ -1, -1 ] );

    #--- Layout

    my $main_sz = Wx::FlexGridSizer->new( 3, 1, 5, 5 );

    my $top_sz = Wx::FlexGridSizer->new( 1, 2, 0, 0 );
    my $mid_sz = Wx::BoxSizer->new(wxHORIZONTAL);
    my $bot_sz = Wx::BoxSizer->new(wxHORIZONTAL);

    $top_sz->AddGrowableCol(0,1);

    $main_sz->AddGrowableRow(1);
    $main_sz->AddGrowableCol(1);

    #-- Top

    #-- Label frame
    my $order_sb  = Wx::StaticBox->new( $rec_page, -1, ' Order ' );
    my $order_sbs = Wx::StaticBoxSizer->new( $order_sb, wxHORIZONTAL, );

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

    $grid->AddGrowableCol(1);
    $grid->AddGrowableCol(2);
    $grid->AddGrowableCol(3);

    $order_sbs->Add( $grid, 1, wxALL | wxGROW, 0 );
    $top_sz->Add( $order_sbs, 0, wxALL | wxGROW, 5 );

    my $comment_sb  = Wx::StaticBox->new( $rec_page, -1, ' Comment ' );
    my $comment_sbs = Wx::StaticBoxSizer->new( $comment_sb, wxHORIZONTAL, );

    $comment_sbs->Add( $ecomments, 1, wxALL | wxEXPAND, 5 );
    $top_sz->Add( $comment_sbs, 1, wxALL | wxEXPAND, 5 );

    #-- Middle

    my $table = Tpda3::Wx::Grid->new( $rec_page );

    my $article_sb  = Wx::StaticBox->new( $rec_page, -1, ' Articles ' );
    my $article_sbs = Wx::StaticBoxSizer->new( $article_sb, wxHORIZONTAL, );

    $article_sbs->Add( $table, 1, wxALL | wxEXPAND, 5 );
    $mid_sz->Add($article_sbs, 1, wxALL | wxEXPAND, 5 );

    #-- Bottom

    my $grid_bot = Wx::GridBagSizer->new( 5, 5 );

    #-- ordertotal
    $grid_bot->Add(
        $lordertotal,
        gbpos( 0, 1 ),
        gbspan( 1, 1 ),
        wxLEFT | wxRIGHT, 5
    );
    $grid_bot->Add(
        $eordertotal,
        gbpos( 0, 2 ),
        gbspan( 1, 1 ),
        wxEXPAND | wxLEFT | wxRIGHT, 5
    );

    #-- Label frame
    my $total_sb  = Wx::StaticBox->new( $rec_page, -1, ' Order total' );
    my $total_sbs = Wx::StaticBoxSizer->new( $total_sb, wxHORIZONTAL, );

    $total_sbs->Add( $grid_bot, 1, wxALL | wxEXPAND, 5 );
    $bot_sz->Add($total_sbs, 1, wxALL | wxEXPAND, 5 );

    #-- Layout

    $main_sz->Add( $top_sz, 0, wxALL | wxGROW, 5 );
    $main_sz->Add( $mid_sz, 0, wxALL | wxGROW, 5 );
    $main_sz->Add( $bot_sz, 0, wxALL | wxGROW, 5 );

    $rec_page->SetSizer($main_sz);

    #-- Layout end

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
        ordertotal     => [ undef, $eordertotal ],
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
