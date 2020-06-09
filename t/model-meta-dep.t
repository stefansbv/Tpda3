use strict;
use warnings;

use Test2::V0;

use lib qw( lib ../lib );

use Tpda3::Model::Meta::Dep;

my $metadata = {
    colslist => [
        "orderlinenumber", "productcode",
        "productname",     "quantityordered",
        "priceeach",       "ordervalue",
    ],
    fkcol    => "orderlinenumber",
    order    => "orderlinenumber",
    pkcol    => "ordernumber",
    table    => "orderdetails",
    updstyle => "update",
    where    => { ordernumber => 10199 },
};

ok my $tmu = Tpda3::Model::Meta::Dep->new(
    pk_key    => 'ordernumber',
    pk_val    => 10199,
    main_keys => ['ordernumber'],
    metadata  => $metadata,
), 'new object';

is $tmu->table,    $metadata->{table},    'dep table name';
is $tmu->fkcol,    $metadata->{fkcol},    'fkcol';
is $tmu->order,    $metadata->{order},    'order';
is $tmu->pkcol,    $metadata->{pkcol},    'pkcol';
is $tmu->updstyle, $metadata->{updstyle}, 'updstyle';

is $tmu->where, $metadata->{where}, 'dep table where';

is $tmu->colslist, $metadata->{colslist}, 'colslist';

done_testing;
