package Tpda3::Config;

use strict;
use warnings;
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

Version 0.60

=cut

our $VERSION = 0.60;

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

    $args->{cfgmain} = 'etc/main.yml';    # hardcoded main config file
    $args->{default} = 'etc/default.yml'; # and app default config file

    $self->init_configurations($args);

    # Load configuration and create accessors
    $self->config_main_load($args);
    if ( $args->{cfname} ) {

        # If no config name don't bother to load this
        $self->config_interfaces_load();

        # Application configs
        $self->config_application_load();
    }

    return $self;
}

=head2 init_configurations

Initialize basic configuration options.

=cut

sub init_configurations {
    my ( $self, $args ) = @_;

    my $configpath = File::UserConfig->new(
        dist     => 'Tpda3',
        sharedir => 'share',
    )->configdir;

    my $configpath_hr = {
        cfpath  => $configpath,
        cfapps  => catdir( $configpath, 'apps' ),
        cfetc   => catdir( $configpath, 'etc' ),
        user    => $args->{user}, # make accessors for user
        pass    => $args->{pass}, # and pass
        verbose => $args->{verbose},
        default => catfile( $configpath, $args->{default} ),
    };

    $self->make_accessors($configpath_hr);

    # Log init, can't do before we know the application config path
    my $log_fqn = catfile( $self->cfpath, 'etc/log.conf' );
    Log::Log4perl->init($log_fqn);

    # Fallback to the default cfname (mnemonic) from default.yml if
    # exists unless list or init argument provied on the CLI
    $args->{cfname} = $self->get_default_mnemonic()
        unless ( $args->{cfname}
        or defined $args->{list}
        or defined $args->{init} );

    $self->{_log} = get_logger();
    $self->{_log}->info('-------------------------');
    $self->{_log}->info('*** NEW SESSION BEGIN ***');

    return;
}

=head2 get_default_mnemonic

Set cfname (mnemonic) to the value read from the optional
L<default.yml> configuration file.

=cut

sub get_default_mnemonic {
    my $self = shift;

    my $defaultapp_fqn = $self->default();
    if (-f $defaultapp_fqn) {
        my $cfg_hr = $self->get_config_data($defaultapp_fqn);
        return $cfg_hr->{mnemonic};
    }
    else {
        $self->{_log}->info("No valid default found, using 'test-tk'");
        return 'test-tk';
    }
}

=head2 set_default_mnemonic

Save the default mnemonic in the configs.

=cut

sub set_default_mnemonic {
    my ($self, $arg) = @_;

    Tpda3::Config::Utils->save_default_yaml(
        $self->default, 'mnemonic', $arg );

    return;
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

    print "Loading configuration files ...\n" if $self->verbose;

    # Main config file name, load
    my $main_fqn = catfile( $self->cfpath, $args->{cfgmain} );

    my $maincfg = $self->config_load_file($main_fqn);

    my $main_hr = {
        cfgeom    => $maincfg->{geometry},
        cfiface   => $maincfg->{interface},
        cfrun     => $maincfg->{runtime},
        cfextapps => $maincfg->{externalapps},
        cfico     => catdir( $self->cfpath, $maincfg->{resource}{icons} ),
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

=head2 config_interfaces_load

Process the main configuration file and automaticaly load all the
interface defined configuration files.  That means if we add a YAML
configuration file to the tree, all defined values should be available
at restart.

=cut

sub config_interfaces_load {
    my $self = shift;

    foreach my $section ( keys %{ $self->cfiface } ) {
        my $cfg_file = $self->config_iface_file_name($section);
        $self->config_load($cfg_file);
    }

    return;
}

=head2 config_application_load

Load the application specific configuration files.  This are treated
separately because the path is only known at runtime.

=cut

sub config_application_load {
    my $self = shift;

    my $cf_name = $self->cfname;

    # Check early if the config dir for the application exists and
    # populate with defaults if doesn't.
    if ( !-d $self->configdir ) {
        $self->configdir_populate($cf_name);
    }

    my @cfg = (
        'application.yml',
        'connection.yml',
        'menu.yml',
        'toolbar.yml',
    );

    foreach my $section ( @cfg ) {
        my $cfg_file = catfile( $self->configdir, 'etc', $section );
        $self->config_load($cfg_file);
    }

    return;
}

=head2 config_load

Load configuration file and make accessors.

=cut

sub config_load {
    my ($self, $cfg_file) = @_;

    $self->{_log}->info("Loading file: $cfg_file");

    my $cfg_hr = $self->config_load_file($cfg_file);

    my @accessor = keys %{$cfg_hr};
    $self->{_log}->info("Making accessors for: @accessor");

    $self->make_accessors($cfg_hr);

    return;
}

=head2 config_iface_file_name

Return fully qualified application interface configuration file name.

=cut

sub config_iface_file_name {
    my ( $self, $section ) = @_;

    return catfile( $self->cfpath, $self->cfiface->{$section} );
}

=head2 config_file_name

Return full path to a configuration file.  Default is the connection
configuration file.

=cut

sub config_file_name {
    my ( $self, $cfg_name, $cfg_file ) = @_;

    $cfg_file ||= catfile('etc', 'connection.yml');

    return catfile( $self->configdir($cfg_name), $cfg_file);
}

=head2 list_mnemonics

List all existing connection configurations or the one supplied on the
command line, with details if required.

=cut

sub list_mnemonics {
    my ( $self, $mnemonic ) = @_;

    $mnemonic ||= q{};    # default empty

    if ($mnemonic) {
        $self->list_mnemonic_details_for($mnemonic);
        return;
    }

    # Print
    $self->list_mnemonics_all();

    return;
}

=head2 list_mnemonics_all

List all the configured mnemonics.

=cut

sub list_mnemonics_all {
    my $self = shift;

    my $mnemonics = $self->get_mnemonics();

    my $cc_no = scalar @{$mnemonics};
    if ( $cc_no == 0 ) {
        print "Configurations (mnemonics): none\n";
        print ' in ', $self->cfapps, "\n";
        return;
    }

    print "Configurations (mnemonics):\n";
    foreach my $cfg_name ( @{$mnemonics} ) {
        $self->get_default_mnemonic eq $cfg_name
            ? ( print " *> $cfg_name\n" )
            : ( print "  > $cfg_name\n" );
    }
    print ' in ', $self->cfapps, "\n";

    return;
}

=head2 list_mnemonic_details_for

List details about the configuration name (mnemonic) if exists.

=cut

sub list_mnemonic_details_for {
    my ($self, $mnemonic) = @_;

    my $conn_ref = $self->get_details_for($mnemonic);

    unless (scalar %{$conn_ref} ) {
        print "Configuration mnemonic '$mnemonic' not found!\n";
        return;
    }

    print "Configuration:\n";
    print "  > mnemonic: $mnemonic\n";
    while ( my ( $key, $value ) = each( %{ $conn_ref->{connection} } ) ) {
        print sprintf( "%*s", 11, $key ), ' = ';
        print $value if defined $value;
        print "\n";
    }
    print ' in ', $self->cfapps, "\n";

    return;
}

=head2 get_details_for

Return the connection configuration details.  Check the name and
return the reference only if the name matches.

=cut

sub get_details_for {
    my ($self, $mnemonic) = @_;

    my $conn_file = $self->config_file_name($mnemonic);
    my $conlst    = $self->get_mnemonics();

    my $conn_ref = {};
    if ( grep { $mnemonic eq $_ } @{$conlst} ) {
        my $cfg_file = $self->config_file_name($mnemonic);
        $conn_ref = $self->get_config_data($conn_file);
    }

    return $conn_ref;
}

=head2 get_mnemonics

Return the list of mnemonics - the subdirectory names of the L<apps>
path.

=cut

sub get_mnemonics {
    my $self = shift;

    my $list = Tpda3::Config::Utils->find_subdirs($self->cfapps);

    my @mnemonics;
    foreach my $cfg_name ( @{$list} ) {
        my $ccfn = $self->config_file_name($cfg_name);
        push @mnemonics, $cfg_name if -f $ccfn;
    }

    return \@mnemonics;
}

=head2 get_config_data

Return the connection configuration details directly from the YAML
file.

=cut

sub get_config_data {
    my ( $self, $cfg_file ) = @_;

    return $self->config_load_file($cfg_file);
}

=head2 instance_file

Return the absolute path to the instance.yaml configuration file.

=cut

sub instance_file {
    my $self = shift;

    return catfile( $self->configdir, 'etc', 'instance.yml' );
}

=head2 config_save_instance

Save instance configurations.  Only window geometry configuration.

=cut

sub config_save_instance {
    my ( $self, $key, $value ) = @_;

    Tpda3::Config::Utils->save_instance_yaml( $self->instance_file, $key,
        $value );

    return;
}

=head2 config_load_instance

Load instance configurations.  User window geometry configuration.

=cut

sub config_load_instance {
    my $self = shift;

    my $cfg_hr = $self->config_load_file( $self->instance_file, 'notfatal' );

    $self->make_accessors($cfg_hr);

    return;
}

=head2 toolbar_interface_reload

Reload toolbar.

=cut

sub toolbar_interface_reload {
    my $self = shift;

    my $cfg_file = $self->config_iface_file_name('toolbar');
    $self->config_load($cfg_file);

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

    print "Creating new configuration '$new_cfname'...\r";
    $self->configdir_populate( $cfname, $new_cfname );
    print "Creating new configuration '$new_cfname'... done\n\n";

    return;
}

=head2 configdir

Return application configuration directory.  The config name is an
optional parameter with default as the current application config
name.

=cut

sub configdir {
    my ( $self, $cfname ) = @_;

    $cfname ||= $self->cfname;

    return catdir( $self->cfapps, $cfname );
}

=head2 sharedir

Returns the share directory for the current application configuration.
The config name is an optional parameter with default as the current
application config name.

=cut

sub sharedir {
    my ( $self, $cfname ) = @_;

    $cfname ||= $self->cfname;

    return catdir( dist_dir('Tpda3'), 'apps', $cfname );
}

=head2 configdir_populate

Copy configuration files to the application configuration paths.

The applications I<sharedir> is determined using the following
algorithm: I<Tpda3-> + upper case of the I<configname> if the
I<configname> contains digits or upper case first letter from the
I<configname> otherwise.

This is an workaround of the fact that applications have different
distribution names than the I<Tpda3> run time.

Ideally the share dirs for all the applications would be copied under
I<Tpda3/>, but there is no option (yet?) to do that using
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

    $self->{_log}->info("Config: $configdir");
    $self->{_log}->info("Share : $sharedir");

    # Stolen from File::UserConfig ;)
    File::Copy::Recursive::dircopy( $sharedir, $configdir )
        or ouch 'CfgInsErr', "Failed to copy app user data to '$configdir'";

    return;
}

=head2 config_tex_path

Return TeX documents model or output path.

=cut

sub config_tex_path {
    my ($self, $what) = @_;

    my $path = catdir( $self->configdir, 'tex', $what );

    ouch 404, "Path not found: $path" unless -d $path;

    return $path;
}

=head2 docs_path

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

=head2 config_load_file

Load a config file and return the Perl data structure.  It loads a
file in Config::General format or in YAML::Tiny format, depending on
the extension of the file.

=cut

sub config_load_file {
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

    my $suf = ( fileparse( $conf_file, qr/\.[^.]*/ ) )[2];
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

=head2 config_scrdir

Return the screen configuration directory.

=cut

sub config_scrdir {
    my $self = shift;

    return catdir( $self->configdir, 'scr' );
}

=head2 config_scr_file_name

Return fully qualified screen configuration file name.

=cut

sub config_scr_file_name {
    my ( $self, $file_name ) = @_;

    # Check if has extension and add it if not
    my ( $name, $path, $type ) = fileparse( $file_name, qr/\.[^.]*/ );
    $file_name .= '.conf' unless $type; # defaults to .conf

    my $conf_fn = catfile( $self->config_scrdir, $file_name );

    if (-f $conf_fn) {
        return $conf_fn;
    }
    else {

        # Fallback to alternative location (tools)
        return catfile( $self->cfpath, 'scr', $file_name );
    }
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

=head2 config_misc_load

Load a config file from the etc dir of the application.

=cut

sub config_misc_load {
    my ($self, $config_file) = @_;

    my $cfg_file = catfile( $self->configdir, 'etc', $config_file );

    my $config_hr = $self->config_load_file($cfg_file);
    $self->make_accessors($config_hr);

    return $config_hr;                       # do we need this?
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Config
