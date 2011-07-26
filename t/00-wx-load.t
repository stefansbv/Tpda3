#
# Tpda3 use test script
#

use Test::More;

BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }

    eval { require Wx; };
    if ($@) {
        plan( skip_all => 'wxPerl is required for this test' );
    }
    else {
        plan tests => 16;
    }
}

diag( "Testing with Perl $], $^X" );

use_ok('Tpda3');
use_ok('Tpda3::Utils');
use_ok('Tpda3::Config');
use_ok('Tpda3::Config::Utils');
use_ok('Tpda3::Db');
use_ok('Tpda3::Db::Connection');
use_ok('Tpda3::Db::Connection::Postgresql');
use_ok('Tpda3::Db::Connection::Firebird');
use_ok('Tpda3::Db::Connection::Sqlite');
use_ok('Tpda3::Model');
use_ok('Tpda3::Observable');

use_ok('Tpda3::Wx::Controller');
use_ok('Tpda3::Wx::Notebook');
use_ok('Tpda3::Wx::ToolBar');
use_ok('Tpda3::Wx::View');
use_ok('Tpda3::Wx::Screen');
