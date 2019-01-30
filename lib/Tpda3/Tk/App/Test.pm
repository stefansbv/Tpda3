package Tpda3::Tk::App::Test;

# ABSTRACT: The main module of the Tpda3 test and demo application

use strict;
use warnings;

sub application_name {
    my $name = "Test and demo application for Tpda3\n";
    $name .= "Author: Stefan Suciu\n";
    $name .= "Copyright 2010-2019\n";
    $name .= "GNU General Public License (GPL)\n";
    $name .= 'stefan@s2i2.ro';
    return $name;
}

1;
