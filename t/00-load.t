#
# TpdaMvc::Config test script
#
# From Class::Singleton test script
#   by Andy Wardley <abw@wardley.org>

use Test::More tests => 2;

diag( "Testing with Perl $], $^X" );

use_ok('TpdaMvc');
use_ok('TpdaMvc::Config');
