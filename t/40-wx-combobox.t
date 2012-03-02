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
        plan tests => 16;
        $ok_test = 1;
    }
}

use if $ok_test, "Wx", q{:everything};
use if $ok_test, "Wx::Event", q{EVT_TIMER};

use_ok('Tpda3::Wx::ComboBox');

my $choices = [
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

    is( $cb->add_choices($choices), undef, 'Add choices' );

    foreach my $choice (@{$choices}) {
        my $value = $choice->{-value};
        is( $cb->set_selected($value), undef, "Set selected '$value'" );
        is( $cb->get_selected(), $value, "Get selected '$value'");
    }
}

#-- End test
