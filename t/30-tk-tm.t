#
# Tpda3 Tk TM test script
#

use strict;
use warnings;

use Test::More;

use lib qw( lib ../lib );

use Tk;
# use Tpda3;
# use Tpda3::Config;
use Tpda3::Tk::TM;

BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }

    eval { use Tk; };
    if ($@) {
        plan( skip_all => 'Perl Tk is required for this test' );
    }

    plan tests => 9;
}

use_ok('Tpda3::Tk::TM');

my $fields = {
    'priceeach' => {
        'places'     => '2',
        'width'      => '12',
        'validation' => 'numeric',
        'order'      => 'N',
        'id'         => '4',
        'label'      => 'Price',
        'tag'        => 'enter_right',
        'rw'         => 'rw'
    },
    'productcode' => {
        'places'     => '0',
        'width'      => '15',
        'validation' => 'alphanum',
        'order'      => 'A',
        'id'         => '1',
        'label'      => 'Code',
        'tag'        => 'find_center',
        'rw'         => 'rw'
    },
    'ordervalue' => {
        'places'     => '2',
        'width'      => '12',
        'validation' => 'numeric',
        'order'      => 'A',
        'id'         => '5',
        'label'      => 'Value',
        'tag'        => 'ro_right',
        'rw'         => 'ro'
    },
    'quantityordered' => {
        'places'     => '0',
        'width'      => '12',
        'validation' => 'numeric',
        'order'      => 'N',
        'id'         => '3',
        'label'      => 'Quantity',
        'tag'        => 'enter_right',
        'rw'         => 'rw'
    },
    'productname' => {
        'places'     => '0',
        'width'      => '36',
        'validation' => 'alphanumplus',
        'order'      => 'A',
        'id'         => '2',
        'label'      => 'Product',
        'tag'        => 'ro_left',
        'rw'         => 'ro'
    },
    'orderlinenumber' => {
        'places'     => '0',
        'width'      => '5',
        'validation' => 'integer',
        'order'      => 'N',
        'id'         => '0',
        'label'      => 'Art',
        'tag'        => 'ro_center',
        'rw'         => 'rw'
    }
};

my $record = [
    {
        'priceeach'       => '37.97',
        'productcode'     => 'S50_1341',
        'ordervalue'      => '1101.13',
        'quantityordered' => '29',
        'productname'     => '1930 Buick Marquette Phaeton',
        'orderlinenumber' => '1'
    },
    {
        'priceeach'       => '81.29',
        'productcode'     => 'S700_1691',
        'ordervalue'      => '3901.92',
        'quantityordered' => '48',
        'productname'     => 'American Airlines: B767-300',
        'orderlinenumber' => '2'
    },
    {
        'priceeach'       => '70.4',
        'productcode'     => 'S700_3167',
        'ordervalue'      => '2675.2',
        'quantityordered' => '38',
        'productname'     => 'F/A 18 Hornet 1/72',
        'orderlinenumber' => '3'
    }
];

my $mw = tkinit;
$mw->geometry("680x200+10+10");

my $tm;
eval { $tm = Tpda3::Tk::TM->new($mw, $fields) };
$tm->pack;

is( ref $tm, "Tpda3::Tk::TM", "TM object");

is($tm->fill($record), undef, 'Fill TM');

# my $data;
# eval { ($data) = $tm->data_read(); };
# ok ($@, "Error: data_read");

# eval { $tm->destroy; };
# ok($@, "can't destroy TM widget");

# my $cell_data = $tm->cell_read(1,1);

# $tm->clear_all;

# $tm->add_row();
# $tm->write_row( 1, 0, $record->[0] );

# $tm->add_row();
# $tm->write_row( 2, 0, $record->[1] );

$mw->after(1500, sub { $mw->destroy } );

Tk::MainLoop;

#-- End test
