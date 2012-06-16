#
# Tpda3 Tk GUI test script
#

use strict;
use warnings;

use lib qw( lib ../lib t/lib );

use TkScreenTest q{test_screen};

my $args = {
    cfname => 'test-tk',
    user   => undef,
    pass   => undef,
};

test_screen($args, 'Tpda3::Tk::App::Test::Orders');

# done
