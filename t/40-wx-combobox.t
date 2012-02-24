#
# Tpda3 Wx GUI test script
#

use strict;
use warnings;

use lib qw(t/lib);

use Test::More;
use MyTest;

my $ok_test;
BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }

    eval { require Wx; };
    if ($@) {
        plan( skip_all => 'wxPerl is required for this test' );
    }
    else {
        plan tests => 4;
        $ok_test = 1;
    }
}

use if $ok_test, "Wx", q{:everything};
use if $ok_test, "Wx::Event", q{EVT_TIMER};

use_ok('Tpda3::Wx::ComboBox');

my $choices = [
    {   '-name'  => '',
        '-value' => ''
    },
    {   '-name'  => 'Cancelled',
        '-value' => 'C'
    },
    {   '-name'  => 'Disputed',
        '-value' => 'D'
    },
    {   '-name'  => 'In Process',
        '-value' => 'P'
    },
    {   '-name'  => 'On Hold',
        '-value' => 'H'
    },
    {   '-name'  => 'Resolved',
        '-value' => 'R'
    },
    {   '-name'  => 'Shipped',
        '-value' => 'S'
    }
];

test {
    my $frame = shift;
    my $cb = Tpda3::Wx::ComboBox->new(
        $frame,
        -1,
        q{},
        [-1, -1], [-1, -1],
        [],
        wxCB_SORT | wxTE_PROCESS_ENTER,
    );

    my $timer1 = Wx::Timer->new( $frame, 1 );
    $timer1->Start( 1000, 1 );    # one shot

    EVT_TIMER $frame, 1, sub {
        is( $cb->add_choices($choices), undef, 'Add choices' );
    };

    my $timer2 = Wx::Timer->new( $frame, 2 );
    $timer2->Start(2000);

    EVT_TIMER $frame, 2, sub {
        foreach my $choice (@{$choices->{-value}}) {
            diag $choice;
            is( $cb->set_selected($choice), undef, "Set selected '$choice'" );
            is( $cb->get_selected(), $choice, "Get selected '$choice'");
        }
        $timer2->Stop();
    };
}

#-- End test
