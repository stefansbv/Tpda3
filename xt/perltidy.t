#
# Perl Tidy
#

use strict;
use warnings;

use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan skip_all => "Author tests not required for installation";
}

eval { require Test::PerlTidy };
if ($@) {
    plan( skip_all => 'Test::PerlTidy is required for this test' );
}
else {
    plan tests => 1;
}

run_tests(
    perltidyrc => './.perltidyrc',
    exclude    => [ qr{\.t$}, 'inc/', 'blib/' ],
);
