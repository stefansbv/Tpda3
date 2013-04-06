#!/usr/bin/perl

package TableFrame;

use strict;
use warnings;
use Carp;

use Wx qw[:everything];
use base qw(Wx::Frame);

use lib 'lib';

use Tpda3::Wx::Grid;

my $header = {
    colstretch    => 2,
    selectorcol   => '',
    selectorstyle => '',
    columns       => {
        productcode => {
            id          => 1,
            label       => 'Code',
            tag         => 'find_center',
            displ_width => 15,
            valid_width => 15,
            numscale    => 0,
            readwrite   => 'rw',
            datatype    => 'alphanum',
        },
        ordervalue => {
            id          => 5,
            label       => 'Value',
            tag         => 'ro_right',
            displ_width => 12,
            valid_width => 12,
            numscale    => 2,
            readwrite   => 'rw',
            datatype    => 'numeric',
        },
        quantityordered => {
            id          => 3,
            label       => 'Quantity',
            tag         => 'enter_right',
            displ_width => 12,
            valid_width => 12,
            numscale    => 0,
            readwrite   => 'rw',
            datatype    => 'numeric',
        },
        productname => {
            id          => 2,
            label       => 'Product',
            tag         => 'ro_left',
            displ_width => 36,
            valid_width => 36,
            numscale    => 0,
            readwrite   => 'rw',
            datatype    => 'alphanumplus',
        },
        priceeach => {
            id          => 4,
            label       => 'Price',
            tag         => 'enter_right',
            displ_width => 12,
            valid_width => 12,
            numscale    => 2,
            readwrite   => 'rw',
            datatype    => 'numeric',
        },
        orderlinenumber => {
            id          => 0,
            label       => 'Art',
            tag         => 'ro_center',
            displ_width => 5,
            valid_width => 5,
            numscale    => 0,
            readwrite   => 'rw',
            datatype    => 'integer',
        }
    },
};

# Data for tests

my $record = [
    {   priceeach       => '37.97',
        productcode     => 'S50_1341',
        ordervalue      => '1101.13',
        quantityordered => '29',
        productname     => '1930 Buick Marquette Phaeton',
        orderlinenumber => '1'
    },
    {   priceeach       => '81.29',
        productcode     => 'S700_1691',
        ordervalue      => '3901.92',
        quantityordered => '48',
        productname     => 'American Airlines: B767-300',
        orderlinenumber => '2'
    },
    {   priceeach       => '70.40',
        productcode     => 'S700_3167',
        ordervalue      => '2675.20',
        quantityordered => '38',
        productname     => 'F/A 18 Hornet 1/72',
        orderlinenumber => '3'
    }
];

sub new {

    my $self = shift;

    $self = $self->SUPER::new(
        undef, -1, 'Table demo',
        [ -1, -1 ],
        [ -1, -1 ],
        wxDEFAULT_FRAME_STYLE,
    );

    Wx::InitAllImageHandlers();

    #- Grid Sizer

    my $panel = Wx::Panel->new($self);

    my $sizer = Wx::BoxSizer->new(wxVERTICAL);

    my $table
        = Tpda3::Wx::Grid->new( $panel, -1, undef, undef, undef,
        $header->{columns} );

    $sizer->Add($table, 1, wxEXPAND, 5 );

    $panel->SetSizerAndFit($sizer);

    return $self;
}

1;

package TableApp;

use base 'Wx::App';

sub OnInit {

    my $frame = TableFrame->new();

    $frame->Show( 1 );
}

package main;

use strict;
use warnings;

my $app = TableApp->new();

$app->MainLoop;

1;
