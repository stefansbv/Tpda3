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

    plan tests => 9;
}

use_ok('Tpda3::Tk::App::Test::Orders');

my $args = {
    cfname => 'test-tk',
    user   => undef,
    pass   => undef,
};

my $delay = 1;

ok( my $a = Tpda3->new($args), 'New Tpda3 app' );

#- Test the test screens :)

$a->{gui}{_view}->after( $delay * 1000,
    sub { ok( $a->{gui}->screen_module_load('Orders'), 'Load Screen' ); } );

#-- Test application states

$delay++;

foreach my $state (qw{find idle add idle edit idle}) {
    $a->{gui}{_view}->after(
        $delay * 1000,
        sub {
            ok( $a->{gui}->set_app_mode($state), "Set app mode '$state'" );
        }
    );

    $delay++;
}

#-- Quit

$delay++;

$a->{gui}{_view}->after(
    $delay * 1000,
    sub {
        $a->{gui}{_view}->on_quit;
    }
);

$a->run;

#-- End test
