#
# Tpda3 Wx GUI test script
#

use strict;
use warnings;

use Test::More;

use lib qw( lib ../lib );

my $ok_test;
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
        plan tests => 23;
        $ok_test = 1;
    }
}

use if $ok_test, "Wx", q{:everything};
use if $ok_test, "Wx::Event", q{EVT_TIMER};

require Tpda3;
require Tpda3::Config;

my $screen_module_package = 'Tpda3::Wx::App::Test::Customers';
my $screen_name = 'Customers';

use_ok($screen_module_package);

my $args = {
    cfname => 'test-wx',
    user   => undef,
    pass   => undef,
};

ok( my $a = Tpda3->new($args), 'New Tpda3 app' );

# Create controller
my $ctrl = $a->{gui};
ok( $ctrl->isa('Tpda3::Controller'),
    'created Tpda3::Controller instance '
);

#- Test the test screens :)

my $timer = Wx::Timer->new( $a->{gui}{_view}, 1 );
$timer->Start( 100, 1 );    # one shot

EVT_TIMER $a->{gui}{_view}, 1, sub {
    ok( $a->{gui}->screen_module_load($screen_name), 'Load Screen' );

    my $obj_rec = $ctrl->scrobj('rec');
    ok( $obj_rec->isa($screen_module_package),
        "created $screen_name instance"
    );
    ok( $ctrl->can('scrcfg'), 'scrcfg loaded' );
    my $cfg_rec = $ctrl->scrcfg('rec');
    ok( $cfg_rec->can('screen'),          'screen' );
    ok( $cfg_rec->can('defaultreport'),   'defaultreport' );
    ok( $cfg_rec->can('defaultdocument'), 'defaultdocument' );
    ok( $cfg_rec->can('lists_ds'),        'lists_ds' );
    ok( $cfg_rec->can('list_header'),     'list_header' );
    ok( $cfg_rec->can('bindings'),        'bindings' );
    ok( $cfg_rec->can('tablebindings'),   'tablebindings' );
    ok( $cfg_rec->can('maintable'),       'maintable' );
    ok( $cfg_rec->can('deptable'),        'deptable' );
    ok( $cfg_rec->can('scrtoolbar'),      'scrtoolbar' );
    ok( $cfg_rec->can('toolbar'),         'toolbar' );
};

#-- Test application states

my $timer2 = Wx::Timer->new( $a->{gui}{_view}, 2 );
$timer2->Start(2000);

# TODO: Add delay between mode changes(?)

EVT_TIMER $a->{gui}{_view}, 2, sub {
    foreach my $state (qw{find idle add idle edit idle}) {
        ok( $a->{gui}->set_app_mode($state), "Set app mode '$state'" );
    }
    $timer2->Stop();
};

#-- Quit

my $timer3 = Wx::Timer->new( $a->{gui}{_view}, 3 );
$timer3->Start(2000);

EVT_TIMER $a->{gui}{_view}, 3, sub {
    $a->{gui}{_view}->on_quit;
};

$a->run;

#-- End test
