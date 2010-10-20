#
# TpdaMvc::Config test script
#
# From Class::Singleton test script
#   by Andy Wardley <abw@wardley.org>

use strict;
use warnings;

use Test::More tests => 5;

use lib qw( lib ../lib );

use TpdaMvc::Config;

my $args = {
    cfgname => 'test',
    user    => undef,
    pass    => undef,
};

#-- Check the one instance functionality

# No instance if instance() not called yet
ok( ! TpdaMvc::Config->has_instance(), 'no TpdaMvc::Config instance yet' );

my $c1 = TpdaMvc::Config->instance( $args );
ok( $c1->isa('TpdaMvc::Config'), 'created TpdaMvc::Config instance 1' );

my $c2 = TpdaMvc::Config->instance();
ok( $c2->isa('TpdaMvc::Config'), 'created TpdaMvc::Config instance 2' );

is( $c1, $c2, 'both instances are the same object' );

# Check some config key => value pairs ( stollen from Padre ;) )

ok( $c1->connection->{database} =~ m{testdb},
    'connection has expected config value for "database"' )
  or diag( '"database" defined as "'
      . $c1->connection->{database}
      . '" and not "testdb" in config' );

# end tests
