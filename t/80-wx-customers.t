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
        plan tests => 9;
        $ok_test = 1;
    }
}

use if $ok_test, "Wx", q{:everything};
use if $ok_test, "Wx::Event", q{EVT_TIMER};

require Tpda3;
require Tpda3::Config;

use_ok('Tpda3::Wx::App::Test::Customers');

my $args = {
    cfname => 'test-wx',
    user   => undef,
    pass   => undef,
};

ok( my $a = Tpda3->new($args), 'New Tpda3 app' );

#- Test the test screens :)

my $timer = Wx::Timer->new( $a->{gui}{_view}, 1 );
$timer->Start( 1000, 1 );    # one shot

EVT_TIMER $a->{gui}{_view}, 1, sub {
    ok( $a->{gui}->screen_module_load('Customers'), 'Load Screen' );
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
