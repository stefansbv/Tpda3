#
# Tpda3::Config test script
#
# From Class::Singleton test script
#   by Andy Wardley <abw@wardley.org>

use strict;
use warnings;

use Test::More tests => 5;

use lib qw( lib ../lib );

use Tpda3::Config;

my $args = {
    cfname => 'test-tk',
    user   => $ENV{USER},
    pass   => 'pass',
};

#-- Check the one instance functionality

# No instance if instance() not called yet
ok( ! Tpda3::Config->has_instance(), 'no Tpda3::Config instance yet' );

my $c1 = Tpda3::Config->instance( $args );
ok( $c1->isa('Tpda3::Config'), 'created Tpda3::Config instance 1' );

my $c2 = Tpda3::Config->instance();
ok( $c2->isa('Tpda3::Config'), 'created Tpda3::Config instance 2' );

is( $c1, $c2, 'both instances are the same object' );

# Check some config key => value pairs ( stollen from Padre ;) )

ok( $c1->connection->{dbname} =~ m{classicmodels},
    'connection has expected config value for "dbname"' )
  or diag( '"dbname" defined as "'
      . $c1->connection->{dbname}
      . '" and not "classicmodels" in config' );

# end tests
