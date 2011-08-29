#
# Perl Tidy
#

use strict;
use warnings;

use Test::PerlTidy;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

run_tests(
    perltidyrc => './.perltidyrc',
    exclude    => [ qr{\.t$}, 'inc/', 'blib/' ],
);
