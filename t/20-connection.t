#
# Tpda3::Db test script
#
# Inspired from the Class::Singleton test script by Andy Wardley
#

use strict;
use warnings;

use Test::More tests => 7;

use lib qw( lib ../lib );

use Tpda3::Config;

my $args = {
    cfname => 'test-tk',
    user   => $ENV{USER},
    pass   => undef,
};

my $c1 = Tpda3::Config->instance($args);
ok( $c1->isa('Tpda3::Config'), 'created Tpda3::Config instance 1' );

use Tpda3::Db;

#-- Check the one instance functionality

# No instance if instance() not called yet
ok( ! Tpda3::Db->has_instance(), 'no Tpda3::Db instance yet' );

my $d1 = Tpda3::Db->instance();
ok( $d1->isa('Tpda3::Db'), 'created Tpda3::Db instance 1' );

my $d2 = Tpda3::Db->instance();
ok( $d2->isa('Tpda3::Db'), 'created Tpda3::Db instance 2' );

is( $d1, $d2, 'both instances are the same object' );

my $dbh = Tpda3::Db->instance->dbh;
ok( $dbh->isa('DBI::db'), 'Connected' );

ok( $dbh->disconnect, 'Disconnect' );

# end test
