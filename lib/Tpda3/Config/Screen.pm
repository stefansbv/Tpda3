package Tpda3::Config::Screen;

# ABSTRACT: Configuration data structure for screens

use 5.010;
use strict;
use warnings;

use Data::Diver qw( Dive ); #  DiveError
use Hash::Merge;

use Tpda3::Config;

use Data::Dump;

sub new {
    my ( $class, $args ) = @_;
    my $self = {
        _cfg => Tpda3::Config->instance(),
    };
    bless $self, $class;
    $self->{_scr} = $self->load_conf( $args->{scrcfg} );
    $self->alter_toolbar_state;
    return $self;
}

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

sub load_conf {
    my ($self, $name) = @_;
    my $conf_file = $self->cfg->config_scr_file_name($name);
    my $conf_href = $self->cfg->config_data_from($conf_file);
    return $conf_href;
}

#-- Screen sections

sub screen {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'screen', @args );
}

sub defaultreport {
    my ($self, @args) = @_;
    my $c = Dive( $self->{_scr}, 'defaultreport', @args );
    return $c // {};
}

sub defaultdocument {
    my ($self, @args) = @_;
    my $c = Dive( $self->{_scr}, 'defaultdocument', @args );
    # if ( $self->cfg->{verbose} ) {
    #     my ( $errDesc, $ref, $svKey ) = DiveError();
    #     warn "$errDesc: $$svKey\n";
    # }
    return $c // {};
}

sub lists_ds {
    my ($self, @args) = @_;
    my $c =  Dive( $self->{_scr}, 'lists_ds', @args );
    return $c // {};
}

sub lists_ds_tm {
    my ($self, @args) = @_;
    my $c = Dive( $self->{_scr}, 'lists_ds_tm', @args );
    return $c // {};
}

sub list_header {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'list_header', @args );
}

sub bindings {
    my ($self, @args) = @_;
    my $c = Dive( $self->{_scr}, 'bindings', @args );
    return $c // {};
}

sub bindings_select {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'bindings_select', @args );
}

sub tablebindings {
    my ($self, @args) = @_;
    my $c = Dive( $self->{_scr}, 'tablebindings', @args );
    return $c // {};
}

sub maintable {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'maintable', @args );
}

sub deptable {
    my ($self, @args) = @_;
    my $c = Dive( $self->{_scr}, 'deptable', @args );
    return $c // {};
}

sub is_href_is_empty {
    my ($self, $href) = @_;
    return undef if not ref $href;
    return undef if ref $href ne 'HASH';
    return !keys %{$href};
}

sub is_aref_is_empty {
    my ($self, $aref) = @_;
    return undef if not ref $aref;
    return undef if ref $aref ne 'ARRAY';
    return !@{$aref};
}

sub deptable_name {
    my ($self, $tm_ds) = @_;
    die "deptable_name: the \$tm_ds parameter is required" unless $tm_ds;
    my $name = $self->deptable( $tm_ds, 'name' );
    return undef if $self->is_href_is_empty($name);
    return $name;
}

sub deptable_view  {
    my ($self, $tm_ds) = @_;
    die "deptable_view: the \$tm_ds parameter is required" unless $tm_ds;
    my $view = $self->deptable( $tm_ds, 'view' );
    return undef if $self->is_href_is_empty($view);
    return $view;
}

sub deptable_updatestyle  {
    my ($self, $tm_ds) = @_;
    die "deptable_updatestyle: the \$tm_ds parameter is required" unless $tm_ds;
    my $conf = $self->deptable( $tm_ds, 'updatestyle' );
    return undef if $self->is_href_is_empty($conf);
    return $conf;
}

sub deptable_columns  {
    my ($self, $tm_ds, @args) = @_;
    die "deptable_columns: the \$tm_ds parameter is required" unless $tm_ds;
    my $columns = $self->deptable( $tm_ds, 'columns', @args );
    return undef if $self->is_href_is_empty($columns);
    return $columns;
}

sub deptable_columns_rw {
    my ( $self, $tm_ds ) = @_;
    die "deptable_columns: the \$tm_ds parameter is required" unless $tm_ds;
    my $columns = $self->deptable( $tm_ds, 'columns' );
    return undef if $self->is_href_is_empty($columns);
    my $columns_rw = {};
    foreach my $field ( keys %{$columns} ) {
        next unless $columns->{$field}{readwrite} eq 'rw';
        $columns_rw->{$field} = $columns->{$field};
    }
    return $columns_rw;
}

sub deptable_keys {
    my ($self, $tm_ds, @args) = @_;
    die "deptable_keys: the \$tm_ds parameter is required" unless $tm_ds;
    my $keys = $self->deptable( $tm_ds, 'keys', @args );
    return undef if $self->is_href_is_empty($keys);
    return undef if $self->is_aref_is_empty($keys);
    return $keys;
}

sub deptable_selectorcol {
    my ( $self, $tm_ds ) = @_;
    die "deptable_selectorcol: the \$tm_ds parameter is required" unless $tm_ds;
    my $conf = $self->deptable( $tm_ds, 'selectorcol' );
    return undef if $self->is_href_is_empty($conf);
    return undef if !$conf;
    return $conf;
}

sub deptable_selectorcolor {
    my ( $self, $tm_ds ) = @_;
    die "deptable_selectorcolor: the \$tm_ds parameter is required"
      unless $tm_ds;
    my $conf = $self->deptable( $tm_ds, 'selectorcolor' );
    return undef if $self->is_href_is_empty($conf);
    return undef if !$conf;
    return $conf;
}

sub deptable_selectorstyle  {
    my ($self, $tm_ds) = @_;
    die "deptable_selectorstyle: the \$tm_ds parameter is required"
      unless $tm_ds;
    my $conf = $self->deptable( $tm_ds, 'selectorstyle' );
    return undef if $self->is_href_is_empty($conf);
    return undef if !$conf;
    return $conf;
}

sub deptable_colstretch  {
    my ($self, $tm_ds) = @_;
    die "deptable_colstretch: the \$tm_ds parameter is required" unless $tm_ds;
    my $conf = $self->deptable( $tm_ds, 'colstretch' );
    return undef if $self->is_href_is_empty($conf);
    return undef if !$conf;
    return $conf;
}

sub deptable_orderby {
    my ($self, $tm_ds) = @_;
    die "deptable_orderby: the \$tm_ds parameter is required" unless $tm_ds;
    my $conf = $self->deptable( $tm_ds, 'orderby' );
    return undef if $self->is_href_is_empty($conf);
    return undef if !$conf;
    return $conf;
}

sub repotable {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'repotable', @args );
}

sub scrtoolbar {
    my ($self, @args) = @_;
    my $c = Dive( $self->{_scr}, 'scrtoolbar', @args );
    return $c // {};
}

sub toolbar {
    my ($self, @args) = @_;
    my $c =  Dive( $self->{_scr}, 'toolbar', @args );
    return $c // {};
}

#-- Screen sections END

sub has_screen_details {
    my $self = shift;
    my $screen = $self->screen('details');
    if ( ref $screen eq 'HASH' ) {
        return scalar keys %{$screen};
    }
    return;
}

sub has_defaultreport {
    my $self = shift;
    my $conf = $self->defaultreport;
    if ( ref $conf eq 'HASH' ) {
        return scalar keys %{$conf};
    }
    return;
}

sub has_defaultdocument {
    my $self = shift;
    my $conf = $self->defaultdocument;
    if ( ref $conf eq 'HASH' ) {
        return scalar keys %{$conf};
    }
    return;
}

sub screen_toolbars {
    my ( $self, $name ) = @_;
    die "Screen toolbar name is required" unless $name;
    my $scrtb    = $self->scrtoolbar($name);
    return unless $scrtb;
    my $toolbars = [];
    if ( ref $scrtb eq 'ARRAY' ) {
        $toolbars = $scrtb;
    }
    else {
        $toolbars = [$scrtb];
    }
    return $toolbars;
}

sub scr_toolbar_names {
    my ( $self, $name ) = @_;
    die " scr_toolbar_names: the \$name parameter is required\n"
        unless defined $name;
    my $attribs = $self->screen_toolbars($name);
    if ( ref $attribs eq 'ARRAY' ) {
        my @tbnames = map { $_->{name} } @{$attribs};
        my %tbattrs = map { $_->{name} => $_->{method} } @{$attribs};
        return ( \@tbnames, \%tbattrs );
    }
    die "Config error for screen toolbar name '$name'\n";
    return;
}

sub scr_toolbar_groups {
    my $self = shift;
    my @group_labels = keys %{ $self->scrtoolbar // {} }; # TODO ...
    return \@group_labels;
}

sub dep_table_header_info {
    my ( $self, $tm_ds ) = @_;
    die "TM parameter missing!" unless $tm_ds;
    my $href = {};
    $href->{updatestyle}   = $self->deptable_updatestyle($tm_ds);
    $href->{columns}       = $self->deptable_columns($tm_ds);
    $href->{selectorcol}   = $self->deptable_selectorcol($tm_ds);
    $href->{selectorcolor} = $self->deptable_selectorcolor($tm_ds);
    $href->{selectorstyle} = $self->deptable_selectorstyle($tm_ds);
    $href->{colstretch}    = $self->deptable_colstretch($tm_ds);
    $href->{orderby}       = $self->deptable_orderby($tm_ds);
    return $href;
}

sub repo_table_header_info {
    my $self = shift;

    my $href = {};

    $href->{columns}       = $self->repotable('columns');
    $href->{selectorcol}   = $self->repotable('selectorcol');
    $href->{colstretch}    = $self->repotable('colstretch');
    $href->{selectorstyle} = $self->repotable('selectorstyle');

    return $href;
}

sub app_dateformat {
    my $self = shift;
    return $self->cfg->application->{dateformat} || 'iso';
}

sub app_toolbar_attribs {
    my $self = shift;
    return $self->cfg->toolbar2;
}

# sub dep_table_has_selectorcol {
#     my ( $self, $tm_ds ) = @_;
#     die "TM parameter missing!" unless $tm_ds;
#     my $sc = $self->deptable($tm_ds, 'selectorcol');
#     if ( ref $sc eq 'HASH' ) {
#         return scalar keys %{$sc};
#     }
#     ???
# }

sub repo_table_columns_by_level {
    my ( $self, $level ) = @_;

    my $cols = $self->repotable('columns');

    $level = 'level' . $level;
    my $dss;

    foreach my $col ( keys %{$cols} ) {
        my $ds = ref $cols->{$col}{datasource}
               ? $cols->{$col}{datasource}{$level}
               : $cols->{$col}{datasource};
        next unless $ds;
        $dss->{$ds} = [] unless exists $dss->{$ds};
        push @{ $dss->{$ds} }, $col;
    }

    return $dss;
}

sub alter_toolbar_state {
    my $self = shift;
    my $tb_orig_ref = $self->cfg->toolbar->tool;
    my $tb_scrn_ref = $self->toolbar // {};
    my $merged = Hash::Merge->new('RIGHT_PRECEDENT')
        ->merge( $tb_orig_ref, $tb_scrn_ref );
    $self->cfg->toolbar->tool($merged);
    return;
}

1;

=head1 SYNOPSIS

Load the screen configuration.

    use Tpda3::Config::Screen;

    my $foo = Tpda3::Config::Screen->new();
    ...

=head2 new

Constructor method.

=head2 cfg

Return configuration instance object.

=head2 load_conf

Return a Perl data structure from a configuration file.

=head2 screen

Return the L<screen> section data structure.

The L<screen> section is required.

The B<details> section can be used for loading different screen
modules in the B<Details> tab, based on a field value from the
B<Record> tab.

In the screen config example below C<cod_tip> can be B<CS> or B<CT>,
and for each, the corresponding screen module is loaded.  The
C<filter> parameter is the foreign key of the database table.  There
si no default screen in this example.

    <screen>
        version             = 5
        name                = persoane
        description         = Persoane si activitati
        style               = default
        geometry            = 710x728+20+20
        <details>
            match           = cod_tip
            filter          = id_act
            <detail>
                value       = CS
                name        = Cursuri
            </detail>
            <detail>
                value       = CT
                name        = Consult
            </detail>
        </details>
    </screen>

Here C<cod_tip> and C<id_act> are fields from the TableMatrix widget
on the C<rec> page, coresponding to the fields with the same name from
a details database table.

Another example, the simplest configuration with a default screen
C<Activity>:

    <screen>
      version               = 5
      ...
      details               = Activity
    </screen>

In the screen config example below C<id_prsrv> can be B<4> and the
corresponding screen module C<Gunoi> is loaded.  Or can have any other
value and the default screen named C<Details> is loaded.

  <details>
      match           = id_prsrv
      filter          = id_art
      default         = Details
      <detail>
          value       = 4
          name        = Gunoi
      </detail>
  </details>

=head2 defaultreport

Return the L<defaultreport> section data structure.

    <defaultreport>
        name                = The title of the report
        file                = report-file.rep
    </defaultreport>

The L<defaultreport> section is optional.

=head2 defaultdocument

Return the L<defaultdocument> section data structure.

    <defaultdocument>
        name                = The title of the document
        file                = template-file.tt
        datasource          = db_view_name
    </defaultdocument>

The L<defaultdocument> section is optional.

=head2 lists_ds

Return the L<lists_ds> section data structure.

    <lists_ds>
        <cod_stud>
            orderby         = id_isced
            name            = denumire
            table           = isced
            default         =
            code            = id_isced
        </cod_stud>
    </lists_ds>

The L<lists_ds> section is optional.

=head2 lists_ds_tm

Return the L<lists_ds_tm> section data structure.  Has the same
configuration as for L<list_ds but> is for the embeded ComboBox from
the TM widget.

The L<lists_ds_tm> section is optional.

=head2 list_header

Return the L<list_header> section data structure.

    <list_header>
        lookup              = [ id_column ]
        column              = column1
        column              = column2
        ...
    </list_header>

The L<lookup> column value is returned and considered the primary key
of the table.  Some screens can have a second L<lookup> column.

    <list_header>
        lookup              = id_column1
        lookup              = id_column2
        column              = column3
        column              = column4
        ...
    </list_header>

=head2 bindings

Return the L<bindings> section data structure.

See the POD in L<setup_lookup_bindings_entry> in the Tpda3::Controller
module.

=head2 bindings_select

Return the L<bindings_select> section data structure.

    <bindings_select>
        <suma>
            target_tm       = tm1
            table           = fact_pr
            filter          = id_terti
            order           = data_fact
            field           = id_fact
            ...
            callback        = update_suma
        </suma>
    </bindings_select>

=head2 tablebindings

Return the L<tablebindings> section data structure.

See the POD in L<get_lookup_setings> in the Tpda3::Controller
module.

=head2 deptable

Return the L<deptable> section data structure.

    <deptable tm1>
        name                = orderdetails
        view                = v_orderdetails
        updatestyle         = delete+add
        selectorcol         =
        selectorcolor       =
        selectorstyle       =
        colstretch          = 2
        orderby             = orderlinenumber
        <keys>
            name            = ordernumber
            name            = orderlinenumber
        </keys>
        <columns>
            <orderlinenumber>
                id          = 0
                label       = Art
                tag         = ro_center
                displ_width = 5
                valid_width = 5
                numscale    = 0
                readwrite   = rw
                datatype    = integer
            </orderlinenumber>
            ...
        </columns>
    </deptable>

=head2 repotable

Return the L<repotable> section data structure.

=head2 scrtoolbar

Return the L<scrtoolbar> section data structure.

    <scrtoolbar>
        <tm1>
            name            = tb2ad
            method          = tmatrix_add_row
        </tm1>
        <tm1>
            name            = tb2rm
            method          = tmatrix_remove_row
        </tm1>
    </scrtoolbar>

=head2 toolbar

Return the L<toolbar> section data structure.

    <toolbar>
      <tb_fm>
        <state>
          <rec>
            idle            = disabled
            add             = disabled
            edit            = disabled
          </rec>
        </state>
      </tb_tn>
      <tb_rm>
        <state>
          <rec>
            edit            = disabled
          </rec>
        </state>
      </tb_rm>
    </toolbar>

=head2 maintable

Return the L<maintable> section data structure.

    <maintable>
        name                = orders
        view                = v_orders
        <keys>
            name            = [ ordernumber ]
        </keys>
        <columns>
            <customername>
                label       = Customer
                state       = normal
                ctrltype    = e
                displ_width = 30
                valid_width = 30
                numscale    = 0
                readwrite   = ro
                findtype    = contains
                bgcolor     = lightgreen
                datatype    = alphanumplus
            </customername>
            ...
        </columns>
    </maintable>

=head2 has_screen_details

Return true if the main screen has details screen.

=head2 screen_toolbars

Return the C<scrtoolbar> configuration data structure defined for the
curren screen.

If there is only one toolbar button then return it as an array reference.

=head2 scr_toolbar_names

Return the toolbar names and their method names configured for the
current screen.

=head2 scr_toolbar_groups

The scrtoolbar are grouped with a label that used to be the same as
the TM label, because each group was considered to be attached to a TM
widget.  Now screen toolbars can be defined separately.

This method returns the labels.

=head2 dep_table_header_info

Return the table header configuration data structure bound to the
related Tk::TableMatrix widget.

=head2 repo_table_header_info

Return the table header configuration data structure bound to the
related Tk::TableMatrix widget.

=head2 app_dateformat

Date format configuration.

=head2 app_toolbar_attribs

Return the toolbar configuration data structure defined for the
current application, in the etc/toolbar.yml file.

=head2 dep_table_has_selectorcol

Return true if the dependent table has I<selector column> attribute
set.

=head2 repo_table_columns_by_level

Return the dependent table columns configuration data structure bound
to the related Tk::TableMatrix widget, filtered by the I<level>.

Columns with no level ...

=cut
