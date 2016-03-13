#
# Borrowed and adapted from Sqitch v0.997 by @theory
#
use strict;
use warnings;
use 5.010;
use utf8;
use Test::More;
use Path::Class;
use Test::Exception;
use Locale::TextDomain qw(Tpda3);
use Tpda3;
use Tpda3::Target;
use Tpda3::X qw(hurl);
use lib 't/lib';

my $CLASS;

BEGIN {
    $CLASS = 'Tpda3::Engine';
    use_ok $CLASS or die;
    # $ENV{TRANSFER_CONFIG} = 'nonexistent.conf';
}

can_ok $CLASS, qw(load new name uri);
my $die = '';
ENGINE: {
    # Stub out a engine.
    package Tpda3::Engine::whu;
    use Moose;
    use Tpda3::X qw(hurl);
    extends 'Tpda3::Engine';
    $INC{'App/Tpda3Dev/Engine/whu.pm'} = __FILE__;

    my @SEEN;
    for my $meth (qw(
        get_info
    )) {
        no strict 'refs';
        *$meth = sub {
            hurl 'AAAH!' if $die eq $meth;
            push @SEEN => [ $meth => $_[1] ];
        };
    }

    sub seen { [@SEEN] }
    after seen => sub { @SEEN = () };
}

##############################################################################
# Test new().
ok my $target = Tpda3::Target->new(
    uri      => 'db:firebird:',
), 'new target instance';

throws_ok { $CLASS->new }
    qr/\QAttribute (target) is required/,
    'Should get an exception for missing target param';
lives_ok { $CLASS->new( target => $target ) }
    'Should get no exception';

isa_ok $CLASS->new( { target => $target } ), $CLASS,
    'Engine';

##############################################################################
# Test load().
ok $target = Tpda3::Target->new(
    uri      => 'db:whu:',
), 'new whu target';
ok my $engine = $CLASS->load({
    target   => $target,
}), 'Load a "whu" engine';
isa_ok $engine, 'Tpda3::Engine::whu';

# Try an unknown engine.
$target = Tpda3::Target->new(
    uri      => 'db:nonexistent:',
);
throws_ok { $CLASS->load( { target => $target } ) }
    'Tpda3::X', 'Should get error for unsupported engine';
is $@->message, 'Unable to load Tpda3::Engine::nonexistent',
    'Should get load error message';
like $@->previous_exception, qr/\QCan't locate/,
    'Should have relevant previoius exception';

# Test handling of an invalid engine.
throws_ok { $CLASS->load({ engine => 'nonexistent', target => $target }) }
    'Tpda3::X', 'Should die on invalid engine';
is $@->message, __('Unable to load Tpda3::Engine::nonexistent'),
    'Should get load error message';
like $@->previous_exception, qr/\QCan't locate/,
    'Should have relevant previoius exception';

NOENGINE: {
    # Test handling of no target.
    throws_ok { $CLASS->load({}) } 'Tpda3::X',
            'No target should die';
    is $@->message, 'Missing "target" parameter to load()',
        'It should be the expected message';
}

done_testing;
