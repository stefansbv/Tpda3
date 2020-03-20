#
# Test the Antet
#
use 5.010;
use strict;
use warnings;
use Test::More;

BEGIN {
    unless ( $^O eq 'MSWin32' ) {
        plan skip_all => 'This module is only for Windows';
        exit 0;
    }
    eval { require Tpda3::Outlook };
    if ($@) {
        plan( skip_all => 'Mail::Outlook is required for this test' );
    }
}

subtest 'Test with string address' => sub {
    my $send_to = 'name1@example.ro';

    ok my $ol = Tpda3::Outlook->new(
        subject  => 'The subject',
        contents => 'The contents!',
        send_to  => $send_to,
        files    => [],
      ),
      'new outlook instance';

    is $ol->_to, 'name1@example.ro', 'to';
    is $ol->_cc, '', 'cc';

    # isa_ok $a, 'Tpda3::Outlook', 'Tpda3::Outlook';
};

subtest 'Test with hash reference address' => sub {
    my $send_to = {
        to => ['name1@example.ro'],
        cc => ['name2@example.ro'],
    };

    ok my $ol = Tpda3::Outlook->new(
        subject  => 'The subject',
        contents => 'The contents!',
        send_to  => $send_to,
        files    => [],
      ),
      'new outlook instance';

    is $ol->_to, 'name1@example.ro', 'to';
    is $ol->_cc, 'name2@example.ro', 'cc';

    # isa_ok $a, 'Tpda3::Outlook', 'Tpda3::Outlook';
};

subtest 'Test with hash reference address and array for "to"' => sub {
    my $send_to = {
        to => ['name1@example.ro', 'name2@example.ro'],
        cc => ['name3@example.ro'],
    };

    ok my $ol = Tpda3::Outlook->new(
        subject  => 'The subject',
        contents => 'The contents!',
        send_to  => $send_to,
        files    => [],
      ),
      'new outlook instance';

    is $ol->_to, 'name1@example.ro;name2@example.ro', 'to';
    is $ol->_cc, 'name3@example.ro', 'cc';

    # isa_ok $a, 'Tpda3::Outlook', 'Tpda3::Outlook';
};

subtest 'Test with array reference address' => sub {
    my $send_to = [
        'name1@example.ro',
        'name2@example.ro',
    ];

    ok my $ol = Tpda3::Outlook->new(
        subject  => 'The subject',
        contents => 'The contents!',
        send_to  => $send_to,
        files    => [],
      ),
      'new outlook instance';

    is $ol->_to, 'name1@example.ro;name2@example.ro', 'to';
    is $ol->_cc, '', 'cc';

    # isa_ok $a, 'Tpda3::Outlook', 'Tpda3::Outlook';
};

done_testing;
