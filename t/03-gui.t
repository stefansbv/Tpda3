#
# Tpda3 GUI test script
#

use strict;
use warnings;

use Test::More tests => 3;

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
    cfgname => 'test',
    user    => 'stefan',
    pass    => 'pass',
};

my $a = Tpda3->new($args);

ok($a->{gui}{_view}->after(1000, sub {
                               $a->{gui}->screen_load('Products'); } ));
ok($a->{gui}{_view}->after(2000, sub {
                               $a->{gui}->screen_load('Products2'); } ));
ok($a->{gui}{_view}->after(3000, sub {
                               $a->{gui}{_view}->on_quit; } ));

$a->run;
