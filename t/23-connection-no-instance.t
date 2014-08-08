#
# Tpda3::Db::Connection test script - direct, no instance
#

use strict;
use warnings;

use Test::More tests => 5;

use lib qw( lib ../lib );
use t::lib::TkTest qw/make_database/;

use Tpda3::Config;
use Tpda3::Db::Connection;

my $args = {
    cfname => 'test-tk',
    user   => 'user',
    pass   => 'pass',
    cfpath => 'share/',
};

ok my $c1 = Tpda3::Config->instance($args), 'create new config instance';
ok $c1->isa('Tpda3::Config'), 'isa Tpda3::Config instance 1';
ok my $conn = Tpda3::Db::Connection->new, 'new connection';
ok $conn->{dbh}->isa('DBI::db'), 'Connected';
ok $conn->{dbh}->disconnect, 'Disconnect';

# end test
