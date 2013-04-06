#!/bin/env perl
#
# Inspired from the tests of the Wx-Scintilla module,
# Copyright (C) 2011 Ahmad M. Zawawi,
# the MyTimer package is copied verbatim.
#
use strict;
use warnings;

use Test::More;

BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }

    eval { require Wx; };
    if ($@) {
        plan( skip_all => 'wxPerl is required for this test' );
    }
    else {
        plan tests => 14;
    }
}

package MyTimer;

use Wx qw(:everything);
use Wx::Event;

use vars qw(@ISA); @ISA = qw(Wx::Timer);

sub Notify {
    my $self  = shift;
    my $frame = Wx::wxTheApp()->GetTopWindow;
    $frame->Destroy;
    main::ok( 1, "Grid instance destroyed" );
}

package TestApp;

use strict;
use warnings;

use Wx qw(:everything);
use Wx::Event;
use base 'Wx::App';

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

# We must override OnInit to build the window
sub OnInit {
    my $self = shift;

    my $frame = $self->{frame} = Wx::Frame->new( undef, -1, 'Test!', );

    my $columns = $header->{columns};
    my $table = Tpda3::Wx::Grid->new(
        $frame,
        -1,
        undef,
        undef,
        undef,
        $columns,
    );
    $table->init( undef, $header );

    main::ok( $table, 'Grid instance created' );

    # Fill the table and delete all
    foreach (1..3) {
        main::is( $table->fill($record), undef, 'fill TM' );
        main::is( $table->get_num_rows, 3, '3 rows' );
        main::is( $table->clear_all, undef, 'clear TM' );
        main::is( $table->get_num_rows, 0, 'no rows' );
    }

    # Uncomment this to observe the test
    # $frame->Show(1);

    MyTimer->new->Start( 500, 1 );

    return 1;
}

# Create the application object, and pass control to it.
package main;
my $app = TestApp->new;
$app->MainLoop;
