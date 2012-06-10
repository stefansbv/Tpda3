#
# Tpda3 Tk GUI test script
#

use strict;
use warnings;

use lib qw( lib ../lib t/lib );

use TkScreenTest q{test_screen};

test_screen('Tpda3::Tk::App::Test::Customers');

# done
