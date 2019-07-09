#
# Testing Tpda3::Config::Screen
#

use Test2::V0;

use lib qw( lib ../lib );

use Tpda3::Config;
use Tpda3::Config::Screen;

# Use the screen configs from share/
my $args = {
    cfname => 'test-tk',
    user   => 'user',
    pass   => 'pass',
    cfpath => 'share/',
};

#-- Check the one instance functionality

# No instance if instance() not called yet
ok( !Tpda3::Config->has_instance(), 'no Tpda3::Config instance yet' );

my $c1 = Tpda3::Config->instance($args);
ok $c1->isa('Tpda3::Config'), 'created Tpda3::Config instance';

subtest 'Customers screen config' => sub {
    $args->{scrcfg} = 'customers';

    ok my $conf = Tpda3::Config::Screen->new($args), 'new config screen object';

    is ref $conf->{_scr}, 'HASH', 'config loaded';

    # screen section

    is $conf->screen('version'),     5,               'screen version';
    is $conf->screen('name'),        'customers',     'screen name';
    is $conf->screen('description'), 'Customers',     'screen description';
    is $conf->screen('style'),       'default',       'screen style';
    is $conf->screen('geometry'),    '495x515+20+20', 'screen geometry';

    is $conf->defaultreport,   {}, 'defaultreport';
    is $conf->defaultdocument, {}, 'defaultdocument';

    is $conf->defaultdocument('datasource'), {}, 'defaultdocument datasource';
    is $conf->defaultdocument('name'), {}, 'defaultdocument name';
    is $conf->defaultdocument('file'), {}, 'defaultdocument file';

    # list_ds

    is $conf->lists_ds, {}, 'list datasource';

    # list_header

    is ref $conf->list_header, 'HASH', 'list_header';
    is $conf->list_header('lookup'), ['customernumber'],
    'list_header lookup';
    is $conf->list_header('column'), ['customername'],
    'list_header column';

    # bindings

    is ref $conf->bindings, 'HASH', 'bindings';
    is $conf->bindings('country')->{table}, 'v_country',
    'bindings country table hashref';
    is $conf->bindings( 'country', 'table' ), 'v_country',
    'bindings country table';
    is $conf->bindings( 'country', 'search' ), 'countryname',
    'bindings country search';
    is $conf->bindings( 'country', 'field' ), ['countrycode'],
    'bindings country field';

    # tablebindings

    is $conf->tablebindings, {}, 'tablebindings';

    # maintable

    is ref $conf->maintable, 'HASH', 'maintable';
    is $conf->maintable('name'), 'customers',   'maintable name';
    is $conf->maintable('view'), 'v_customers', 'maintable view name';
    is $conf->maintable( 'keys', 'name' ), ['customernumber'],
    'keys name';

    # deptable

    is $conf->deptable, {}, 'deptable hashref';
    is $conf->deptable_name('tm1'),          undef, 'deptable name';
    is $conf->deptable_view('tm1'),          undef, 'deptable view';
    is $conf->deptable_updatestyle('tm1'),   undef, 'deptable updatestyle';
    is $conf->deptable_columns('tm1'),       undef, 'deptable columns';
    is $conf->deptable_selectorcol('tm1'),   undef, 'deptable selectorcol';
    is $conf->deptable_selectorcolor('tm1'), undef, 'deptable selectorcolor';
    is $conf->deptable_selectorstyle('tm1'), undef, 'deptable selectorstyle';
    is $conf->deptable_colstretch('tm1'),    undef, 'deptable colstretch';
    is $conf->deptable_orderby('tm1'),       undef, 'deptable orderby';
};

subtest 'Products screen config' => sub {
    $args->{scrcfg} = 'products';

    ok my $conf = Tpda3::Config::Screen->new($args), 'new config screen object';

    is ref $conf->{_scr}, 'HASH', 'config loaded';

    #dd $conf->{_scr}{list_header};

    # screen section

    is $conf->screen('version'),     5,               'screen version';
    is $conf->screen('name'),        'products',      'screen name';
    is $conf->screen('description'), 'Products',      'screen description';
    is $conf->screen('style'),       'default',       'screen style';
    is $conf->screen('geometry'),    '495x545+20+20', 'screen geometry';

    is $conf->defaultreport,   {}, 'defaultreport';
    is $conf->defaultdocument, {}, 'defaultdocument';

    # list_ds

    is $conf->lists_ds, {}, 'list datasource';

    # list_header

    is ref $conf->list_header, 'HASH', 'list_header';
    is $conf->list_header('lookup'), ['productcode'],
    'list_header lookup';
    is $conf->list_header('column'), [qw(productname productline productvendor)],
    'list_header column';

    # bindings

    is ref $conf->bindings, 'HASH', 'bindings';
    is $conf->bindings('productlines')->{table}, 'productlines',
    'bindings country table hashref';
    is $conf->bindings( 'productlines', 'table' ), 'productlines',
    'bindings country table';
    is $conf->bindings( 'productlines', 'search' ), 'productline',
    'bindings country search';
    is $conf->bindings( 'productlines', 'field' ), ['productlinecode'],
    'bindings country field';

    # tablebindings

    is $conf->tablebindings, {}, 'tablebindings';

    # maintable

    is ref $conf->maintable, 'HASH', 'maintable';
    is $conf->maintable('name'), 'products',   'maintable name';
    is $conf->maintable('view'), 'v_products', 'maintable view name';
    is $conf->maintable( 'keys', 'name' ), ['productcode'],
    'keys name';

    # deptable

    is $conf->deptable, {}, 'deptable hashref';
    is $conf->deptable_name('tm1'),          undef, 'deptable name';
    is $conf->deptable_view('tm1'),          undef, 'deptable view';
    is $conf->deptable_updatestyle('tm1'),   undef, 'deptable updatestyle';
    is $conf->deptable_columns('tm1'),       undef, 'deptable columns';
    is $conf->deptable_selectorcol('tm1'),   undef, 'deptable selectorcol';
    is $conf->deptable_selectorcolor('tm1'), undef, 'deptable selectorcolor';
    is $conf->deptable_selectorstyle('tm1'), undef, 'deptable selectorstyle';
    is $conf->deptable_colstretch('tm1'),    undef, 'deptable colstretch';
    is $conf->deptable_orderby('tm1'),       undef, 'deptable orderby';

    is $conf->deptable_columns('tm1'), undef,    'deptable columns';
    is $conf->deptable_keys('tm1'), undef, 'deptable_keys';
    is $conf->deptable_keys( 'tm1', 'name' ), undef, 'deptable_keys name';

};

subtest 'Orders screen config' => sub {
    $args->{scrcfg} = 'orders';

    ok my $conf = Tpda3::Config::Screen->new($args), 'new config screen object';

    is ref $conf->{_scr}, 'HASH', 'config loaded';

    #dd $conf->{_scr}{list_header};

    # screen section

    is $conf->screen('version'),     5,               'screen version';
    is $conf->screen('name'),        'orders',        'screen name';
    is $conf->screen('description'), 'Orders',        'screen description';
    is $conf->screen('style'),       'default',       'screen style';
    is $conf->screen('geometry'),    '715x490+20+20', 'screen geometry';
    is $conf->has_screen_details, undef, 'has no screen details';

    is $conf->defaultreport,   {}, 'defaultreport';
    is $conf->defaultdocument, {}, 'defaultdocument';

    # lists_ds

    is ref $conf->lists_ds, 'HASH', 'lists datasource';
    is $conf->lists_ds('statuscode', 'table'), 'status', 'lists_ds statuscode table';
    is $conf->lists_ds('statuscode', 'name'), 'description', 'lists_ds statuscode name';
    is $conf->lists_ds('statuscode', 'code'), 'code', 'lists_ds statuscode code';
    is $conf->lists_ds('statuscode', 'orderby'), '', 'lists_ds statuscode orderby';
    is $conf->lists_ds('statuscode', 'default'), 'not set', 'lists_ds statuscode default';

    # list_header

    is ref $conf->list_header, 'HASH', 'list_header';
    is $conf->list_header('lookup'), ['ordernumber'], 'list_header lookup';
    is $conf->list_header('column'), [qw(customername orderdate requireddate shippeddate)],
    'list_header column';

    # bindings

    is ref $conf->bindings, 'HASH', 'bindings';
    is $conf->bindings('customer')->{table}, 'customers',
    'bindings customers table hashref';
    is $conf->bindings( 'customer', 'table' ), 'customers',
    'bindings customer table';
    is $conf->bindings( 'customer', 'search' ), 'customername',
    'bindings customer search';
    is $conf->bindings( 'customer', 'field' ), ['customernumber'],
    'bindings customer field';

    # tablebindings

    is ref $conf->tablebindings, 'HASH', 'tablebindings';
    is $conf->tablebindings( 'tm1', 'lookup', 'products', 'bindcol' ), 1,
    'table bindings lookup products bindcol';
    is $conf->tablebindings( 'tm1', 'lookup', 'products', 'table' ), 'products',
    'table bindings lookup products table';
    is $conf->tablebindings( 'tm1', 'lookup', 'products', 'field' ), ['productcode'],
    'table bindings lookup products field';

    is $conf->tablebindings( 'tm1', 'method', 'article', 'bindcol' ), 4,
    'table bindings method bindcol';
    is $conf->tablebindings( 'tm1', 'method', 'article', 'method' ), 'calculate_order_line',
    'table bindings method method name';

    # maintable

    is ref $conf->maintable, 'HASH', 'maintable';
    is $conf->maintable('name'), 'orders',   'maintable name';
    is $conf->maintable('view'), 'v_orders', 'maintable view name';
    is $conf->maintable( 'keys', 'name' ), ['ordernumber'], 'keys name';

    # deptable

    is ref $conf->deptable, 'HASH', 'deptable hashref';
    is $conf->deptable_name('tm1'), 'orderdetails',   'deptable name';
    is $conf->deptable_view('tm1'), 'v_orderdetails', 'deptable view';
    is $conf->deptable_updatestyle('tm1'), 'delete+add', 'deptable updatestyle';
    is $conf->deptable_selectorcol('tm1'), undef,   'deptable selectorcol';
    is $conf->deptable_selectorcolor('tm1'), undef, 'deptable selectorcolor';
    is $conf->deptable_selectorstyle('tm1'), undef, 'deptable selectorstyle';
    is $conf->deptable_colstretch('tm1'),    2,     'deptable colstretch';
    is $conf->deptable_orderby('tm1'), 'orderlinenumber', 'deptable orderby';

    is ref $conf->deptable_columns('tm1'), 'HASH', 'deptable columns is a hash';
    my $expected_cols = [
        qw(
          orderlinenumber
          ordervalue
          priceeach
          productcode
          productname
          quantityordered
    )];
    my $cols_h = $conf->deptable_columns('tm1');
    my @cols = sort keys %{$cols_h};
    is \@cols, $expected_cols, 'deptable columns';
    
    my $col = $conf->deptable_columns('tm1', 'orderlinenumber');

    is ref $col, 'HASH', 'deptable column orderlinenumber';
    is $col->{id},          0,           'column id';
    is $col->{label},       'Art',       'column label';
    is $col->{tag},         'ro_center', 'column tag';
    is $col->{displ_width}, 5,           'column displ_width';
    is $col->{valid_width}, 5,           'column valid_width';
    is $col->{numscale},    0,           'column numscale';
    is $col->{readwrite},   'rw',        'column readwrite';
    is $col->{datatype},    'integer',   'column datatype';

    is $conf->deptable_columns( 'tm1', 'orderlinenumber', 'id' ), 0,
      'deptable_columns id';

    is ref $conf->deptable_keys('tm1'), 'HASH', 'deptable_keys';
    is $conf->deptable_keys( 'tm1', 'name' ),
      [qw(ordernumber orderlinenumber)], 'deptable_keys';

    is ref $conf->deptable_columns_rw('tm1'), 'HASH', 'deptable rw columns';
    my $expected_rw_cols = [
        qw(
          orderlinenumber
          priceeach
          productcode
          quantityordered
    )];
    my $cols_rw_h = $conf->deptable_columns_rw('tm1');
    my @cols_rw = sort keys %{$cols_rw_h};
    is \@cols_rw, $expected_rw_cols, 'deptable rw columns';
};

# productcode     - rw
# quantityordered - rw
# priceeach       - rw
# ordervalue      - ro
# orderlinenumber - rw
# productname     - ro
    
# {
#   datatype => "integer",
#   displ_width => 5,
#   id => 0,
#   label => "Art",
#   numscale => 0,
#   readwrite => "rw",
#   tag => "ro_center",
#   valid_width => 5,
# }

done_testing;
