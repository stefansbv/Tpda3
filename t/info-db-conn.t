use 5.010001;
use utf8;
use strict;
use warnings;
use Path::Tiny;
use Test::More;
use Test::Exception;

use Tpda3::Config;
use Tpda3::Connection;

subtest 'Connection config from test-tk' => sub {
    my $args = {
        cfname => 'test-tk',
        user   => 'user',
        pass   => 'pass',
        cfpath => 'share/',
    };
    my $c1 = Tpda3::Config->instance($args);
    ok( $c1->isa('Tpda3::Config'), 'created Tpda3::Config instance 1' );

    ok my $db = Tpda3::Connection->new, 'new instance';
    like $db->uri_db, qr/^db:sqlite/,  'the uri built from a connection file';
    is $db->driver,   'sqlite',        'the engine';
    is $db->host,     'localhost',     'the host';
    is $db->port,     undef,           'the port';
    is $db->dbname,   'classicmodels', 'the dbname';
    is $db->user,     undef,           'the user name';
    is $db->role,     undef,           'the role name';
    like $db->uri, qr/classicmodels$/, 'the uri';
};

subtest 'Connection config from test-wx' => sub {
    my $args = {
        cfname => 'test-wx',
        user   => 'user',
        pass   => 'pass',
        cfpath => 'share/',
    };
    my $c1 = Tpda3::Config->instance($args);
    ok( $c1->isa('Tpda3::Config'), 'created Tpda3::Config instance 1' );

    ok my $db = Tpda3::Connection->new, 'new instance';
    like $db->uri_db, qr/^db:sqlite/,  'the uri built from a connection file';
    is $db->driver,   'sqlite',        'the engine';
    is $db->host,     'localhost',     'the host';
    is $db->port,     undef,           'the port';
    is $db->dbname,   'classicmodels', 'the dbname';
    is $db->user,     undef,           'the user name';
    is $db->role,     undef,           'the role name';
    like $db->uri, qr/classicmodels$/, 'the uri';
};

done_testing;
