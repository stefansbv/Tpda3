#
# Tpda3 use test script
#

use Test::More;
use lib 'lib';

BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }
    eval { require Tk; };
    if ($@) {
        plan( skip_all => 'Perl Tk is required for this test' );
    }
    else {
        plan tests => 53;
    }
}

diag("Testing with Perl $], $^X");

use_ok('Tpda3::Controller');
use_ok('Tpda3::Generator');
use_ok('Tpda3::Lookup');
use_ok('Tpda3::Role::Utils');
use_ok('Tpda3::Role::DBIMessages');
use_ok('Tpda3::Role::DBIEngine');
use_ok('Tpda3::Tree');
use_ok('Tpda3::Observable');
use_ok('Tpda3::Model::Table::Record');
use_ok('Tpda3::Model::Table');
use_ok('Tpda3::Tk::Screen');
use_ok('Tpda3::Tk::Controller');
use_ok('Tpda3::Tk::Entry');
use_ok('Tpda3::Tk::Tools::Reports');
use_ok('Tpda3::Tk::Tools::TemplDet');
use_ok('Tpda3::Tk::Tools::Templates');
use_ok('Tpda3::Tk::Validation');
use_ok('Tpda3::Tk::TB');
use_ok('Tpda3::Tk::View');
use_ok('Tpda3::Tk::Text');
use_ok('Tpda3::Tk::App::Test::Orders');
use_ok('Tpda3::Tk::App::Test::Products');
use_ok('Tpda3::Tk::App::Test::Customers');
use_ok('Tpda3::Tk::App::Test');
use_ok('Tpda3::Tk::TMSHR');
use_ok('Tpda3::Tk::TM');
use_ok('Tpda3::Tk::Dialog::Tiler');
use_ok('Tpda3::Tk::Dialog::SSelect');
use_ok('Tpda3::Tk::Dialog::Message');
use_ok('Tpda3::Tk::Dialog::AppList');
use_ok('Tpda3::Tk::Dialog::Select');
use_ok('Tpda3::Tk::Dialog::Login');
use_ok('Tpda3::Tk::Dialog::Repman');
use_ok('Tpda3::Tk::Dialog::Configs');
use_ok('Tpda3::Tk::Dialog::TTGen');
use_ok('Tpda3::Tk::Dialog::Search');
use_ok('Tpda3::Exceptions');
use_ok('Tpda3::Engine');
use_ok('Tpda3::Selected');
use_ok('Tpda3::Config');
use_ok('Tpda3::Model');
use_ok('Tpda3::Config::Toolbar');
use_ok('Tpda3::Config::Screen');
use_ok('Tpda3::Config::Connection');
use_ok('Tpda3::Config::Utils');
use_ok('Tpda3::Config::Menu');
use_ok('Tpda3::Engine::firebird');
use_ok('Tpda3::Engine::pg');
use_ok('Tpda3::Engine::sqlite');
use_ok('Tpda3::Utils');
use_ok('Tpda3::Codings');
use_ok('Tpda3::Target');
use_ok('Tpda3');

done_testing;
