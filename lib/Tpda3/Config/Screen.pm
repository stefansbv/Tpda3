package Tpda3::Config::Screen;

use strict;
use warnings;

use Data::Dumper;

use Log::Log4perl qw(get_logger);
use File::Spec::Functions;

use Tpda3::Config;
use Tpda3::Config::Utils;

use base qw(Class::Accessor);

=head1 NAME

Tpda3::Config::Screen - Configuration module for screen

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Tpda3::Config::Screen;

    my $foo = Tpda3::Config::Screen->new();
    ...

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

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

Load a config files at request

=cut

sub config_screen_load {
    my ($self, $scrcls) = @_;

    my $log = get_logger();

    my $file_name = "$scrcls.conf";
    my $cfg_file  = $self->config_scr_file_name($file_name);

    my $msg = qq{\nConfiguration error: \n Can't read configurations};
    $msg   .= qq{\n  from '$cfg_file'!};

    $log->info("Loading '$file_name' config");
    $log->trace("file: $cfg_file");

    my $cfg_data = Tpda3::Config::Utils->config_file_load($cfg_file, $msg);

    my @accessor = keys %{ $cfg_data };
    $log->trace("Making accessors for: @accessor");

    $self->_make_accessors( $cfg_data );

    return;
}

=head2 config_scr_file_name

Return fully qualified screen configuration file name.

=cut

sub config_scr_file_name {
    my ( $self, $file_name ) = @_;

    my $cfg = Tpda3::Config->instance();

    return catfile( $cfg->cfapps, $cfg->cfname, 'scr', $file_name );
}

sub screen_detail {
    my $self = shift;

    return $self->screen->{details};
}

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

=head2 m_table

Return main table configurations data structure.

=cut

sub m_table {
    my $self = shift;

    return $self->maintable if $self->can('maintable');
}

sub m_table_name {
    my $self = shift;

    return $self->m_table->{name};
}

sub m_table_view {
    my $self = shift;

    return $self->m_table->{view};
}

sub m_table_generator {
    my $self = shift;

    return $self->m_table->{generator};
}

sub m_table_pkcol {
    my $self = shift;

    return $self->m_table->{pkcol}{name};
}

sub m_table_fkcol {
    my $self = shift;

    return $self->m_table->{fkcol}{name};
}

sub m_table_columns {
    my $self = shift;

    return $self->m_table->{columns};
}

sub m_table_column {
    my ($self, $column) = @_;

    return $self->m_table_columns->{$column};
}

sub m_table_column_attr {
    my ($self, $column, $attr) = @_;

    return $self->m_table_column($column)->{$attr};
}

#---

sub d_table {
    my ($self, $tm_ds) = @_;

    return $self->deptable->{$tm_ds} if $self->can('deptable');
}

sub d_table_name {
    my ($self, $tm_ds) = @_;

    return $self->d_table($tm_ds)->{name};
}

sub d_table_view {
    my ($self, $tm_ds) = @_;

    return $self->d_table($tm_ds)->{view};
}

sub d_table_generator {
    my ($self, $tm_ds) = @_;

    return $self->d_table($tm_ds)->{generator};
}

sub d_table_updatestyle {
    my ($self, $tm_ds) = @_;

    return $self->d_table($tm_ds)->{updatestyle};
}

sub d_table_selectorcol {
    my ($self, $tm_ds) = @_;

    return $self->d_table($tm_ds)->{selectorcol};
}

sub d_table_has_selectorcol {
    my ($self, $tm_ds) = @_;

    my $sc = $self->d_table_selectorcol($tm_ds);

    return if $sc eq 'none';

    return $sc;
}

sub d_table_orderby {
    my ($self, $tm_ds) = @_;

    return $self->d_table($tm_ds)->{orderby};
}

sub d_table_colstretch {
    my ($self, $tm_ds) = @_;

    return $self->d_table($tm_ds)->{colstretch};
}

sub d_table_pkcol {
    my ($self, $tm_ds) = @_;

    return $self->d_table($tm_ds)->{pkcol}{name};
}

sub d_table_fkcol {
    my ($self, $tm_ds) = @_;

    return $self->d_table($tm_ds)->{fkcol}{name};
}

sub d_table_columns {
    my ($self, $tm_ds) = @_;

    return $self->d_table($tm_ds)->{columns};
}

sub d_table_column {
    my ($self, $tm_ds, $column) = @_;

    return $self->d_table_columns($tm_ds)->{$column};
}

sub d_table_column_attr {
    my ($self, $tm_ds, $column, $attr) = @_;

    return $self->d_table($tm_ds)->{columns}{$column}{$attr};
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

1; # End of Tpda3::Config::Screen
