#
# Tpda3 Tk TMSHR test script
#
# Bug?:
# t/35-tk-tmshr.t ...... 1/6 Use of uninitialized value in numeric ne (!=)
# at blib/lib/Tk/Frame.pm (autosplit into
# blib/lib/auto/Tk/Frame/sbset.al) line 212,
# from 'make test' but not from 'prove' :(

use strict;
use warnings;

use Test::More;
use Tk;

use lib qw( lib ../lib );

BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }

    eval { use Tk; };
    if ($@) {
        plan( skip_all => 'Perl Tk is required for this test' );
    }

    plan tests => 6;
}

use_ok('Tpda3::Tk::TMSHR');

# Header for TMSHR, slightly modified data, all cols are 'ro'

my $header = {
    colstretch  => undef,
    columns     => {
        orderlinenumber => {
            id         => '1',
            places     => '0',
            width      => '3',
            validation => 'integer',
            order      => 'N',
            label      => '#',
            tag        => 'ro_center',
            rw         => 'ro',
            show       => '1',
            datasource => '=count',
        },
        productline => {
            id         => '2',
            places     => '0',
            width      => '15',
            validation => 'alphanumplus',
            order      => 'A',
            label      => 'Line',
            tag        => 'ro_left',
            rw         => 'ro',
            show       => '1',
            datasource => 'products',
        },
        productname => {
            id         => '3',
            places     => '0',
            width      => '30',
            validation => 'alphanumplus',
            order      => 'A',
            label      => 'Product',
            tag        => 'ro_left',
            rw         => 'ro',
            show       => '1',
            datasource => 'firme',
        },
        quantityordered => {
            id         => '4',
            places     => '0',
            width      => '8',
            validation => 'numeric',
            order      => 'N',
            label      => 'Quantity',
            tag        => 'enter_right',
            rw         => 'ro',
            show       => '1',
            datasource => 'firme',
        },
        priceeach => {
            id         => '5',
            places     => '2',
            width      => '8',
            validation => 'numeric',
            order      => 'N',
            label      => 'Price',
            tag        => 'enter_right',
            rw         => 'ro',
            show       => '1',
            datasource => 'firme',
        },
        ordervalue => {
            id         => '6',
            places     => '2',
            width      => '8',
            validation => 'numeric',
            order      => 'A',
            label      => 'Value',
            tag        => 'ro_right',
            rw         => 'ro',
            show       => '1',
            datasource => '=quantityordered*priceeach',
        },
    },
};

# Data for tests - main data

my $record
    = [ { productline => 'Vintage Cars', }, { productline => 'Planes', }, ];

my $expdata_1 = [
    {   priceeach       => '37.97',
        quantityordered => '29',
        productname     => '1930 Buick Marquette Phaeton',
    },
];

my $expdata_4 = [
    {   priceeach       => '81.29',
        quantityordered => '48',
        productname     => 'American Airlines: B767-300',
    },
    {   priceeach       => '70.40',
        quantityordered => '38',
        productname     => 'F/A 18 Hornet 1/72',
    },
];

my $mw = tkinit;
$mw->geometry('+20+20');

my $tm;
my ( $xtvar, $expand_data ) = ( {}, {} );
eval {
    $tm = $mw->Scrolled(
        'TMSHR',
        -rows           => 5,
        -cols           => 1,
        -width          => -1,
        -height         => -1,
        -ipadx          => 3,
        -titlerows      => 1,
        -variable       => $xtvar,
        -selectmode     => 'single',
        -colstretchmode => 'unset',
        -resizeborders  => 'none',
        -bg             => 'white',
        -scrollbars     => 'osw',
        -expandData     => $expand_data,
    );
};
ok(!$@, 'create TMSHR');

is( $tm->make_header($header), undef, 'make header' );

$tm->pack( -expand => 1, -fill => 'both');

my $delay = 1;

$mw->after( $delay * 1000,
    sub { is( $tm->fill_main($record), undef, 'fill TMSHR' ); } );

# $delay++;

# $mw->after( $delay * 1000,
#     sub { is( $tm->fill_details($expdata_1, 1), undef, 'fill TMSHR det 1' ); } );

# $delay++;

# $mw->after( $delay * 1000,
#     sub { is( $tm->fill_details($expdata_4, 2), undef, 'fill TMSHR det 2' ); } );

$delay++;

$mw->after( $delay * 1000, sub { $mw->destroy } );

Tk::MainLoop;

#-- End test
