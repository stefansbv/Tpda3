package Tpda3::Tk::ScreenTest;

use strict;
use warnings;

use Test::More;
#use Test::FailWarnings;

use Tpda3;
use Tpda3::Config;

use Exporter 'import';
our @EXPORT_OK = qw(test_screen);

=head1 NAME

Tpda3::Tk::ScreenTest - module for screen test.

=head1 VERSION

Version 0.83

=cut

our $VERSION = 0.83;

=head1 SYNOPSIS

use Tpda3::Tk::ScreenTest q{test_screen};

my $args = {
    cfname => 'test-tk',
    user   => undef,
    pass   => undef,
};

test_screen($args, 'Tpda3::Tk::App::<AppName>::<ScreenName>');

=head1 METHODS

=head2 new

Constructor method.

=cut

BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }

    eval { require Tk; };
    if ($@) {
        plan( skip_all => 'Perl Tk is required for this test' );
    }

    plan tests => 23;
}

=head2 test_screen

Test method. Not exported by default.

=cut

sub test_screen {
    my ($args, $screen_module_package) = @_;

    my $screen_name = ( split /::/, $screen_module_package )[-1];
    #diag "screen_name is $screen_name";

    use_ok($screen_module_package);

    ok( my $app = Tpda3->new($args), 'New Tpda3 app' );

    # Create controller
    my $ctrl = $app->{gui};
    ok( $ctrl->isa('Tpda3::Controller'),
        'created Tpda3::Controller instance '
    );

    my $delay = 1;

    #- Test the test screens :)

    $ctrl->{_view}->after(
        $delay * 100,
        sub { ok( $ctrl->screen_module_load($screen_name), 'Load Screen' ); }
    );

    #-- Test screen configs

    $ctrl->{_view}->after(
        $delay * 100,
        sub {
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
        }
    );

    #-- Test application states

    $delay++;

    foreach my $state (qw{find idle add idle edit idle}) {
        $ctrl->{_view}->after(
            $delay * 100,
            sub {
                ok( $ctrl->set_app_mode($state), "Set app mode '$state'" );
            }
        );

        $delay++;
    }

    #-- Quit

    $delay++;

    $ctrl->{_view}->after(
        $delay * 200,
        sub {
            $ctrl->on_quit;
        }
    );

    $app->run;

}

1;  #-- End test
