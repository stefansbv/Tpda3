package Tpda3::Config::Screen;

use strict;
use warnings;

use Data::Diver qw( Dive );

require Tpda3::Config;

=head1 NAME

Tpda3::Config::Screen - Configuration module for screen

=head1 VERSION

Version 0.70

=cut

our $VERSION = 0.70;

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

    $self->{_scr} = $self->load_conf($args);

    $self->alter_toolbar();

    return $self;
}

=head2 _cfg

Return config instance variable

=cut

sub cfg {
    my $self = shift;

    return $self->{_cfg};
}

sub load_conf {
    my ($self, $name) = @_;

    my $config_file = $self->cfg->config_scr_file_name($name);
    my $config_href = $self->cfg->config_data_from($config_file);

    return $config_href;
}

=head2 screen

Return the screen section data structure.

The B<details> section is used for loading different screen modules
in the B<Details> tab, based on a field value from the B<Record> tab.

In the screen config example below C<cod_tip> can be B<CS> or B<CT>,
and for each, the corresponding screen module is loaded.  The
C<filter> parametere is the foreign key of the database table.

    <screen>
        version             = 4
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

sub defaultreport {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'defaultreport', @args );
}

sub defaultdocument {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'defaultdocument', @args );
}

=head2 lists_ds

Return the B<lists_ds> section data structure.  Data source for list
widgets (Combobox).

An example:

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

sub list_header {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'list_header', @args );
}

sub bindings {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'bindings', @args );
}

sub bindings_select {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'bindings_select', @args );
}

sub tablebindings {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'tablebindings', @args );
}

sub deptable {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'deptable', @args );
}

sub repotable {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'repotable', @args );
}

sub scrtoolbar {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'scrtoolbar', @args );
}

sub toolbar {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'toolbar', @args );
}

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

    return if $sc eq 'none';

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

=head2 alter_toolbar

Fine tune the configuration for screens, alter behavior of toolbar
buttons per screen.

=cut

sub alter_toolbar {
    my $self = shift;

    my $tb_m = $self->cfg->toolbar();
    my $tb_a = $self->toolbar();

    foreach my $tb ( keys %{$tb_a} ) {
        foreach my $pg ( keys %{ $tb_a->{$tb}{state} } ) {
            while ( my ( $k, $v ) = each( %{ $tb_a->{$tb}{state}{$pg} } ) ) {
                $tb_m->{$tb}{state}{$pg}{$k} = $v;
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

Copyright 2010-2013 Stefan Suciu.

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
