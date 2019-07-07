use strict;
use warnings;

use Test2::V0;

use lib qw( lib ../lib );

use Tpda3::Model::Meta::Dep;

my $data = {
    metadata => {
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
    },
};

ok my $tmu = Tpda3::Model::Meta::Dep->new($data), 'new object';

my $meta = $data->{metadata};

is $tmu->table,    $meta->{table},    'dep table name';
is $tmu->fkcol,    $meta->{fkcol},    'fkcol';
is $tmu->order,    $meta->{order},    'order';
is $tmu->pkcol,    $meta->{pkcol},    'pkcol';
is $tmu->updstyle, $meta->{updstyle}, 'updstyle';

is $tmu->where, $meta->{where}, 'dep table where';

is $tmu->colslist, $meta->{colslist}, 'colslist';

done_testing;
