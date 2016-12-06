#
# Tpda3::Tk::Validation test script
#
use strict;
use warnings;
use utf8;
use Test::More;

use lib qw( lib ../lib );

use Tpda3::Tk::Validation;
use Tpda3::Tk::ScreenTest q{get_ctrl};

my $args = {
    cfname => 'test-tk',
    user   => 'user',
    pass   => 'pass',
    cfpath => 'share/',
};
ok( my $app = Tpda3->new($args), 'New Tpda3 app' );

ok my $ctrl = get_ctrl($app), 'new controller';

my $scrcfg = undef;

ok my $valid = Tpda3::Tk::Validation->new( $scrcfg, $ctrl->{_view} ),
    'new validation';

subtest 'Test "date" validation' => sub {
    my $var;

    $var = 'te-st-string';
    is $valid->date( $var, 10 ), 0, 'not a date';
    is $ctrl->{_view}->get_status_msg(), 'date:invalid', 'status';

    $var = '2000-09-11';
    is $valid->date( $var, 10 ), 0, 'not a date';
    is $ctrl->{_view}->get_status_msg(), 'date:invalid', 'status';

    $var = '09.11.2000';
    is $valid->date( $var, 10 ), 1, 'is a date';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

    $var = '09-11-2000';
    is $valid->date( $var, 10 ), 0, 'invalid date separator';
    is $ctrl->{_view}->get_status_msg(), 'date:invalid', 'status';
};

subtest 'Test "alpha" validation' => sub {
    my $var;

    $var = 'test-string';
    is $valid->alpha( $var, 10 ), 0, 'invalid';
    is $ctrl->{_view}->get_status_msg(), 'alpha:10', 'status';

    $var = 'teststring';
    is $valid->alpha( $var, 10 ), 1, 'valid';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

    $var = 'testșțrîng';
    is $valid->alpha( $var, 10 ), 1, 'valid UTF-8';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

    $var = 'tes#string';
    is $valid->alpha( $var, 10 ), 0, 'invalid';
    is $ctrl->{_view}->get_status_msg(), 'alpha:10', 'status';

};

subtest 'Test "alphanum" validation' => sub {
    my $var;

    $var = 'test string 12';
    is $valid->alphanum( $var, 10 ), 0, 'invalid';
    is $ctrl->{_view}->get_status_msg(), 'alphanum:10', 'status';

    $var = 'test string 12';
    is $valid->alphanum( $var, 14 ), 1, 'valid';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

    $var = 'testșțrîng+ ';
    is $valid->alphanum( $var, 12 ), 1, 'valid UTF-8';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

    $var = 'tes#string';
    is $valid->alphanum( $var, 10 ), 0, 'invalid';
    is $ctrl->{_view}->get_status_msg(), 'alphanum:10', 'status';

};

subtest 'Test "alphanumplus" validation' => sub {
    my $var;

    $var = 'test @string 12';
    is $valid->alphanumplus( $var, 10 ), 0, 'invalid';
    is $ctrl->{_view}->get_status_msg(), 'alphanum+:10', 'status';

    $var = 'test string 12';
    is $valid->alphanumplus( $var, 14 ), 1, 'valid';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

    $var = 'testșțrîng+ ';
    is $valid->alphanumplus( $var, 12 ), 1, 'valid UTF-8';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

    $var = 'tes#string';
    is $valid->alphanumplus( $var, 10 ), 1, 'valid';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

};

subtest 'Test "anychar" validation' => sub {
    my $var;

    $var = 'test @string 12';
    is $valid->anychar( $var, 10 ), 0, 'invalid, too long';
    is $ctrl->{_view}->get_status_msg(), 'anychar:10', 'status';

    $var = 'test string 12';
    is $valid->anychar( $var, 14 ), 1, 'valid';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

    $var = 'testșțrîng+ ';
    is $valid->anychar( $var, 12 ), 1, 'valid UTF-8';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

    $var = 'tes#string';
    is $valid->anychar( $var, 10 ), 1, 'valid';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

};

subtest 'Test "email" validation' => sub {
    my $var;

    $var = 'test @string 12';
    is $valid->email( $var, 10 ), 0, 'invalid, too long';
    is $ctrl->{_view}->get_status_msg(), 'email:10', 'status';

    $var = 'test string 12';
    is $valid->email( $var, 14 ), 1, 'valid';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

    $var = 'testșțrîng+ ';
    is $valid->email( $var, 12 ), 1, 'valid UTF-8';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

    $var = 'tes#string';
    is $valid->email( $var, 10 ), 1, 'valid';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

};

subtest 'Test "integer" validation' => sub {
    my $var;

    $var = 'test 12';
    is $valid->integer( $var, 10 ), 0, 'invalid';
    is $ctrl->{_view}->get_status_msg(), 'integer:10', 'status';

    $var = 'test string 12';
    is $valid->integer( $var, 14 ), 0, 'invalid';
    is $ctrl->{_view}->get_status_msg(), 'integer:14', 'status';

    $var = '123456';
    is $valid->integer( $var, 7 ), 1, 'valid';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

    $var = '123.34';
    is $valid->integer( $var, 5 ), 0, 'invalid';
    is $ctrl->{_view}->get_status_msg(), 'integer:5', 'status';

};

subtest 'Test "numeric" validation' => sub {
    my $var;

    $var = '21 test 12';
    is $valid->numeric( $var, 10, 0 ), 0, 'invalid';
    is $ctrl->{_view}->get_status_msg(), 'numeric:10', 'status';

    $var = '234.01';
    is $valid->numeric( $var, 6, 2 ), 1, 'valid';
    is $ctrl->{_view}->get_status_msg(), '', 'status';

    $var = '12345';
    is $valid->numeric( $var, 5, 2 ), 0, 'invalid';
    is $ctrl->{_view}->get_status_msg(), 'numeric:5', 'status';

};


done_testing();
