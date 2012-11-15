# Test helper module from:
# http://search.cpan.org/dist/Wx-Perl-ListCtrl/
# by Mattia Barbon
#
package MyTest;

use strict;
use Wx;
use base qw(Wx::Frame Exporter);
our @EXPORT = qw(test init);

my $frame;

sub test(&) {
    MyApp->new;
    &{$_[0]}( $frame );
    $frame->Destroy;
}

package MyApp;

use strict;
use base 'Wx::App';

sub OnInit {
    ( $frame = MyTest->new( undef, -1, 'test' ) )->Show( 1 );
    1;
}

1;
