#
# Tpda3 Tk GUI test script
#

use strict;
use warnings;
use Test::More;

use lib qw( lib ../lib );

use Tpda3::Tk::ScreenTest q{test_screen};

my $args = {
    cfname => 'test-tk',
    user   => 'user',
    pass   => 'pass',
    cfpath => 'share/',
};

test_screen($args, 'Tpda3::Tk::App::Test::Orders');

done_testing();
