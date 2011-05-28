package Tpda3::Config::Screen;

use strict;
use warnings;

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
    my ($self, $file_name) = @_;

    my $log = get_logger();

    my $cfg_file = $self->config_scr_file_name($file_name);

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
