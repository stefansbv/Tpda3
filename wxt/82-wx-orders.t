#
# Tpda3 Wx GUI test script
#

use strict;
use warnings;

use lib qw( lib ../lib );

use Tpda3::Wx::ScreenTest q{test_screen};

my $args = {
    cfname => 'test-wx',
    user   => 'user',
    pass   => 'pass',
    cfpath => 'share/',
};

test_screen($args, 'Tpda3::Wx::App::Test::Orders');

# done
