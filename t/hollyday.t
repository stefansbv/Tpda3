use 5.010001;
use utf8;
use strict;
use warnings;
use Path::Tiny;
use Test::Most;

use Tpda3::Hollyday;

my $hollyday_file = path 't', 'sarbatori.yml';

subtest 'Hollyday ian ' => sub {
    ok my $s1 = Tpda3::Hollyday->new(
        year          => 2015,
        month         => 1,
        hollyday_file => $hollyday_file,
    ), 'new calendar';
    is $s1->year, 2015, 'year';
    is $s1->month, 1, 'month';
    is $s1->get_hollyday(1), 'Anul Nou', 'sarbatoare';
    is $s1->get_hollyday(3), undef, 'zi lucratore';
    is $s1->has_no_hollyday, 0, 'has no hollyday';
    is $s1->num_hollyday, 3, 'hollyday count';
};

subtest 'Hollyday feb - none' => sub {
    ok my $s1 = Tpda3::Hollyday->new(
        year          => 2015,
        month         => 2,
        hollyday_file => $hollyday_file,
    ), 'new calendar';
    is $s1->year, 2015, 'year';
    is $s1->month, 2, 'month';
    is $s1->has_no_hollyday, 1, 'has no hollyday';
    is $s1->num_hollyday, 0, 'hollyday count';
};

done_testing;
