package Tpda3::Config;

use strict;
use warnings;

use Log::Log4perl qw(get_logger);

use File::HomeDir;
use File::UserConfig;
use File::Spec::Functions;

use Tpda3::Config::Utils;

use base qw(Class::Singleton Class::Accessor);

=head1 NAME

Tpda3::Config - Tpda Tpda configuration module

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

Reads configuration files in I<Config::General> format and create a
complex Perl data structure (HoH).  Then using I<Class::Accessor>,
automatically create methods from the keys of the hash.

    use Tpda3::Config;

    my $cfg = Tpda3::Config->instance($args); # first time init

    my $cfg = Tpda3::Config->instance(); # later, in other modules

=head1 METHODS

=head2 _new_instance

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=cut

sub _new_instance {
    my ($class, $args) = @_;

    my $self = bless {}, $class;

    $args->{cfgmain} = 'etc/main.yml'; # hardcoded main config file name

    # Load configuration and create accessors
    $self->config_main_load($args);
    if ( $args->{cfname} ) {
        # If no config name don't bother to load this
        # Interface configs
        $self->config_interface_load();
        # Application configs
        $self->config_application_load($args);
    }

    return $self;
}

=head2 make_accessors

Automatically make accessors for the hash keys.

=cut

sub make_accessors {
    my ( $self, $cfg_hr ) = @_;

    __PACKAGE__->mk_accessors( keys %{$cfg_hr} );

    # Add data to object
    foreach ( keys %{$cfg_hr} ) {
        $self->$_( $cfg_hr->{$_} );
    }

    return;
}

=head2 config_main_load

Initialize configuration variables from arguments, also initialize the
user configuration tree if not exists, with the I<File::UserConfig>
module.

Load the main configuration file and return a HoH data structure.

Make accessors.

=cut

sub config_main_load {
    my ( $self, $args ) = @_;

    my $configpath = File::UserConfig->new(
        dist     => 'tpda-mvc',
        sharedir => 'share',
    )->configdir;

    # Log init
    # Can't do before we know the application config path
    my $log_qfn = catfile( $configpath, 'etc/log.conf' );
    Log::Log4perl->init($log_qfn);

    $self->{_log} = get_logger();

    $self->{_log}->info("*** New session begin:");

    # Main config file name, load
    my $main_qfn = catfile( $configpath, $args->{cfgmain} );
    $self->{_log}->info("Main config file is $main_qfn");

    my $msg = qq{\nConfiguration error: \n Can't read 'main.conf'};
    $msg   .= qq{\n  from '$main_qfn'!};
    my $maincfg = Tpda3::Config::Utils->config_file_load($main_qfn, $msg);
    $self->{_log}->info("Main config file loaded.");

    # Base configuration methods
    my $main_hr = {
        cfpath  => $configpath,
        cfapps  => catdir($configpath, 'apps'),
        cfiface => $maincfg->{interface},
        cfapp   => $maincfg->{application},
        cfrun   => $maincfg->{runtime},
        user    => $args->{user}, # make accessors for user and pass
        pass    => $args->{pass},
    };

    # Setup when GUI runtime
    if ( $args->{cfname} ) {
        $main_hr->{cfname} = $args->{cfname};
    }

    my @accessor = keys %{$main_hr};
    $self->{_log}->info("Making accessors for @accessor");

    $self->make_accessors($main_hr);

    return $maincfg;
}

=head2 config_interface_load

Process the main configuration file and automaticaly load all the
interface defined configuration files.  That means if we add a YAML
configuration file to the tree, all defined values should be available
at restart.

=cut

sub config_interface_load {
    my $self = shift;

    foreach my $section ( keys %{ $self->cfiface } ) {
        my $cfg_file = $self->config_iface_file_name($section);

        my $msg = qq{\nConfiguration error: \n Can't read configurations};
        $msg .= qq{\n  from '$cfg_file'!};

        $self->{_log}->info("Loading $section config file: $cfg_file");
        my $cfg_hr = Tpda3::Config::Utils->config_file_load( $cfg_file, $msg );

        my @accessor = keys %{$cfg_hr};
        $self->{_log}->info("Making accessors for @accessor");

        $self->make_accessors($cfg_hr);
    }

    return;
}

=head2 config_application_load

Load the application configuration files.  This are treated separately
because the path is only known at runtime.

=cut

sub config_application_load {
    my ( $self, $args ) = @_;

    foreach my $section ( keys %{ $self->cfapp } ) {
        my $cfg_file = $self->config_app_file_name($section);

        $self->{_log}->info("Loading $section config file: $cfg_file");
        my $msg = qq{\nConfiguration error, to fix, run\n\n};
        $msg .= qq{  tpda-mvc -init };
        $msg .= $self->cfname . qq{\n\n};

        #$msg   .= qq{then edit: $cfgconn_f\n};
        my $cfg_hr = Tpda3::Config::Utils->config_file_load( $cfg_file, $msg );

        my @accessor = keys %{$cfg_hr};
        $self->{_log}->info("Making accessors for @accessor");

        $self->make_accessors($cfg_hr);
    }

    return;
}

=head2 config_iface_file_name

Return fully qualified application interface configuration file name.

=cut

sub config_iface_file_name {
    my ($self, $section) = @_;

    return catfile( $self->cfpath, $self->cfiface->{$section} );
}

=head2 config_app_file_name

Return fully qualified application configuration file name.

=cut

sub config_app_file_name {
    my ($self, $section) = @_;

    return catfile( $self->cfapps, $self->cfname,  $self->cfapp->{$section} );
}

=head2 list_configs

List all existing connection configurations.

=cut

sub list_configs {
    my $self = shift;

    my $conpath = $self->conpath;
    my $conn_list = Tpda3::Config::Utils->find_subdirs($conpath);

    print "Connection configurations:\n";
    foreach my $cfg_name ( @{$conn_list} ) {
        my $ccfn = Tpda3::Config::Utils->config_file_name($cfg_name);
        # If connection file exist than list as connection name
        if (-f $ccfn) {
            print "  > $cfg_name\n";
        }
    }
    print " in '$conpath'\n";

    return;
}

=head2 config_save_instance

Save instance configuarations.  Only window geometry configuration for
now.

=cut

sub config_save_instance {
    my ($self, $key, $value) = @_;

    my $inst = $self->cfrun->{instance};

    my $inst_qfn = catfile($self->cfapps, $self->cfname, $inst );

    Tpda3::Config::Utils->save_yaml($inst_qfn, $key, $value);

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users . sourceforge . net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Tpda3::Config
