use 5.010001;
use utf8;
use strict;
use warnings;
use Path::Tiny;
use Test::Most;
use Time::Moment;

use Tpda3::Calendar;

my $hollyday_file = path 't', 'sarbatori.yml';

subtest 'Calendar month - 2019, 1' => sub {
    ok my $cal = Tpda3::Calendar->new(
        year          => 2019,
        month         => 1,
        hollyday_file => $hollyday_file,
    ), 'new calendar';
    is $cal->year,            2019, 'year';
    is $cal->month,           1,    'month';
    is $cal->last_day,        31,   'last day in month';
    is $cal->work_days_count, 20,   'zile lucratoare';
    is $cal->first_day_week_day, 2,'first day week day';
    is $cal->last_day_week_day, 4, 'last day week day';

    my @we_days_exp = ( 5, 6, 12, 13, 19, 20, 26, 27 );    # 2019-01
    my @we_days = sort { $a <=> $b } $cal->all_weekend_days;
    cmp_deeply \@we_days, \@we_days_exp, 'elements';
    is $cal->count_weekend_days, 8, 'count';

    my @hd_days_exp = (1, 2, 24);
    my @hd_days = sort { $a <=> $b } $cal->all_hollyday_days;
    cmp_deeply \@hd_days, \@hd_days_exp, 'elements';
    is $cal->count_hollyday_days, 3, 'holyday days count';

    my $found_h = $cal->find_hollyday( sub { $_ == 24 } );
    is $found_h, 24, '24 is holly-day';

    my $found_w = $cal->find_weekend( sub { $_ == 27 } );
    is $found_w, 27, '27 is weekend';

    ok $cal->is_weekend(5),   'is weekend 5';

    ok $cal->is_weekend_sat(5), 'is weekend 5 Sat';
    ok !$cal->is_weekend_sun(5), 'is weekend 5 Sun';
    ok !$cal->is_weekend_sat(6), 'is weekend 6 Sat';
    ok $cal->is_weekend_sun(6), 'is weekend 6 Sun';

    ok $cal->is_holliday(24), 'is holliday 24';
    ok !$cal->is_weekend(1),  'is not weekend 1';
    ok !$cal->is_holliday(13), 'is not holliday 13';

    is $cal->hist_month(0), '2019_01', 'initial month';
    is $cal->hist_month(1), '2018_12', '1 month back';
    is $cal->hist_month(2), '2018_11', '2 months back';
    is $cal->hist_month(3), '2018_10', '3 months back';
};

subtest 'Calendar month - 2016, 2' => sub {
    ok my $cal = Tpda3::Calendar->new(
        year          => 2016,
        month         => 2,
        hollyday_file => $hollyday_file,
    ), 'new calendar';
    is $cal->year,            2016, 'year';
    is $cal->month,           2,    'month';
    is $cal->last_day,        29,   'last day in month';
    is $cal->work_days_count, 21,   'zile lucratoare';

    my @we_days_exp = ( 6, 7, 13, 14, 20, 21, 27, 28 );    # 2016-02
    my @we_days = sort { $a <=> $b } $cal->all_weekend_days;
    cmp_deeply \@we_days, \@we_days, 'elements';
    is $cal->count_weekend_days, 8, 'count';

    my @hd_days = ();
    cmp_deeply [ $cal->all_hollyday_days ], \@hd_days, 'elements';
    is $cal->count_hollyday_days, 0, 'holyday days count';

    my $found_w = $cal->find_weekend( sub { $_ == 14 } );
    is $found_w, 14, '14 is weekend';

    ok $cal->is_weekend(27),   'is weekend 27';
    ok !$cal->is_weekend(15),  'is not weekend 15';
    ok !$cal->is_holliday(13), 'is not holliday 13';

    is $cal->hist_month(0), '2016_02', 'initial month';
    is $cal->hist_month(1), '2016_01', '1 month back';
    is $cal->hist_month(2), '2015_12', '2 months back';
    is $cal->hist_month(3), '2015_11', '3 months back';
    is $cal->hist_month(4), '2015_10', '4 months back';
    is $cal->hist_month(5), '2015_09', '5 months back';
    is $cal->hist_month(6), '2015_08', '6 months back';
};

subtest 'Calendar month - current year, last month' => sub {
    ok my $cal = Tpda3::Calendar->new(
        hollyday_file => $hollyday_file,
    ), 'new calendar';
    my ($year, $month) = current_year_month();
    is $cal->year, $year, "this year: $year";
    is $cal->month, $month, "last month $month";
};

sub current_year_month {
    my $tm     = Time::Moment->now;
    my $tm_new = $tm->minus_months(1);
    return ($tm_new->year, $tm_new->month);
}

done_testing;
