#!/bin/env perl

use 5.010;
use Test2::V0;

BEGIN {
    unless ( $^O eq 'MSWin32' ) {
        plan skip_all => 'This module is only for Windows';
        exit 0;
    }
    eval { require Tpda3::Drives };
    if ($@) {
        print " $@\n";
        plan( skip_all => 'Win32::DriveInfo is required for this test' );
    }
}

ok my $d = Tpda3::Drives->new, 'New drives object';

is $d->get_type(2), 'Removable', 'get type';
is $d->num_types, 7, 'number of types';

is $d->get_drive('C'), 'HDD', 'get type of drive C';
like $d->num_drives, qr/\d+/, 'number of drives';

like $d->has_removables, qr/\d+/, 'has removables or not';

ok my $rem = $d->get_removables, 'get removables';

like $d->has_removable('F'), qr/\d+/, 'has removable F or not';

like(
    dies { $d->has_removable('AA') },
    qr/\Qrequires a drive letter/,
    'Should have error for wrong drive letter argument'
);

done_testing;
