#
# Testing Tpda3::Config::Screen::Details
#

use Test2::V0;

use lib qw( lib ../lib );

use Tpda3::Config::Screen::Details;

ok my $dets = Tpda3::Config::Screen::Details->new(), 'new object';

done_testing;
