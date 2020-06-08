use strict;
use warnings;

use Test2::V0;

use lib qw( lib ../lib );

use Tpda3::Model;

use Data::Dump;

ok my $m = Tpda3::Model->new(), 'new model object';

isa_ok $m->cfg,       ['Tpda3::Config'],             'config';
isa_ok $m->info_db,   ['Tpda3::Config::Connection'], 'connection config';
isa_ok $m->target,    ['Tpda3::Target'],             'db target';
isa_ok $m->connector, ['DBIx::Connector'],           'db connector';
isa_ok $m->db,        ['Tpda3::Model::DB'],          'db model';

done_testing;
