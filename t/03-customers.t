#
# Tpda3 GUI test script
#

use strict;
use warnings;

use Test::More tests => 9;

use lib qw( lib ../lib );

use Tpda3;
use Tpda3::Config;

BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }
}

use_ok('Tpda3::App::Test::Customers');

my $args = {
    cfname => 'test',
    user   => 'stefan',
    pass   => 'pass',
};

my $delay = 1;

my $a = Tpda3->new($args);

#- Test the test screens :)

ok( $a->{gui}{_view}->after(
    $delay * 1000,
    sub { $a->{gui}->screen_module_load('Customers'); } )
);

#-- Test application states

$delay++;

foreach my $state (qw{find idle add idle edit idle}) {
    ok(
        $a->{gui}{_view}->after(
            $delay * 1000,
            sub {
                $a->{gui}->set_app_mode($state);
            }
        )
    );
        $delay++;
}

#-- Quit

$delay++;

ok( $a->{gui}{_view}->after(
    $delay * 1000,
    sub {
        $a->{gui}{_view}->on_quit;
    }
) );

$a->run;

#-- End test
