#
# Testing Tpda3::Model::Table
#

use strict;
use warnings;

use Test::More tests => 18;

use lib qw( lib ../lib );

use Tpda3::Model::Table;

#-- Test Key and Value modules

my $params = {
    keys   => [qw{field1 field2 field3}],
    table  => 'table',
    view   => 'view',
};

ok( my $table = Tpda3::Model::Table->new($params), 'new key object' );

is($table->table, 'table', 'check table name');
is($table->view, 'view', 'check view name');

is($table->count_keys, 3, 'count keys');

is($table->get_key(0)->value, undef, 'check field1 value');

ok($table->update_key_field( 'field1', 101 ), 'update field1 value');

is($table->get_key(0)->name, 'field1', 'check field1 name');
is($table->get_key(0)->value, 101, 'check field1 value 101');

ok($table->update_key_field( 'field1', 1001 ), 'update field1 value');
is($table->get_key(0)->value, 1001, 'check field1 value 1001');

ok($table->update_key_index(1, 1002 ), 'update field2 value');
is($table->get_key(1)->value, 1002, 'check field2 value 1002');

is($table->update_key_index(2, undef ), undef, 'clear field3 value');
is($table->get_key(2)->value, undef, 'check field3 value undef ');

is($table->update_key_field( 'field1', undef ), undef, 'clear field1 value');
is($table->get_key(0)->value, undef, 'check field1 value undef ');

ok(my @keys = $table->all_keys, 'get all keys');
my $expected = [
    { name => 'field1', value => undef },
    { name => 'field2', value => 1002  },
    { name => 'field3', value => undef }
];
is_deeply( \@keys, $expected, 'check all keys' );

#-- done testing
