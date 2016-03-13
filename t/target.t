#
# Borrowed and adapted from Sqitch v0.997 by @theory
#
use strict;
use warnings;
use utf8;
use Test::More;
use Path::Class qw(dir file);
use Test::Exception;
use lib 't/lib';

my $CLASS;
BEGIN {
    $CLASS = 'Tpda3::Target';
    use_ok $CLASS or die;
}

##############################################################################
# Load a target and test the basics.
isa_ok my $target
    = $CLASS->new( uri => 'db:firebird:' ), $CLASS;
can_ok $target, qw(
    new
    uri
    engine
);

# Look at default values.
is $target->uri, URI::db->new('db:firebird:'), 'URI should be "db:firebird:"';
is $target->engine_key, 'firebird', 'Engine key should be "firebird"';
isa_ok $target->engine, 'Tpda3::Engine::firebird', 'Engine';

my $uri = $target->uri;
is $target->dsn, $uri->dbi_dsn, 'DSN should be from URI';
is $target->username, $uri->user, 'Username should be from URI';
is $target->password, $uri->password, 'Password should be from URI';

##############################################################################
# Let's look at how the object is created based on the params to new().
# !!! First try no params, this has a problem:
# - found: AttributeIsRequired (Attribute (uri) is required     for v5.14,16
# - found: AttributeIsRequired (Attribute (tranfer) is required for v5.18
throws_ok { $CLASS->new() }
    qr/\QAttribute (uri) is required/,
    'Should get an exception for missing uri param';

# Pass both tpda3dev and URI.
$uri = URI::db->new('db:pg://hi:there@localhost/blah');
ok $target = $CLASS->new(
    uri      => $uri,
), 'new target instance';

is $target->uri, $uri, 'URI should be set as passed';
is $target->engine_key, 'pg', 'Engine key should be "pg"';
isa_ok $target->engine, 'Tpda3::Engine::pg', 'Engine';
is $target->dsn, $uri->dbi_dsn, 'DSN should be from URI';
is $target->username, $uri->user, 'Username should be from URI';
is $target->password, $uri->password, 'Password should be from URI';

done_testing;
