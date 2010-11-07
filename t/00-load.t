#
# Tpda3::Config test script
#
# From Class::Singleton test script
#   by Andy Wardley <abw@wardley.org>

use Test::More tests => 12;

diag( "Testing with Perl $], $^X" );

use_ok('Tpda3');
use_ok('Tpda3::Utils');
use_ok('Tpda3::Config');
use_ok('Tpda3::Config::Utils');
use_ok('Tpda3::Db');
use_ok('Tpda3::Db::Connection');
use_ok('Tpda3::Db::Connection::Postgresql');
use_ok('Tpda3::Model');
use_ok('Tpda3::Observable');
use_ok('Tpda3::Tk::Controller');
use_ok('Tpda3::Tk::View');
use_ok('Tpda3::Tk::Dialog::Configs');
