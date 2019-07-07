use strict;
use warnings;

use Test2::V0;

use lib qw( lib ../lib );

use Tpda3::Model::Update::Compare;

# An orders + orderdetails record:

my $record = [
  {
    data => {
      comments       => undef,
      customernumber => 475,
      orderdate      => "2003-12-01",
      ordernumber    => 10199,
      ordertotal     => "0.00",
      requireddate   => "2003-12-10",
      shippeddate    => "2003-12-06",
      statuscode     => "S",
    },
    metadata => { table => "orders", where => { ordernumber => 10199 } },
  },
  {
    tm1 => {
             data => [
               {
                 orderlinenumber => 1,
                 ordernumber     => 10199,
                 priceeach       => 37.97,
                 productcode     => "S50_1341",
                 quantityordered => 29,
               },
               {
                 orderlinenumber => 2,
                 ordernumber     => 10199,
                 priceeach       => 81.29,
                 productcode     => "S700_1691",
                 quantityordered => 48,
               },
               {
                 orderlinenumber => 3,
                 ordernumber     => 10199,
                 priceeach       => 70.4,
                 productcode     => "S700_3167",
                 quantityordered => 38,
               },
             ],
             metadata => {
               colslist => [
                             "orderlinenumber",
                             "productcode",
                             "productname",
                             "quantityordered",
                             "priceeach",
                             "ordervalue",
                           ],
               fkcol    => "orderlinenumber",
               order    => "orderlinenumber",
               pkcol    => "ordernumber",
               table    => "orderdetails",
               updstyle => "update",
               where    => { ordernumber => 10199 },
             },
           },
  },
];

my $tm_data = [
  {
    orderlinenumber => 1,
    ordernumber     => 10199,
    priceeach       => 37.97,
    productcode     => "S50_1341",
    quantityordered => 29,
  },
  {
    orderlinenumber => 2,
    ordernumber     => 10199,
    priceeach       => 81.29,
    productcode     => "S700_1691",
    quantityordered => 48,
  },
];

my $tm_data_hoh = {
    1 => {
        orderlinenumber => 1,
        ordernumber     => 10199,
        priceeach       => 37.97,
        productcode     => "S50_1341",
        quantityordered => 29,
    },
    2 => {
        orderlinenumber => 2,
        ordernumber     => 10199,
        priceeach       => 81.29,
        productcode     => "S700_1691",
        quantityordered => 48,
    },
};

my $db_data_hoh = {
    1 => {
        orderlinenumber => 1,
        ordernumber     => 10199,
        priceeach       => 37.97,
        productcode     => "S50_1341",
        quantityordered => 29,
    },
    2 => {
        orderlinenumber => 2,
        ordernumber     => 10199,
        priceeach       => 81.29,
        productcode     => "S700_1691",
        quantityordered => 48,
    },
    3 => {
        orderlinenumber => 3,
        ordernumber     => 10199,
        priceeach       => 70.4,
        productcode     => "S700_3167",
        quantityordered => 38,
    },
};

my $db_data = $record->[1]{tm1}{data};

ok my $mu = Tpda3::Model::Update::Compare->new(
    fk_key    => 'orderlinenumber',
    db_data   => $db_data,
    tm_data   => $tm_data,
), 'new update object';

is $mu->tm_fk_data, [ 1, 2 ], 'tm_fk_data';
is $mu->db_fk_data, [ 1, 2, 3 ], 'db_fk_data';

is $mu->to_insert, [], 'fk to insert';
is $mu->to_delete, [3], 'fk to delete';
is $mu->_to_update, [ 1, 2 ], 'fk to update';

is $mu->aoh_to_hoh( $tm_data, 'orderlinenumber' ), $tm_data_hoh, 'aoh_to_hoh';

is $mu->tm_data_hoh, $tm_data_hoh, 'tm_data_hoh';
is $mu->db_data_hoh, $db_data_hoh, 'db_data_hoh';

is $mu->to_update, [], 'records to update';

done_testing;
