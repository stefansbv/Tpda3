#
# Tpda3::Utils test script
#
use strict;
use warnings;
use utf8;
use Test::More;
use File::HomeDir;
use Path::Tiny;
use Cwd;

use lib qw( lib ../lib );

require Tpda3::Utils;
require Tpda3::Config;

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
    is $dbname, 'classicmodels', 'dbname config';

    ok my $data_path = File::HomeDir->my_data, 'my data path';
    ok my $dbfile = Tpda3::Utils->get_sqlitedb_filename($dbname), 'db file';

    is $dbfile, path( $data_path, "$dbname.db" ), 'db file path';
};

subtest 'Test "get_sqlitedb_filename" with absolute path' => sub {
    ok my $dbname = path('classicmodels.db')->absolute, 'dbname config';

    ok my $data_path = File::HomeDir->my_data, 'my data path';
    ok my $dbfile = Tpda3::Utils->get_sqlitedb_filename($dbname), 'db file';

    is $dbfile, path( Cwd::cwd(), 'classicmodels.db' ), 'db file path';
};

done_testing;
