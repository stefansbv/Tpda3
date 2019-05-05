#
# Testing Tpda3::Config::Toolbar
#

use Test2::V0;

use lib qw( lib ../lib );

use List::Util qw(first);

require Tpda3::Config::Toolbar;

ok my $conf = Tpda3::Config::Toolbar->new, 'new config tool object';

ok my @tools = $conf->ids_in_tool, 'get the tool names';

ok my @names = (qw{tb_ad tb_at tb_fc tb_fe tb_fm tb_gr tb_pr tb_qt tb_rm tb_rr tb_sv tb_tn tb_tr}), 'tool name list';

ok my @attribs = ( qw{tooltip help icon sep type id state} ), 'attribs lists';

foreach my $name (@names) {
    my $tool = first { $_ eq $name } @tools;
    is $tool, $name, qq{we have "$name"};
    ok my $attr = $conf->get_tool($name), qq{get the "$name" tool};
    foreach my $attr_name (@attribs) {
        ok exists $attr->{$attr_name}, qq{atribute "$attr_name" exists};
    }
}

is $conf->get_tool("some_tool"), undef, 'fail to get the "some_tool" tool';

done_testing;
