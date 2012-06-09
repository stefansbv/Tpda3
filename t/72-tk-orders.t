#
# Tpda3 Tk GUI test script
#

use strict;
use warnings;

use Test::More;

use lib qw( lib ../lib );

use Tpda3;
use Tpda3::Config;

BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }

    eval { use Tk; };
    if ($@) {
        plan( skip_all => 'Perl Tk is required for this test' );
    }

    plan tests => 23;
}

use_ok('Tpda3::Tk::App::Test::Orders');

my $args = {
    cfname => 'test-tk',
    user   => undef,
    pass   => undef,
};

my $delay = 1;

ok( my $app = Tpda3->new($args), 'New Tpda3 app' );

# Create controller
my $ctrl = $app->{gui};
ok( $ctrl->isa('Tpda3::Controller'), 'created Tpda3::Controller instance ' );

#- Test the test screens :)

$ctrl->{_view}->after( $delay * 100,
    sub { ok( $ctrl->screen_module_load('Orders'), 'Load Screen' ); } );
#-- Test screen configs

$ctrl->{_view}->after(
    $delay * 100,
    sub {
        my $obj_rec = $ctrl->scrobj('rec');
        ok( $obj_rec->isa('Tpda3::Tk::App::Test::Orders'),
            'created Orders instance ' );
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
    }
);

#-- Test application states

$delay++;

foreach my $state (qw{find idle add idle edit idle}) {
    $ctrl->{_view}->after(
        $delay * 100,
        sub {
            ok( $ctrl->set_app_mode($state), "Set app mode '$state'" );
        }
    );

    $delay++;
}

#-- Quit

$delay++;

$ctrl->{_view}->after(
    $delay * 100,
    sub {
        $ctrl->{_view}->on_quit;
    }
);

$app->run;

#-- End test
