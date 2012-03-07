package Tpda3::Config;

use strict;
use warnings;

use Data::Dumper;
use Ouch;

use Log::Log4perl qw(get_logger :levels);
use File::Basename;
use File::HomeDir;
use File::ShareDir qw(dist_dir);
use File::UserConfig;
use File::Spec::Functions;
use File::Copy::Recursive ();

require Tpda3::Config::Utils;

use base qw(Class::Singleton Class::Accessor);

=head1 NAME

Tpda3::Config - Tpda Tpda configuration module

=head1 VERSION

Version 0.51

=cut

our $VERSION = '0.51';

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
    my ( $class, $args ) = @_;

    my $self = bless {}, $class;

    $args->{cfgmain} = 'etc/main.yml';    # hardcoded main config file name

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
    foreach my $name ( keys %{$cfg_hr} ) {
        $self->$name( $cfg_hr->{$name} );
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
        dist     => 'Tpda3',
        sharedir => 'share',
    )->configdir;

    my $base_methods_hr = {
        cfpath  => $configpath,
        cfapps  => catdir( $configpath, 'apps' ),
        cfetc   => catdir( $configpath, 'etc' ),
        user    => $args->{user},                   # make accessors for user
        pass    => $args->{pass},                   # and pass
        verbose => $args->{verbose},
    };
    $self->make_accessors($base_methods_hr);

    # Log init
    # Can't do before we know the application config path
    my $log_fqn = catfile( $configpath, 'etc/log.conf' );
    Log::Log4perl->init($log_fqn);
    # Log::Log4perl::Appender->new(
    #     "Log::Log4perl::Appender::File",
    #     name      => "Logfile",
    #     filename  => "/tmp/my.log");

    $self->{_log} = get_logger();
    $self->{_log}->info('-------------------------');
    $self->{_log}->info('*** NEW SESSION BEGIN ***');

    print "Loading configuration files ...\n" if $self->verbose;

    # Main config file name, load
    my $main_fqn = catfile( $configpath, $args->{cfgmain} );
    # $self->{_log}->info("Loading 'main' config");
    # $self->{_log}->info("file: $main_fqn");

    my $maincfg = $self->config_file_load($main_fqn);

    # FIXIT: Refactor
    my $main_hr = {
        cfgeom    => $maincfg->{geometry},
        cfiface   => $maincfg->{interface},
        cfapp     => $maincfg->{application},
        cfgen     => $maincfg->{general},
        cfrun     => $maincfg->{runtime},
        widgetset => $maincfg->{widgetset},      # Wx or Tk
        cfextapps => $maincfg->{externalapps},
        cfico     => catdir( $configpath, $maincfg->{resource}{icons} ),
    };

    # Setup when GUI runtime
    if ( $args->{cfname} ) {
        $main_hr->{cfname} = $args->{cfname};
    }

    my @accessor = keys %{$main_hr};
    $self->{_log}->trace("Making accessors for: @accessor");

    $self->make_accessors($main_hr);

    $self->{_log}->info("Loading 'main' config ... done");

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

        $self->{_log}->info("Loading '$section' config");
        $self->{_log}->info("file: $cfg_file");

        my $cfg_hr = $self->config_file_load($cfg_file);

        my @accessor = keys %{$cfg_hr};
        $self->{_log}->info("Making accessors for: @accessor");

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

    my $cf_name = $self->cfname;

    # Check early if the config dir for the application exists and
    # populate with defaults if not.
    if ( !-d $self->configdir ) {
        $self->configdir_populate($cf_name);
    }

    foreach my $section ( keys %{ $self->cfapp } ) {
        my $cfg_file = $self->config_app_file_name($section);

        $self->{_log}->info("Loading '$section' config");
        $self->{_log}->info("file: $cfg_file");

        my $cfg_hr = $self->config_file_load($cfg_file);

        my @accessor = keys %{$cfg_hr};
        $self->{_log}->info("runtime: Making accessors for: @accessor");

        $self->make_accessors($cfg_hr);
    }

    return;
}

=head2 config_iface_file_name

Return fully qualified application interface configuration file name.

=cut

sub config_iface_file_name {
    my ( $self, $section ) = @_;

    return catfile( $self->cfpath, $self->cfiface->{$section} );
}

=head2 config_app_file_name

Return fully qualified application configuration file name.

=cut

sub config_app_file_name {
    my ( $self, $section ) = @_;

    my $fl = catfile( $self->configdir, $self->cfapp->{$section} );

    return $fl;
}

=head2 config_file_name

Return full path to connection file.

=cut

sub config_file_name {
    my ( $self, $cfg_name ) = @_;

    return catfile( $self->configdir($cfg_name), $self->cfapp->{conninfo} );
}

=head2 list_configs

List all existing connection configurations or the one supplied on the
command line, with details.

TODO Simplify this!

=cut

sub list_configs {
    my ( $self, $cfg_name_param ) = @_;

    $cfg_name_param ||= q{};    # default empty

    my $cfpath = $self->cfapps;
    my $conlst = Tpda3::Config::Utils->find_subdirs($cfpath);

    my $cc_no = scalar @{$conlst};
    if ( $cc_no == 0 ) {
        print "Configurations: none\n";
        print " in '$cfpath':\n";
        return;
    }

    # Detailed list for config name
    if ($cfg_name_param) {
        if ( grep { $cfg_name_param eq $_ } @{$conlst} ) {
            my $cfg_file = $self->config_file_name($cfg_name_param);
            print "Configuration:\n";
            print " > $cfg_name_param\n";
            $self->list_configs_details( $cfg_file, $cfpath );
            print " in '$cfpath':\n";
            return;
        }
        else {
            print "Unknown configuration name: $cfg_name_param\n";
            return;
        }
    }
    else {

        # List all if connection file exists
        print "Configurations:\n";
        foreach my $cfg_name ( @{$conlst} ) {
            my $cfg_file = $self->config_file_name($cfg_name);
            if ( -f $cfg_file ) {
                print " > $cfg_name\n";
            }
        }
        print " in '$cfpath':\n";
    }

    return;
}

=head2 list_configs_details

Print configuration details.

=cut

sub list_configs_details {
    my ( $self, $cfg_file ) = @_;

    my $cfg_hr = $self->config_file_load($cfg_file);

    while ( my ( $key, $value ) = each( %{ $cfg_hr->{connection} } ) ) {
        print sprintf( "%*s", 10, $key ), ' = ';
        print $value if defined $value;
        print "\n";
    }

    return;
}

=head2 config_save_instance

Save instance configurations.  Only window geometry configuration for
now.

=cut

sub config_save_instance {
    my ( $self, $key, $value ) = @_;

    my $inst = $self->cfrun->{instance};

    my $inst_fqn = catfile( $self->configdir, $inst );

    Tpda3::Config::Utils->save_yaml( $inst_fqn, $key, $value );

    return;
}

=head2 config_load_instance

Load instance configurations.  User window geometry configuration.

=cut

sub config_load_instance {
    my $self = shift;

    my $inst = $self->cfrun->{instance};

    my $inst_fqn = catfile( $self->configdir, $inst );

    my $cfg_hr = $self->config_file_load($inst_fqn, 'notfatal');

    $self->make_accessors($cfg_hr);

    return;
}

=head2 config_init

Create new connection configuration directory and install
configuration file(s) from defaults found in the application's
I<share> directory.

It won't overwrite an existing directory.

=cut

sub config_init {
    my ( $self, $cfname, $new_cfname ) = @_;

    my $cfg_file = $self->config_file_name($new_cfname);
    if ( -f $cfg_file ) {
        print "Connection configuration exists, can't overwrite.\n";
        print " > $new_cfname\n";
        return;
    }
    else {
        print "Creating new configs '$new_cfname' .. ";
    }

    $self->configdir_populate( $cfname, $new_cfname );

    print "done.\n";

    return;
}

=head2 configdir

Return application configuration directory.

=cut

sub configdir {
    my ( $self, $cfname ) = @_;

    $cfname ||= $self->cfname;

    return catdir( $self->cfapps, $cfname );
}

=head2 sharedir

Returns the share directory for the current application configuration.

=cut

sub sharedir {
    my ( $self, $cfname ) = @_;

    $cfname ||= $self->cfname;

    return catdir( dist_dir('Tpda3'), 'apps', $cfname );
}

=head2 configdir_populate

Copy configuration files to the application configuration paths.

The applications I<sharedir> is determined using the following
algorithm: L<Tpda3-> + upper case of the I<configname> if the
I<configname> contains digits or upper case first letter from the
I<configname> otherwise.

This is an workaround of the fact that applications have different
distribution names than the L<Tpda3> run time.

Ideally the share dirs for all the applications would be copied under
L<Tpda3/>, but there is no option (yet?) to do that using
L<Module::Install> or L<Module::Build>.

As a consequence the application names must have the name made like
this:

   Tpda3-Appname and the I<configname>: appname
 or
   Tpda3-APP2NAME and the I<configname>: app2name

=cut

sub configdir_populate {
    my ( $self, $cfname, $new_cfname ) = @_;

    my $configdir = $self->configdir($new_cfname);
    my $sharedir  = $self->sharedir($cfname);

    # Alternate share directory
    if ( !-d $sharedir ) {
        # Funny algorithm to get the distribution name :)
        my $distname = $cfname =~ m{\d} ? uc $cfname : ucfirst $cfname;
        $sharedir = dist_dir( 'Tpda3-' . $distname );
        $sharedir = catdir( $sharedir, 'apps', $cfname );
    }

    $self->{_log}->info("Config dir is '$configdir'");
    $self->{_log}->info("Share dir is '$sharedir'");

    # Stolen from File::UserConfig ;)
    File::Copy::Recursive::dircopy( $sharedir, $configdir )
        or ouch 'CfgInsErr', "Failed to copy user data to '$configdir'";

    return;
}

=head2 config_rep_path

Return reports path.

=cut

sub config_rep_path {
    my $self = shift;

    return catdir( $self->configdir, 'rep' );
}

=head2 config_rep_file

Return default screen report file name and path.

=cut

sub config_rep_file {
    my ($self, $rep_file) = @_;

    return catfile( $self->config_rep_path, $rep_file );
}

=head2 documents_path

Return Tex template documents base path.

=cut

sub config_tex_path {
    my $self = shift;

    return catdir( $self->configdir, 'tex' );
}

=head2 config_tex_model_path

Return TeX documents model path.

=cut

sub config_tex_model_path {
    my $self = shift;

    return catdir( $self->config_tex_path, 'model' );
}

=head2 config_tex_output_path

Return TeX documents output path.

=cut

sub config_tex_output_path {
    my $self = shift;

    return catdir( $self->config_tex_path, 'output' );
}

=head2 docspath

Default documents output path.

=cut

sub docs_path {
    my $self = shift;

    return $self->_cfrun->{docspath};
}

=head2 get_log_filename

Return a file name and path for logging.

=cut

sub get_log_filename {

    return catfile(File::HomeDir->my_data, 'tpda3.log');
}

=head2 config_file_load

Load a config file and return the Perl data structure.  It loads a
file in Config::General format or in YAML::Tiny format, depending on
the extension of the file.

=cut

sub config_file_load {
    my ( $self, $conf_file, $not_fatal ) = @_;

    # my $log = get_logger();
    if ( !-f $conf_file ) {
        print " $conf_file ... not found\n" if $self->verbose;
        if ($not_fatal) {
            return;
        }
        else {
            my $msg = 'Configuration error!';
            $msg .= $self->verbose ? '' : ", file not found:\n$conf_file";
            ouch 404, $msg;
        }
    }
    else {
        print " $conf_file ... found\n" if $self->verbose;
    }

    my $suf = ( fileparse( $conf_file, qr/\.[^.]*/x ) )[2];
    if ( $suf =~ m{conf} ) {
        return Tpda3::Config::Utils->load_conf($conf_file);
    }
    elsif ( $suf =~ m{yml} ) {
        return Tpda3::Config::Utils->load_yaml($conf_file);
    }
    else {
        ouch 'BadSuffix', "Config file: $conf_file has wrong suffix ($suf)";
    }

    return;
}

=head2 list_config_files

List screen configuration files.

=cut

sub list_config_files {
    my $self = shift;

    my $scrdir = catdir( $self->configdir, 'scr' );
    my $conlst = Tpda3::Config::Utils->find_files($scrdir);

    print "Screen configurations:\n";
    foreach my $cfg_name ( @{$conlst} ) {
        print " > $cfg_name\n";
    }
    print "\n";

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users . sourceforge . net> >>

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Config
