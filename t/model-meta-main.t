use strict;
use warnings;

use Test2::V0;

use lib qw( lib ../lib );

use Tpda3::Model::Meta::Main;

my $data = {
    metadata => {
        table => "orders",
        where => {
            ordernumber => 10199 },
    },
};

ok my $tmu = Tpda3::Model::Meta::Main->new($data), 'new object';

my $meta = $data->{metadata};

is $tmu->table, $meta->{table}, 'main table name';

is $tmu->where, $meta->{where}, 'main table where';

done_testing;
