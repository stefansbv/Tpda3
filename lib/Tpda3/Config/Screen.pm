package Tpda3::Config::Screen;

use strict;
use warnings;

use Log::Log4perl qw(get_logger);
use File::Spec::Functions;

use Tpda3::Config;
use Tpda3::Config::Utils;
use Tpda3::Utils;

use base qw(Class::Accessor);

=head1 NAME

Tpda3::Config::Screen - Configuration module for screen

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

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

    $self->config_screen_load($args);

    return $self;
}

=head2 _make_accessors

Automatically make accessors for the hash keys.

=cut

sub _make_accessors {
    my ( $self, $cfg_hr ) = @_;

    __PACKAGE__->mk_accessors( keys %{$cfg_hr} );

    # Add data to object
    foreach ( keys %{$cfg_hr} ) {
        $self->$_( $cfg_hr->{$_} );
    }

    return;
}

=head2 config_screen_load

Load a Screen configuration files at request and make accessors.

=cut

sub config_screen_load {
    my ( $self, $scrcls ) = @_;

    my $log = get_logger();

    my $cfg_data = $self->config_screen_load_file($scrcls);

    my @accessor = keys %{$cfg_data};
    $log->info("Making accessors for: @accessor");

    $self->_make_accessors($cfg_data);

    return;
}

=head2 config_screen_load_file

Load a Screen configuration files at request.

=cut

sub config_screen_load_file {
    my ( $self, $scrcls ) = @_;

    my $log = get_logger();

    my $file_name = "$scrcls.conf";
    my $cfg_file  = $self->config_scr_file_name($file_name);

    my $msg = qq{\nConfiguration error: \n Can't read configurations};
    $msg .= qq{\n  from '$cfg_file'!};

    $log->info("Loading '$file_name' config");
    $log->trace(" file: $cfg_file");

    return Tpda3::Config::Utils->config_file_load( $cfg_file, $msg );
}

=head2 _cfg

Return config instance variable

=cut

sub _cfg {
    my $self = shift;

    return $self->{_cfg};
}

=head2 config_scr_file_name

Return fully qualified screen configuration file name.

=cut

sub config_scr_file_name {
    my ( $self, $file_name ) = @_;

    my $conf_fn = catfile( $self->_cfg->configdir, 'scr', $file_name );

    if (-f $conf_fn) {
        return $conf_fn;
    }
    else {

        # Fallback to alternative location (tools)
        return catfile( $self->_cfg->cfpath, 'scr', $file_name );
    }
}

=head2 app_dateformat

Date format configuration.

=cut

sub app_dateformat {
    my $self = shift;

    return $self->_cfg->application->{dateformat} || 'iso';
}

=head2 get_defaultreport_file

Return default report path and file, used by the print tool button.

=cut

sub get_defaultreport_file {
    my $self = shift;

    return catfile( $self->_cfg->config_rep_path, $self->defaultreport->{file} )
        if $self->defaultreport->{file};

    return;
}

=head2 get_defaultreport_name

Return default report description, used by the print tool button, for
the baloon label.

=cut

sub get_defaultreport_name {
    my $self = shift;

    return $self->defaultreport->{name};
}

=head2 get_defaultdocument_file



=cut

sub get_defaultdocument_file {
    my $self = shift;

    return catfile( $self->_cfg->config_tex_model_path,
        $self->defaultdocument->{file} )
        if $self->defaultdocument->{file};

    return;
}

=head2 get_defaultdocument_name

Return default document description, used by the edit tool button, for
the baloon label.

=cut

sub get_defaultdocument_name {
    my $self = shift;

    return $self->defaultdocument->{name};
}

=head2 get_defaultdocument_datasource

Return default document description, used by the edit tool button, for
the baloon label.

=cut

sub get_defaultdocument_datasource {
    my $self = shift;

    return $self->defaultdocument->{datasource};
}

=head2 screen_name

Screen name.

=cut

sub screen_name {
    my $self = shift;

    return $self->screen->{name};
}

=head2 screen_style

Return screen style attribute.

=cut

sub screen_style {
    my $self = shift;

    return $self->screen->{style};
}

=head2 screen_description

Return screen description string.

=cut

sub screen_description {
    my $self = shift;

    return $self->screen->{description};
}

=head2 screen_detail

Return details screen data structure.

=cut

sub screen_detail {
    my $self = shift;

    return $self->screen->{details};
}

=head2 has_screen_detail

Return true if the main screen has details screen.

=cut

sub has_screen_detail {
    my $self = shift;

    my $screen = $self->screen_detail;
    if ( ref $screen ) {
        return scalar keys %{$screen};
    }
    else {
        return $screen;
    }
}

=head2 main_table

Return the main table configuration data structure.

=cut

sub main_table {
    my $self = shift;

    return $self->maintable if $self->can('maintable');
}

=head2 main_table_name

Return the main table name.

=cut

sub main_table_name {
    my $self = shift;

    return $self->main_table->{name};
}

=head2 main_table_view

Return the main table view name.

=cut

sub main_table_view {
    my $self = shift;

    return $self->main_table->{view};
}

=head2 main_table_pkcol

Return the main table primary key column name.

=cut

sub main_table_pkcol {
    my $self = shift;

    return $self->main_table->{pkcol}{name};
}

=head2 main_table_fkcol

Return the main table foreign key column name.

=cut

sub main_table_fkcol {
    my $self = shift;

    if ( exists $self->main_table->{fkcol} ) {
        return $self->main_table->{fkcol}{name};
    }

    return;
}

=head2 main_table_columns

Return the main table columns configuration data structure.

=cut

sub main_table_columns {
    my $self = shift;

    return $self->main_table->{columns};
}

=head2 main_table_column

Return a column from the main table columns configuration data
structure.

=cut

sub main_table_column {
    my ( $self, $column ) = @_;

    return $self->main_table_columns->{$column};
}

=head2 main_table_column_attr

Return a column attribute from the main table columns configuration
data structure.

=cut

sub main_table_column_attr {
    my ( $self, $column, $attr ) = @_;

    return $self->main_table_column($column)->{$attr};
}

=head2 dep_table

Return the dependent table configuration data structure.

=cut

sub dep_table {
    my ( $self, $tm_ds ) = @_;

    return $self->deptable->{$tm_ds} if $self->can('deptable');
}

=head2 dep_table_name

Return the dependent table name.

=cut

sub dep_table_name {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{name};
}

=head2 dep_table_view

Return the dependent table view name.

=cut

sub dep_table_view {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{view};
}

=head2 dep_table_updatestyle

Return the dependent table I<update style> attribute.

=cut

sub dep_table_updatestyle {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{updatestyle};
}

=head2 dep_table_selectorcol

Return the dependent table I<selector column> attribute.

=cut

sub dep_table_selectorcol {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{selectorcol};
}

=head2 dep_table_has_selectorcol

Return true if the dependent table has I<selector column> attribute
set.

=cut

sub dep_table_has_selectorcol {
    my ( $self, $tm_ds ) = @_;

    my $sc = $self->dep_table_selectorcol($tm_ds);

    return if $sc eq 'none';

    return $sc;
}

=head2 dep_table_orderby

Return the dependent table I<order by> attribute.

=cut

sub dep_table_orderby {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{orderby};
}

=head2 dep_table_colstretch

Return the dependent table I<colstretch> attribute.

=cut

sub dep_table_colstretch {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{colstretch};
}

sub dep_table_datasources {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{datasources};
}

=head2 dep_table_rowcount

Return the dependent table I<rowcount> attribute.

=cut

sub dep_table_rowcount {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{rowcount};
}

=head2 dep_table_pkcol

Return the dependent table primary key column name.

=cut

sub dep_table_pkcol {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{pkcol}{name};
}

=head2 dep_table_fkcol

Return the dependent table foreign key column name.

=cut

sub dep_table_fkcol {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{fkcol}{name};
}

=head2 dep_table_columns

Return the dependent table columns configuration data structure bound
to the related Tk::TableMatrix widget.

=cut

sub dep_table_columns {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{columns};
}

=head2 dep_table_columns_by_ds

Return the dependent table columns configuration data structure bound
to the related Tk::TableMatrix widget, filtered by the I<level>.

Columns with no level ...

=cut

sub dep_table_columns_by_level {
    my ( $self, $tm_ds, $level ) = @_;

    my $cols = $self->dep_table_columns($tm_ds);

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

=head2 dep_table_column

Return a column from the dependent table columns configuration data
structure bound to the related Tk::TableMatrix widget.

=cut

sub dep_table_column {
    my ( $self, $tm_ds, $column ) = @_;

    return $self->dep_table_columns($tm_ds)->{$column};
}

=head2 dep_table_column_attr

Return a column attribute from the dependent table columns
configuration data structure bound to the related Tk::TableMatrix
widget.

=cut

sub dep_table_column_attr {
    my ( $self, $tm_ds, $column, $attr ) = @_;

    return $self->dep_table($tm_ds)->{columns}{$column}{$attr};
}

=head2 dep_table_toolbars

Return the toolbar configuration data structure bound to the related
Tk::TableMatrix widget.

=cut

sub dep_table_toolbars {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{toolbar};
}

=head2 dep_table_header_info

Return the table header configuration data structure bound to the
related Tk::TableMatrix widget.

=cut

sub dep_table_header_info {
    my ( $self, $tm_ds ) = @_;

    return {
        columns     => $self->dep_table_columns($tm_ds),
        selectorcol => $self->dep_table_selectorcol($tm_ds),
        colstretch  => $self->dep_table_colstretch($tm_ds),
    };
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users.sourceforge.net> >>

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Config::Screen

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

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
