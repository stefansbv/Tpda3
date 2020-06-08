#
# Tpda3::Utils test script
#
use utf8;
use Test::Most;
use File::HomeDir;
use Path::Tiny;
use Cwd;

use lib qw( lib ../lib );

use Tpda3::Utils;
use Tpda3::Config;

subtest 'Test "get_sqlitedb_filename" with dbname from config' => sub {
    my $args = {
        cfname => 'test-tk',
        user   => 'user',
        pass   => 'pass',
        cfpath => 'share/',
    };
    ok my $inst = Tpda3::Config->instance($args), 'config instance';
    ok my $conf = $inst->connection, 'connection config';

    ok my ( $dbname, $driver ) = @{$conf}{qw(dbname driver)}, 'get configs';
    is $driver, 'sqlite',        'driver config';
    is $dbname, 'classicmodels.db', 'dbname config';

    ok my $data_path = File::HomeDir->my_data, 'my data path';
    ok my $dbfile = Tpda3::Utils->get_sqlitedb_filename($dbname), 'db file';

    is $dbfile, path( $data_path, $dbname ), 'db file path';
};

subtest 'Test "get_sqlitedb_filename" with absolute path' => sub {
    ok my $dbname = path('classicmodels.db')->absolute, 'dbname config';

    ok my $data_path = File::HomeDir->my_data, 'my data path';
    ok my $dbfile = Tpda3::Utils->get_sqlitedb_filename($dbname), 'db file';

    is $dbfile, path( Cwd::cwd(), 'classicmodels.db' ), 'db file path';
};

subtest 'Test "month_names"' => sub {

    # default locale (ro)
    ok my $dt = Tpda3::Utils->dt_today(), 'date time instance';
    foreach my $format (qw{abbrev narrow wide}) {
        ok my $months = Tpda3::Utils->month_names($format),
          "get $format months";
        like $months->[0], qr/^I|ian/, 'first month matches';

        ok my $days = Tpda3::Utils->day_names($format), "get $format days";
        like $days->[0], qr/^L|lun/, 'first day matches';

        my $month = Tpda3::Utils->get_month_name( 12, 'wide' );
        is $month, 'decembrie', 'last month name';

        my $day = Tpda3::Utils->get_day_name( 1, 'wide' );
        is $day, 'luni', 'first day name';
    }

    # en locale
    my $locale = 'en_GB';
    ok $dt = Tpda3::Utils->dt_today($locale), 'date time instance';
    foreach my $format (qw{abbrev narrow wide}) {
        ok my $months = Tpda3::Utils->month_names($format, $locale),
          "get $format months";
        like $months->[0], qr/^J|Jan/, 'first month matches';

        ok my $days = Tpda3::Utils->day_names($format, $locale),
          "get $format days";
        like $days->[0], qr/^M|Mon/, 'first day matches';

        my $month = Tpda3::Utils->get_month_name( 12, 'wide', $locale );
        is $month, 'December', 'last month name';

        my $day = Tpda3::Utils->get_day_name( 1, 'wide', $locale );
        is $day, 'Monday', 'first day name';
    }
};

done_testing;
