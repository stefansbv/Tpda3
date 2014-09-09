#
# Testing Tpda3::Config::Menu
#

use strict;
use warnings;

use Test::More tests => 23;

use lib qw( lib ../lib );

use List::Util qw(first);

require Tpda3::Config::Menu;

ok( my $conf = Tpda3::Config::Menu->new, 'new config menu object' );

ok my @menus = $conf->ids_in_menu, 'get the menu names';
ok my @names = $conf->all_menus, 'menu names list';

ok my @attribs = ( qw{id label underline popup} ), 'attribs lists';

foreach my $name (@names) {
    my $menu = first { $_ eq $name } @menus;
    is $menu, $name, qq{we have "$name"};
    ok my $attr = $conf->get_menu($name), qq{get the "$name" menu};
    foreach my $attr_name (@attribs) {
        ok exists $attr->{$attr_name}, qq{atribute "$attr_name" exists};
    }
}

is $conf->get_menu("some_menu"), undef, 'fail to get the "some_menu" menu';
