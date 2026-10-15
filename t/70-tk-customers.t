#
# Tpda3 Tk GUI test script
#

use strict;
use warnings;
use Test::More;

# Don't run tests for installs
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

use lib qw( lib ../lib );

use Tpda3::Tk::ScreenTest q{test_screen};

my $args = {
    cfname => 'test-tk',
    user   => 'user',
    pass   => 'pass',
    cfpath => 'share/',
};

test_screen($args, 'Tpda3::Tk::App::Test::Customers');

done_testing();
