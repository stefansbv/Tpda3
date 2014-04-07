#!/bin/env perl

use strict;
use warnings;

while (<DATA>) {
    s /[\n|\r]//g;

    print "Testing with $_, \tresult is ";

    if ( /bg|background/ ) {
        print "match\n";
    }
    else {
        print "no match\n";
    }
}

__DATA__
bg
bground
background
cground
dk
