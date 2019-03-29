use 5.010001;
use utf8;
use strict;
use warnings;
use Path::Tiny;
use Test::Most;
use Time::Moment;

use Tpda3::Calendar;

my $hollyday_file = path 't', 'sarbatori.yml';

subtest 'Calendar month - 2015, 8' => sub {
    ok my $cal = Tpda3::Calendar->new(
        year          => 2015,
        month         => 8,
        hollyday_file => $hollyday_file,
    ), 'new calendar';
    is $cal->year,            2015, 'year';
    is $cal->month,           8,    'month';
    is $cal->last_day,        31,   'last day in month';
    is $cal->work_days_count, 21,   'zile lucratoare';
    is $cal->first_day_week_day, 6,'first day week day';
    is $cal->last_day_week_day, 1, 'last day week day';

    my @we_days = ( 1, 2, 8, 9, 15, 16, 22, 23, 29, 30 );    # 2015-08
    is_deeply [ $cal->all_weekend_days ], \@we_days, 'elements';
    is $cal->count_weekend_days, 10, 'count';

    my @hd_days = (15);
    is_deeply [ $cal->all_hollyday_days ], \@hd_days, 'elements';
    is $cal->count_hollyday_days, 1, 'holyday days count';

    my $found_h = $cal->find_hollyday( sub { $_ == 15 } );
    is $found_h, 15, '15 is holly-day';

    my $found_w = $cal->find_weekend( sub { $_ == 15 } );
    is $found_w, 15, '15 is weekend';

    ok $cal->is_weekend(1),   'is weekend 1';
    ok $cal->is_holliday(15), 'is holliday 15';
    ok !$cal->is_weekend(13),  'is not weekend 13';
    ok !$cal->is_holliday(13), 'is not holliday 13';

    is $cal->hist_month(0), '2015_08', 'initial month';
    is $cal->hist_month(1), '2015_07', '1 month back';
    is $cal->hist_month(2), '2015_06', '2 months back';
    is $cal->hist_month(3), '2015_05', '3 months back';
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

    my @we_days = ( 6, 7, 13, 14, 20, 21, 27, 28 );    # 2016-02
    is_deeply [ $cal->all_weekend_days ], \@we_days, 'elements';
    is $cal->count_weekend_days, 8, 'count';

    my @hd_days = ();
    is_deeply [ $cal->all_hollyday_days ], \@hd_days, 'elements';
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
