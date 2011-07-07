#
# Tpda3 Tk GUI test script
#

use strict;
use warnings;

use Test::More tests => 19;

use lib qw( lib ../lib );

use Tpda3::Config;
use Tpda3::Config::Screen;

my $args = {
    cfname => 'test-tk',
    user   => 'user',
    pass   => 'pass',
};

#-- Check the one instance functionality

# No instance if instance() not called yet
ok( !Tpda3::Config->has_instance(), 'no Tpda3::Config instance yet' );

my $c1 = Tpda3::Config->instance($args);
ok( $c1->isa('Tpda3::Config'), 'created Tpda3::Config instance' );

# Load the new screen configuration
my $scrcfg = Tpda3::Config::Screen->new();
ok( $scrcfg->isa('Tpda3::Config::Screen'), 'created Tpda3::Config::Screen' );

is( $scrcfg->config_screen_load('orders'), undef, 'Load orders.conf' );

is( ref $scrcfg->main_table, 'HASH', 'main_table' );

is( $scrcfg->main_table_name, 'orders', 'main_table_name' );

is( $scrcfg->main_table_view, 'v_orders', 'main_table_view' );

is( $scrcfg->main_table_pkcol, 'ordernumber', 'main_table_pkcol' );

is( ref $scrcfg->main_table_columns, 'HASH', 'main_table_columns' );

is( ref $scrcfg->main_table_column('customername'), 'HASH', 'main_table_column' );

is( $scrcfg->main_table_column_attr( 'customername', 'ctrltype' ),
    'e', 'main_table_column_attr' );

#--

my $tm_ds = 'tm1';

is( ref $scrcfg->dep_table($tm_ds), 'HASH', 'dep_table' );

is( $scrcfg->dep_table_name($tm_ds), 'orderdetails', 'dep_table_name' );

is( $scrcfg->dep_table_view($tm_ds), 'v_orderdetails', 'dep_table_view' );

is( $scrcfg->dep_table_updatestyle($tm_ds), 'delete+add', 'dep_table_updatestyle' );

is( $scrcfg->dep_table_selectorcol($tm_ds), 'none', 'dep_table_selectorcol' );

is( ref $scrcfg->dep_table_columns($tm_ds), 'HASH', 'dep_table_columns' );

is( ref $scrcfg->dep_table_column( $tm_ds, 'productcode' ),
    'HASH', 'dep_table_column' );

is( $scrcfg->dep_table_column_attr( $tm_ds, 'productcode', 'id' ),
    1, 'dep_table_column_attr' );

#-- End test
