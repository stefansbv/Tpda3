package Tpda3::Config::Screen;

use strict;
use warnings;

use Data::Diver qw( Dive );

require Tpda3::Config;

=head1 NAME

Tpda3::Config::Screen - Configuration module for screen

=head1 VERSION

Version 0.89

=cut

our $VERSION = 0.89;

=head1 SYNOPSIS

Load the screen configuration.

    use Tpda3::Config::Screen;

    my $foo = Tpda3::Config::Screen->new();
    ...

=head1 METHODS

=head2 new

Constructor method.

=cut

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

=head2 cfg

Return configuration instance object.

=cut

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

=head2 load_conf

Return a Perl data structure from a configuration file.

=cut

sub load_conf {
    my ($self, $name) = @_;

    my $conf_file = $self->cfg->config_scr_file_name($name);
    my $conf_href = $self->cfg->config_data_from($conf_file);

    return $conf_href;
}

=head2 screen

Return the L<screen> section data structure.

The B<details> section can be used for loading different screen
modules in the B<Details> tab, based on a field value from the
B<Record> tab.

In the screen config example below C<cod_tip> can be B<CS> or B<CT>,
and for each, the corresponding screen module is loaded.  The
C<filter> parametere is the foreign key of the database table.

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

=cut

sub screen {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'screen', @args );
}

=head2 defaultreport

Return the L<defaultreport> section data structure.

    <defaultreport>
        name                = The title of the report
        file                = report-file.rep
    </defaultreport>

=cut

sub defaultreport {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'defaultreport', @args );
}

=head2 defaultdocument

Return the L<defaultdocument> section data structure.

    <defaultdocument>
        name                = The title of the document
        file                = template-file.tt
        datasource          = db_view_name
    </defaultdocument>

=cut

sub defaultdocument {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'defaultdocument', @args );
}

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

=cut

sub lists_ds {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'lists_ds', @args );
}

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

=cut

sub list_header {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'list_header', @args );
}

=head2 bindings

Return the L<bindings> section data structure.

See the POD in L<setup_lookup_bindings_entry> in the Tpda3::Controller
module.

=cut

sub bindings {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'bindings', @args );
}

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

=cut

sub bindings_select {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'bindings_select', @args );
}

=head2 tablebindings

Return the L<tablebindings> section data structure.

See the POD in L<get_lookup_setings> in the Tpda3::Controller
module.

=cut

sub tablebindings {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'tablebindings', @args );
}

=head2 deptable

Return the L<deptable> section data structure.

    <deptable tm1>
        name                = orderdetails
        view                = v_orderdetails
        updatestyle         = delete+add
        selectorcol         =
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

=cut

sub deptable {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'deptable', @args );
}

=head2 repotable

Return the L<repotable> section data structure.

=cut

sub repotable {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'repotable', @args );
}

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


=cut

sub scrtoolbar {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'scrtoolbar', @args );
}

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

=cut

sub toolbar {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'toolbar', @args );
}

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

=cut

sub maintable {
    my ($self, @args) = @_;
    return Dive( $self->{_scr}, 'maintable', @args );
}

=head2 has_screen_details

Return true if the main screen has details screen.

=cut

sub has_screen_details {
    my $self = shift;

    my $screen = $self->screen('details');
    if ( ref $screen ) {
        return scalar keys %{$screen};
    }
    else {
        return $screen;
    }
}

=head2 screen_toolbars

Return the C<scrtoolbar> configuration data structure defined for the
curren screen.

If there is only one toolbar button then return it as an array reference.

=cut

sub screen_toolbars {
    my ( $self, $name ) = @_;

    die "Screen toolbar name is required" unless $name;

    my $scrtb = $self->scrtoolbar($name);
    my @toolbars;
    if (ref($scrtb) eq 'ARRAY') {
        @toolbars = @{$scrtb};
    }
    else {
        @toolbars = ($scrtb);
    }

    return \@toolbars;
}

=head2 scr_toolbar_names

Return the toolbar names and their method names configured for the
current screen.

=cut

sub scr_toolbar_names {
    my ($self, $name) = @_;

    my $attribs = $self->screen_toolbars($name);
    my @tbnames = map { $_->{name} } @{$attribs};
    my %tbattrs = map { $_->{name} => $_->{method} } @{$attribs};

    return (\@tbnames, \%tbattrs);
}

=head2 scr_toolbar_groups

The scrtoolbar are grouped with a label that used to be the same as
the TM label, because each group was considered to be attached to a TM
widget.  Now screen toolbars can be defined separately.

This method returns the labels.

=cut

sub scr_toolbar_groups {
    my $self = shift;
    my @group_labels = keys %{ $self->scrtoolbar };
    return \@group_labels;
}

=head2 dep_table_header_info

Return the table header configuration data structure bound to the
related Tk::TableMatrix widget.

=cut

sub dep_table_header_info {
    my ( $self, $tm_ds ) = @_;

    die "TM parameter missing!" unless $tm_ds;

    my $href = {};

    $href->{columns}       = $self->deptable( $tm_ds, 'columns' );
    $href->{selectorcol}   = $self->deptable( $tm_ds, 'selectorcol' );
    $href->{colstretch}    = $self->deptable( $tm_ds, 'colstretch' );
    $href->{selectorstyle} = $self->deptable( $tm_ds, 'selectorstyle' );

    return $href;
}

=head2 repo_table_header_info

Return the table header configuration data structure bound to the
related Tk::TableMatrix widget.

=cut

sub repo_table_header_info {
    my $self = shift;

    my $href = {};

    $href->{columns}       = $self->repotable('columns');
    $href->{selectorcol}   = $self->repotable('selectorcol');
    $href->{colstretch}    = $self->repotable('colstretch');
    $href->{selectorstyle} = $self->repotable('selectorstyle');

    return $href;
}

=head2 app_dateformat

Date format configuration.

=cut

sub app_dateformat {
    my $self = shift;

    return $self->cfg->application->{dateformat} || 'iso';
}

=head2 app_toolbar_attribs

Return the toolbar configuration data structure defined for the
current application, in the etc/toolbar.yml file.

=cut

sub app_toolbar_attribs {
    my $self = shift;

    return $self->cfg->toolbar2;
}

=head2 dep_table_has_selectorcol

Return true if the dependent table has I<selector column> attribute
set.

=cut

sub dep_table_has_selectorcol {
    my ( $self, $tm_ds ) = @_;

    die "TM parameter missing!" unless $tm_ds;
    my $sc = $self->deptable($tm_ds, 'selectorcol');

    return $sc;
}

=head2 repo_table_columns_by_level

Return the dependent table columns configuration data structure bound
to the related Tk::TableMatrix widget, filtered by the I<level>.

Columns with no level ...

=cut

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

=head2 alter_toolbar_state

Alter the I<state> of the tool-bar buttons per screen, using the
I<toolbar> section from the screen configuration.

=cut

sub alter_toolbar_state {
    my $self = shift;

    my $tb_m = $self->cfg->toolbar();
    my $tb_a = $self->toolbar();

    foreach my $tb ( keys %{$tb_a} ) {
        foreach my $pg ( keys %{ $tb_a->{$tb}{state} } ) {
            foreach my $k ( keys %{ $tb_a->{$tb}{state}{$pg} } ) {
                $tb_m->{$tb}{state}{$pg}{$k} = $tb_a->{$tb}{state}{$pg}{$k};
            }
        }
    }

    $self->cfg->toolbar($tb_m);

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Config::Screen

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1;    # End of Tpda3::Config::Screen
