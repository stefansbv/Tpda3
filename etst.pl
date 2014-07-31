
use 5.010;
use strict;
use warnings;

my $det_params = { key => 1};
if ( defined $det_params and scalar %{$det_params} ) {
    print "are\n";
}
else {

    print " nu are\n";
}
