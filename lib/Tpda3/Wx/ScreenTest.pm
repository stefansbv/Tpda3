package Tpda3::Wx::ScreenTest;

# ABSTRACT: module for screen tests

use strict;
use warnings;

use Test::More;
#use Test::FailWarnings;

use Tpda3;
use Tpda3::Config;

use Exporter 'import';
our @EXPORT_OK = qw(test_screen);

BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }

    eval {
        require Wx;
    };
    if ($@) {
        plan( skip_all => 'wxPerl is required for this test' );
    }

    plan tests => 23;
}

sub test_screen {
    my ( $args, $screen_module_package ) = @_;

    use Wx::Event q(EVT_TIMER);

    my $screen_name = ( split /::/, $screen_module_package )[-1];

    #diag "screen_name is $screen_name";

    use_ok($screen_module_package);

    ok( my $app = Tpda3->new($args), 'New Tpda3 app' );

    # Create controller
    my $ctrl = $app->{gui};
    ok( $ctrl->isa('Tpda3::Controller'),
        'created Tpda3::Controller instance '
    );

    #- Test the test screens :)

    my $timer = Wx::Timer->new( $app->{gui}{_view}, 1 );
    $timer->Start( 100, 1 );    # one shot

    EVT_TIMER $app->{gui}{_view}, 1, sub {
        ok( $app->{gui}->screen_module_load($screen_name), 'Load Screen' );

        my $obj_rec = $ctrl->scrobj('rec');
        ok( $obj_rec->isa($screen_module_package),
            "created $screen_name instance"
        );
        ok( $ctrl->can('scrcfg'), 'scrcfg loaded' );
        my $cfg_rec = $ctrl->scrcfg('rec');
        ok( $cfg_rec->can('screen'),          'screen' );
        ok( $cfg_rec->can('defaultreport'),   'defaultreport' );
        ok( $cfg_rec->can('defaultdocument'), 'defaultdocument' );
        ok( $cfg_rec->can('lists_ds'),        'lists_ds' );
        ok( $cfg_rec->can('list_header'),     'list_header' );
        ok( $cfg_rec->can('bindings'),        'bindings' );
        ok( $cfg_rec->can('tablebindings'),   'tablebindings' );
        ok( $cfg_rec->can('maintable'),       'maintable' );
        ok( $cfg_rec->can('deptable'),        'deptable' );
        ok( $cfg_rec->can('scrtoolbar'),      'scrtoolbar' );
        ok( $cfg_rec->can('toolbar'),         'toolbar' );
    };

    #-- Test application states

    my $timer2 = Wx::Timer->new( $app->{gui}{_view}, 2 );
    $timer2->Start(1000);

    # TODO: Add delay between mode changes(?)

    EVT_TIMER $app->{gui}{_view}, 2, sub {
        foreach my $state (qw{find idle add idle edit idle}) {
            ok( $app->{gui}->set_app_mode($state), "Set app mode '$state'" );
        }
        $timer2->Stop();
    };

    #-- Quit

    my $timer3 = Wx::Timer->new( $app->{gui}{_view}, 3 );
    $timer3->Start(1000);

    EVT_TIMER $app->{gui}{_view}, 3, sub {
        $app->{gui}->on_quit;
    };

    $app->run;

}

1;

=head1 SYNOPSIS

use Tpda3::Wx::ScreenTest q{test_screen};

my $args = {
    cfname => 'test-wx',
    user   => undef,
    pass   => undef,
};

test_screen($args, 'Tpda3::Wx::App::<AppName>::<ScreenName>');

=head2 new

Constructor method.

=head2 test_screen

Test method. Not exported by default.

=cut
