#
# Tpda3 Tk GUI test script
#

use strict;
use warnings;

use Test::More tests => 21;

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

is( ref $scrcfg->m_table, 'HASH', 'm_table' );

is( $scrcfg->m_table_name, 'orders', 'm_table_name' );

is( $scrcfg->m_table_view, 'v_orders', 'm_table_view' );

is( $scrcfg->m_table_generator, 'generator_name', 'm_table_generator' );

is( $scrcfg->m_table_pkcol, 'ordernumber', 'm_table_pkcol' );

is( ref $scrcfg->m_table_columns, 'HASH', 'm_table_columns' );

is( ref $scrcfg->m_table_column('customername'), 'HASH', 'm_table_column' );

is( $scrcfg->m_table_column_attr( 'customername', 'ctrltype' ),
    'e', 'm_table_column_attr' );

#--

my $tm_ds = 'tm1';

is( ref $scrcfg->d_table($tm_ds), 'HASH', 'd_table' );

is( $scrcfg->d_table_name($tm_ds), 'orderdetails', 'd_table_name' );

is( $scrcfg->d_table_view($tm_ds), 'v_orderdetails', 'd_table_view' );

is( $scrcfg->d_table_generator($tm_ds), 'generator_name', 'd_table_generator' );

is( $scrcfg->d_table_updatestyle($tm_ds), 'delete+add', 'd_table_updatestyle' );

is( $scrcfg->d_table_selectorcol($tm_ds), 'none', 'd_table_selectorcol' );

is( ref $scrcfg->d_table_columns($tm_ds), 'HASH', 'd_table_columns' );

is( ref $scrcfg->d_table_column( $tm_ds, 'productcode' ),
    'HASH', 'd_table_column' );

is( $scrcfg->d_table_column_attr( $tm_ds, 'productcode', 'id' ),
    1, 'd_table_column_attr' );

#-- End test
