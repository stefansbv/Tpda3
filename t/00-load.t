#
# TpdaMvc::Config test script
#
# From Class::Singleton test script
#   by Andy Wardley <abw@wardley.org>

use Test::More tests => 10;

diag( "Testing with Perl $], $^X" );

use_ok('TpdaMvc');
use_ok('TpdaMvc::Config');
use_ok('TpdaMvc::Config::Utils');
use_ok('TpdaMvc::Db');
use_ok('TpdaMvc::Db::Connection');
use_ok('TpdaMvc::Db::Connection::Postgresql');
use_ok('TpdaMvc::Model');
use_ok('TpdaMvc::Observable');
use_ok('TpdaMvc::Tk::Controller');
use_ok('TpdaMvc::Tk::View');
