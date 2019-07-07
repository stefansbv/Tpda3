use strict;
use warnings;

use Test2::V0;

use lib qw( lib ../lib );

use Tpda3::Model::Update;
use Tpda3::Model::Update::Compare;
use Tpda3::Model::Meta::Main;
use Tpda3::Model::Meta::Dep;

use Data::Dump;

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

# depdata from TM:

my $tm_data = [
  {
    orderlinenumber => 1,
    ordernumber     => 10199,
    priceeach       => 37.97,
    productcode     => "S50_1341",
    quantityordered => 99,
  },
  {
    orderlinenumber => 2,
    ordernumber     => 10199,
    priceeach       => 81.29,
    productcode     => "S700_1691",
    quantityordered => 99,
  },
  {
    orderlinenumber => 4,
    ordernumber     => 10199,
    priceeach       => 90.52,
    productcode     => "S700_2047",
    quantityordered => 10,
  },
];

my $db_data = $record->[1]{tm1}{data};

ok my $muc = Tpda3::Model::Update::Compare->new(
    fk_key    => 'orderlinenumber',
    db_data   => $db_data,
    tm_data   => $tm_data,
), 'new update object';

is $muc->to_insert, [4], 'fk to insert';
is $muc->to_delete, [3], 'fk to delete';
is $muc->to_update, [1, 2], 'records to update';

my $meta_m_data = $record->[0];
my $meta_d_data = $record->[1]{tm1};

ok my $mm = Tpda3::Model::Meta::Main->new($meta_m_data), 'new Meta::Main';
ok my $md = Tpda3::Model::Meta::Dep->new($meta_d_data), 'new Meta::Dep';

ok my $mu = Tpda3::Model::Update->new(
    meta_main => $mm,
    meta_dep  => $md,
    compare   => $muc,
), 'new update object';

ok $mu->where_for_insert(1), '';

done_testing;
