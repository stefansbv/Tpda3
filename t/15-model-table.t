#
# Testing Tpda3::Model::Table
#

use strict;
use warnings;
use Test2::V0;
use lib qw( lib ../lib );

use Tpda3::Model::Table;

#-- Test Key and Value modules

subtest 'Generic table' => sub {
    my $params = {
        page      => 'rec',
        display   => 'record',
        keys      => [qw{field1 field2 field3}],
        table     => 'table',
        view      => 'view',
        fields    => [qw{field1 field2 field3 field4 field5}],
        fields_rw => [qw{field1 field2 field3}],
    };

    ok my $table = Tpda3::Model::Table->new($params), 'new table object';

    is $table->page, 'rec', 'page';
    is $table->display, 'record', 'display';

    is $table->table, 'table', 'check table name';
    is $table->view,  'view',  'check view name';

    is $table->fields, [qw{field1 field2 field3 field4 field5}],
        'check fields';
    is $table->fields_rw, [qw{field1 field2 field3}], 'check rw fields';

    is $table->count_keys, 3, 'count keys';

    is $table->get_key(0)->value, undef, 'check field1 value';

    ok $table->update_key_field( 'field1', 101 ), 'update field1 value';

    is $table->get_key(0)->name,  'field1', 'check field1 name';
    is $table->get_key(0)->value, 101,      'check field1 value 101';

    ok $table->update_key_field( 'field1', 1001 ), 'update field1 value';
    is $table->get_key(0)->value, 1001, 'check field1 value 1001';

    ok $table->update_key_index( 1, 1002 ), 'update field2 value';
    is $table->get_key(1)->value, 1002, 'check field2 value 1002';

    is $table->update_key_index( 2, undef ), undef, 'clear field3 value';
    is $table->get_key(2)->value, undef, 'check field3 value undef ';

    is $table->update_key_field( 'field1', undef ), undef,
        'clear field1 value';
    is $table->get_key(0)->value, undef, 'check field1 value undef ';

    ok my @a_keys = $table->all_keys, 'get all keys';
    my $expected = [
        { name => 'field1', value => undef },
        { name => 'field2', value => 1002 },
        { name => 'field3', value => undef }
    ];
    is \@a_keys, $expected, 'check all keys';

    ok my @b_keys = $table->all_keys, 'get all keys';
    foreach my $key (@b_keys) {
        like $key->name, qr/field\d/, 'get the key name';
        ok $key->can('value'), 'key has some value';
    }

    ok my @values = $table->map_keys( sub { $_->value } ), 'map_keys';
    is \@values, [undef, 1002, undef], 'map_keys values';
};

subtest 'main table - orders' => sub {
    my $params = {
        page    => 'rec',
        display => 'record',
        keys    => [qw{ordernumber}],
        table   => 'orders',
        view    => 'v_orders',
        fields  => [
            qw{
                customername
                customernumber
                ordernumber
                orderdate
                requireddate
                shippeddate
                statuscode
                comments
                ordertotal
                }
        ],
        fields_rw => [
            qw{
                customernumber
                ordernumber
                orderdate
                requireddate
                shippeddate
                statuscode
                comments
                ordertotal
                }
        ],
    };

    ok my $table = Tpda3::Model::Table->new($params), 'new table object';

    is $table->page, 'rec', 'page';
    is $table->display, 'record', 'display';

    is $table->table, 'orders',      'check table name';
    is $table->view,  'v_orders',    'check view name';
    is $table->pkcol, 'ordernumber', 'check pk col name';
    is $table->fkcol, undef, 'check fk col name';
};

subtest 'dependent table - orderdetails' => sub {
    my $params = {
        page     => 'rec',
        display  => 'table',
        keys     => [qw{ordernumber orderlinenumber}],
        table    => 'orderdetails',
        view     => 'v_orderdetails',
        order    => ['orderlinenumber'],
        updstyle => 'delete+add',
        fields   => [
            qw{
                orderlinenumber
                productcode
                productname
                quantityordered
                priceeach
                ordervalue
                }
        ],
        fields_rw => [
            qw{
                orderlinenumber
                productcode
                quantityordered
                priceeach
                }
        ],
    };

    ok my $table = Tpda3::Model::Table->new($params), 'new table object';

    is $table->page, 'rec', 'page';
    is $table->display, 'table', 'display';

    is $table->table, 'orderdetails',    'check table name';
    is $table->view,  'v_orderdetails',  'check view name';
    is $table->pkcol, 'ordernumber',     'check pk col name';
    is $table->fkcol, 'orderlinenumber', 'check fk col name';
    is $table->order, ['orderlinenumber'], 'check order';
    is $table->updstyle, 'delete+add', 'check update style';
};

done_testing;
