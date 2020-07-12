#
# Testing Tpda3::Config::Screen
#
use Test2::V0;

use lib qw( lib ../lib );

use Tpda3::Config;
use Tpda3::Config::Screen;
use Tpda3::Config::Screen::Details;
use Data::Dump qw/dump/;

# Use the screen configs from share/
my $args = {
    cfname => 'test-cfg',
    user   => 'user',
    pass   => 'pass',
    cfpath => 't/configs/',
};

#-- Check the one instance functionality

# No instance if instance() not called yet
ok( !Tpda3::Config->has_instance(), 'no Tpda3::Config instance yet' );

my $c1 = Tpda3::Config->instance($args);
ok $c1->isa('Tpda3::Config'), 'created Tpda3::Config instance';

subtest 'screen section without details' => sub {
    $args->{scrcfg} = 'simple';

    ok my $conf = Tpda3::Config::Screen->new($args),
        'new config screen object';

    is ref $conf->{_scr}, 'HASH', 'config loaded';

    is $conf->screen('version'),     5,               'screen version';
    is $conf->screen('style'),       'default',       'screen style';
    is $conf->screen('geometry'),    '715x490+20+20', 'screen geometry';

    my $details = $conf->screen('details');

    # dump $details;

    ok my $scr_det
        = Tpda3::Config::Screen::Details->new( details => $details, ),
        'new details object';

    is $scr_det->default, undef, 'default';
    is $scr_det->has_details_screen, F(), 'has no details screen';
};

subtest 'screen section with details - simple details' => sub {
    $args->{scrcfg} = 'simple-detail';

    ok my $conf = Tpda3::Config::Screen->new($args),
        'new config screen object';

    is ref $conf->{_scr}, 'HASH', 'config loaded';

    is $conf->screen('version'),  5,               'screen version';
    is $conf->screen('style'),    'default',       'screen style';
    is $conf->screen('geometry'), '715x490+20+20', 'screen geometry';
 
    ok my $details = $conf->screen('details'), 'get the details';

    # dump $details;

    ok my $scr_det
        = Tpda3::Config::Screen::Details->new( details => $details, ),
        'new details object';

    is $scr_det->default, 'Activity', 'default screen name';
    is $scr_det->has_details_screen, T(), 'has details screen';
};

subtest 'screen section with details - details' => sub {
    $args->{scrcfg} = 'details';

    ok my $conf = Tpda3::Config::Screen->new($args),
        'new config screen object';

    is ref $conf->{_scr}, 'HASH', 'config loaded';

    is $conf->screen('version'), 5,         'screen version';
    is $conf->screen('style'),   'default', 'screen style';

    ok my $details = $conf->screen('details'), 'get the details';
    #dump $details;

    ok my $scr_det
        = Tpda3::Config::Screen::Details->new( details => $details, ),
        'new details object';

    is $scr_det->filter,  'id_art',  'filter';
    is $scr_det->match,   'id_prsrv', 'match';
    is $scr_det->default, 'Details', 'default screen name';

    is $scr_det->has_details_screen, T(), 'has details screen';
    is $scr_det->get_detail(42), 'Other', 'get detail for 42';
};

subtest 'screen section with details - complex (no default)' => sub {
    $args->{scrcfg} = 'complex';

    ok my $conf = Tpda3::Config::Screen->new($args),
        'new config screen object';

    is ref $conf->{_scr}, 'HASH', 'config loaded';

    is $conf->screen('version'), 5,          'screen version';
    is $conf->screen('name'),    'persoane', 'screen name';
    is $conf->screen('description'), 'Persoane si activitati',
        'screen description';
    is $conf->screen('style'),    'default',       'screen style';
    is $conf->screen('geometry'), '715x490+20+20', 'screen geometry';

    ok my $details = $conf->screen('details'), 'get the details';
    #dump $details;

    ok my $scr_det
        = Tpda3::Config::Screen::Details->new( details => $details, ),
        'new details object';

    is $scr_det->filter,  'id_act',  'filter';
    is $scr_det->match,   'cod_tip', 'match';
    is $scr_det->default, undef,     'default';

    is $scr_det->has_details_screen, T(), 'has details screen';
    is $scr_det->get_detail('CS'), 'Cursuri', 'get detail for CS';
    is $scr_det->get_detail('CT'), 'Consult', 'get detail for CT';
};

done_testing;
