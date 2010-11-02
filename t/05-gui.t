#
# Tpda3 GUI test script
#

use strict;
use warnings;

use Test::More tests => 15;

use lib qw( lib ../lib );

use Tpda3;
use Tpda3::Config;

BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }
}

my $args = {
    cfname => 'test',
    user   => 'stefan',
    pass   => 'pass',
};

my $delay = 1;

my $a = Tpda3->new($args);

#- Test some screens

# Products

ok( $a->{gui}{_view}->after(
    $delay * 1000,
    sub { $a->{gui}->screen_load('Products'); } )
);

foreach my $state (qw{on off find off edit off}) {
    ok( $a->{gui}{_view}->after(
        $delay * 1000,
        sub {
            $a->{gui}->screen_controls_state_to($state);
        }
    ) );
    $delay++;
}

$delay++;

# Products2

ok( $a->{gui}{_view}->after(
    $delay * 1000,
    sub { $a->{gui}->screen_load('Products2'); } )
);

foreach my $state (qw{on off find off edit off}) {
    ok( $a->{gui}{_view}->after(
        $delay * 1000,
        sub {
            $a->{gui}->screen_controls_state_to($state);
        }
    ) );
    $delay++;
}

$delay++;

# Quit

ok( $a->{gui}{_view}->after(
    $delay * 1000,
    sub {
        $a->{gui}{_view}->on_quit;
    }
) );

$a->run;
