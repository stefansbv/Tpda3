package Tpda3::Config;

# ABSTRACT: The Tpda3 application's configuration system

use strict;
use warnings;

use Log::Log4perl qw(get_logger :levels);
use File::Basename;
use File::HomeDir;
use File::ShareDir qw(dist_dir);
use File::UserConfig;
use File::Spec::Functions;
use File::Copy::Recursive ();
use List::Util qw(first);
use Try::Tiny;

require Tpda3::Utils;
require Tpda3::Config::Menu;
require Tpda3::Config::Toolbar;
require Tpda3::Config::Utils;

use base qw(Class::Singleton Class::Accessor);

sub _new_instance {
    my ( $class, $args ) = @_;

    my $self = bless {}, $class;

    $self->{_mb} = Tpda3::Config::Menu->new;
    $self->{_tb} = Tpda3::Config::Toolbar->new;

    $args->{cfgmain} = 'etc/main.yml';    # hardcoded main config file
    $args->{cfgdefa} = 'etc/default.yml'; # and app default config file

    print "Loading configuration files ...\n" if $args->{verbose};

    $self->init_configurations($args);

    # Load configuration and create accessors
    $self->config_main_load($args);

    # If no config name don't bother to load this
    if ( $args->{cfname} ) {
        $self->config_runtime_load();       # application configs
        $self->config_load_administrator(); # administrator configs
    }

    return $self;
}

sub init_configurations {
    my ( $self, $args ) = @_;

    my $configpath
        = $args->{cfpath}
        ? $args->{cfpath}
        : File::UserConfig->new(
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
        default => catfile( $configpath, $args->{cfgdefa} ),
    };

    $self->make_accessors($configpath_hr);

    # Check if conf tree is initialized
    my $main_conf = catfile( $self->cfpath, 'etc/main.yml' );
    unless ( -f $main_conf ) {
        die "Failed to initialize the configuration tree in:\n"
            . $self->cfpath;
    }

    # Log init, can't do before we know the application config path
    my $log_fqn = catfile( $self->cfpath, 'etc/log.conf' );
    Log::Log4perl->init($log_fqn) if -f $log_fqn;

    # Fallback to the default cfname (mnemonic) from default.yml if
    # exists unless list or init argument provied on the CLI

    $args->{cfname} = $self->get_default_mnemonic()
        unless ( $args->{cfname}
            or defined( $args->{list} )
            or defined( $args->{init} )
            or $args->{default} );

    my $mnemonic = $args->{cfname}
        ? q{ } x ( 17 - length( $args->{cfname} ) ) . $args->{cfname}
        : ( q{-} x 17 );

    $self->{_log} = get_logger();
    $self->{_log}->info('-------------------------');
    $self->{_log}->info('*** NEW SESSION BEGIN ***');
    $self->{_log}->info("*   $mnemonic   *");

    return;
}

sub get_default_mnemonic {
    my $self = shift;

    my $defaultapp_fqn = $self->default();
    if (-f $defaultapp_fqn) {
        my $cfg_hr = $self->config_data_from($defaultapp_fqn);
        if ($cfg_hr->{default}{mnemonic}) {
            return $cfg_hr->{default}{mnemonic};
        }
        else {
            return $self->pick_default_mnemonic(); # use as default
        }
    }
    else {
        return $self->pick_default_mnemonic(); # use as default
    }
}

sub pick_default_mnemonic {
    my $self = shift;

    my $mnemonics = $self->get_mnemonics();

    return $mnemonics->[0] if scalar @{$mnemonics} == 1; # one choice

    my @choices = grep { $_ !~ m{test\-(tk|wx)} } @{$mnemonics};

    return $choices[0] if scalar @choices == 1; # one other than test-*

    return 'test-tk';           # fallback to test-tk
}

sub set_default_mnemonic {
    my ($self, $mnemonic) = @_;

    #- Check

    my $mnemonics = $self->get_mnemonics();
    my $mnemonic_exist = first { $_ eq $mnemonic } @{$mnemonics};
    unless ($mnemonic_exist) {
        die "Mnemonic '$mnemonic' doesn't exists.\n";
    }
    unless ($self->validate_config($mnemonic)) {
        die "Invalid menmonic: $mnemonic\n";
    }

    #- Save

    print "Setting default to: '$mnemonic'...\r";
    my $data = {};
    $data->{default}{mnemonic} = $mnemonic;
    Tpda3::Utils->write_yaml( $self->default, $data );
    print "Setting default to: '$mnemonic'... done\n";

    return;
}

sub make_accessors {
    my ( $self, $cfg_hr ) = @_;

    __PACKAGE__->mk_accessors( keys %{$cfg_hr} );

    # Add data to object
    foreach my $name ( keys %{$cfg_hr} ) {
        $self->$name( $cfg_hr->{$name} );
    }

    return;
}

sub config_main_load {
    my ( $self, $args ) = @_;

    # Main config file name, load
    my $main_fqn = catfile( $self->cfpath, $args->{cfgmain} );
    my $maincfg = $self->config_data_from($main_fqn);

    my $main_hr = {
        cfmainyml => $main_fqn,
        cfrun     => $maincfg->{runtime},
        cfextapps => $maincfg->{externalapps},
        cfico     => catdir( $self->cfpath, $maincfg->{resource}{icons} ),
    };

    # Setup when GUI runtime
    $main_hr->{cfname} = $args->{cfname} if $args->{cfname};

    $self->make_accessors($main_hr);

    return $maincfg;
}

sub config_runtime_load {
    my $self = shift;

    my $cf_name = $self->cfname;

    # Check if the config dir for the application exists and populate
    # with defaults if doesn't.
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
        my $res_file    = $self->resource_path_for($section, 'etc');
        my $res_data_hr = $self->config_data_from($res_file);
        $self->make_accessors($res_data_hr);
    }

    return;
}

sub validate_config {
    my ( $self, $cfname ) = @_;

    my $cfg_file
        = catfile( $self->configdir($cfname), 'etc', 'application.yml' );
    my $cfg_href = $self->config_data_from($cfg_file);

    my $widgetset   = $cfg_href->{application}{widgetset};
    my $module_name = $cfg_href->{application}{module};

    my $module_class = $self->application_class( $widgetset, $module_name );
    ( my $module_file = "$module_class.pm" ) =~ s{::}{/}g;

    eval { require $module_file };

    return $@ ? 0 : 1;
}

sub config_file_name {
    my ( $self, $cfg_name, $cfg_file ) = @_;

    $cfg_file ||= catfile('etc', 'connection.yml');

    return catfile( $self->configdir($cfg_name), $cfg_file);
}

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

sub list_mnemonics_all {
    my $self = shift;

    my $mnemonics = $self->get_mnemonics();

    my $cc_no = scalar @{$mnemonics};
    if ( $cc_no == 0 ) {
        print "Configurations (mnemonics): none\n";
        print ' in ', $self->cfapps, "\n";
        return;
    }

    my $default = $self->get_default_mnemonic() || q{};

    print "Configurations (mnemonics):\n";
    foreach my $name ( @{$mnemonics} ) {
        my $v = $self->validate_config($name) ? ' ' : '!';
        my $d = $default eq $name             ? '*' : ' ';
        print " ${d}>${v}$name\n";
    }

    print ' in ', $self->cfapps, "\n";

    return;
}

sub list_mnemonic_details_for {
    my ($self, $mnemonic) = @_;

    my $conn_ref = $self->get_details_for($mnemonic);

    unless (scalar %{$conn_ref} ) {
        print "Configuration mnemonic '$mnemonic' not found!\n";
        return;
    }

    my $v = $self->validate_config($mnemonic) ? 'v' : '!';

    print "Configuration ($v):\n";
    print "  > mnemonic: $mnemonic\n";
    foreach my $key (keys %{ $conn_ref->{connection} }) {
        my $value = $conn_ref->{connection}{$key};
        print sprintf( "%*s", 11, $key ), ' = ';
        print $value if defined $value;
        print "\n";
    }
    print ' in ', $self->cfapps, "\n";

    return;
}

sub get_details_for {
    my ($self, $mnemonic) = @_;

    my $conn_file = $self->config_file_name($mnemonic);
    my $conlst    = $self->get_mnemonics();

    my $conn_ref = {};
    if ( grep { $mnemonic eq $_ } @{$conlst} ) {
        my $cfg_file = $self->config_file_name($mnemonic);
        $conn_ref = $self->config_data_from($conn_file);
    }

    return $conn_ref;
}

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

sub instance_file {
    my $self = shift;
    return catfile( $self->configdir, 'etc', 'instance.yml' );
}

sub administrator_file {
    my $self = shift;
    return catfile( $self->configdir, 'etc', 'administrator.yml' );
}

sub config_save_instance {
    my ( $self, $key, $value ) = @_;
    my $data = {};
    try { $data = Tpda3::Utils->read_yaml( $self->instance_file ) }
    finally {
        $data->{geometry}{$key} = $value;
        Tpda3::Utils->write_yaml( $self->instance_file, $data );
    };
    return;
}

sub config_load_instance {
    my $self = shift;
    my $cfg_hr = $self->config_data_from( $self->instance_file, 'notfatal' );
    $self->make_accessors($cfg_hr);
    return;
}

sub config_load_administrator {
    my $self = shift;
    my $cfg_hr
        = $self->config_data_from( $self->administrator_file, 'notfatal' );
    $self->make_accessors($cfg_hr);
    return;
}

sub toolbar_interface_reload {
    my $self = shift;
    $self->{_tb} = Tpda3::Config::Toolbar->new;
    return;
}

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

sub configdir {
    my ( $self, $cfname ) = @_;

    $cfname ||= $self->cfname;

    return catdir( $self->cfapps, $cfname );
}

sub sharedir {
    my ( $self, $cfname ) = @_;
    $cfname ||= $self->cfname;
    return catdir( dist_dir('Tpda3'), 'apps', $cfname );
}

sub configdir_populate {
    my ( $self, $cfname, $new_cfname ) = @_;

    my $configdir = $self->configdir($new_cfname);
    my $sharedir  = $self->sharedir($cfname); # only for the Tpda3 Test app

    # Alternate share directory for independent app distributions
    unless ( -d $sharedir and $cfname) {
        foreach my $distname (uc $cfname, ucfirst $cfname) {
            print "Trying distname '$distname'\n" if $self->verbose;
            try   { $sharedir = dist_dir( 'Tpda3-' . $distname ); }
            catch { print "Fail: $_\n" if $self->verbose;         };
            $sharedir = catdir( $sharedir, 'apps', $cfname ) if -d $sharedir;
        }
    }

    # Fallback to the module source dir in CWD
    unless ( -d $sharedir ) {
        print "Fallback to share dir in CWD\n" if $self->verbose;
        $sharedir = catdir( 'share', 'apps', $cfname);
    }

    $self->{_log}->info("Config: $configdir");
    $self->{_log}->info("Share : $sharedir");

    # Stolen from File::UserConfig ;)
    File::Copy::Recursive::dircopy( $sharedir, $configdir )
          or die "Failed to copy user data from '$sharedir' to '$configdir'";

    return;
}

sub get_log_filename {

    return catfile(File::HomeDir->my_data, 'tpda3.log');
}

sub config_data_from {
    my ( $self, $conf_file, $not_fatal ) = @_;

    if ( !-f $conf_file ) {
        print " $conf_file ... not found\n" if $self->verbose;
        if ($not_fatal) {
            return;
        }
        else {
            my $msg = 'Configuration error!';
            $msg .= $self->verbose ? ", file not found:\n$conf_file" : "" ;
            die "[E] $msg";
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
        return Tpda3::Utils->read_yaml($conf_file);
    }
    else {
        die "Config file: $conf_file has wrong suffix ($suf)";
    }

    return;
}

sub config_scr_file_name {
    my ( $self, $file_name ) = @_;

    die "A Screen config name is required!" unless $file_name;

    # Check if has extension and add it if not
    my ( $name, $path, $type ) = fileparse( $file_name, qr/\.[^.]*/ );
    $file_name .= '.conf' unless $type; # defaults to .conf

    my $scr_file = $self->resource_path_for($file_name, 'scr');
    if (-f $scr_file) {
        return $scr_file;
    }
    else {

        # Fallback to alternative location (tools)
        return catfile( $self->cfpath, 'scr', $file_name );
    }
}

sub list_config_files {
    my $self = shift;

    my $scrdir = catdir( $self->configdir, 'scr' );
    my $conlst = Tpda3::Config::Utils->find_files($scrdir, 'conf');

    print "Screen configurations:\n";
    foreach my $cfg_name ( @{$conlst} ) {
        print " > $cfg_name\n";
    }
    print "\n";

    return;
}

sub application_class {
    my ( $self, $widgetset, $module ) = @_;

    $widgetset ||= $self->application->{widgetset};
    $module    ||= $self->application->{module};

    return qq{Tpda3::${widgetset}::App::${module}};
}

sub resource_path_for {
    my ($self, $name, @type) = @_;

    if ($name) {
        return catfile( $self->configdir, @type, $name );
    }
    else {
        return catdir( $self->configdir, @type );
    }
}

sub resource_data_for {
    my ($self, $file_name, $res_path) = @_;
    my $cfg_file = $self->resource_path_for($file_name, $res_path);
    return $self->config_data_from($cfg_file);
}

sub menubar {
    my $self = shift;
    return $self->{_mb};
}

sub toolbar {
    my $self = shift;
    return $self->{_tb};
}

=head1 SYNOPSIS

Reads configuration files in I<Config::General> format and create a
complex Perl data structure (HoH).  Then using I<Class::Accessor>,
automatically create methods from the keys of the hash.

    use Tpda3::Config;

    my $cfg = Tpda3::Config->instance($args); # first time init

    my $cfg = Tpda3::Config->instance(); # later, in other modules

=head2 _new_instance

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=head2 init_configurations

Initialize basic configuration options.

=head2 get_default_mnemonic

Set cfname (mnemonic) to the value read from the optional
L<default.yml> configuration file.

=head2 pick_default_mnemonic

Pick a default mnemonic. If there is only one, return it.  If there
remains only one after removing I<test-(wx|tk)> pick that. Fall back
to B<test-tk>.

TODO: Should popup a dialog for the user to let him select a mnemonic,
if there are too many choices.

=head2 set_default_mnemonic

Save the default mnemonic in the configs.

=head2 make_accessors

Automatically make accessors for the hash keys.

=head2 config_main_load

Initialize configuration variables from arguments, also initialize the
user configuration tree if not exists, with the I<File::UserConfig>
module.

Load the main configuration file and return a HoH data structure.

Make accessors.

=head2 config_runtime_load

Load the runtime specific configuration files. This are configurations
specific to the current application.

=head2 validate_config

Return I<true>, if the required Tpda3 application module is loadable
and I<false> if not.

=head2 config_file_name

Return full path to a configuration file.  Default is the connection
configuration file.

=head2 list_mnemonics

List all existing connection configurations or the one supplied on the
command line, with details if required.

=head2 list_mnemonics_all

List all the configured mnemonics.

=head2 list_mnemonic_details_for

List details about the configuration name (mnemonic) if exists.

=head2 get_details_for

Return the connection configuration details.  Check the name and
return the reference only if the name matches.

=head2 get_mnemonics

Return the list of mnemonics - the subdirectory names of the L<apps>
path.

=head2 instance_file

Return the absolute path to the instance.yaml configuration file.

=head2 administrator_file

Return the absolute path to the administrator.yaml configuration file.

=head2 config_save_instance

Save instance configurations.  Only window geometry configuration.

=head2 config_load_instance

Load instance configurations.  User window geometry configuration.
This configuration file is optional.

=head2 config_load_administrator

Load administrator configurations.  Disabled menu configurations, for
example for the Admin menu.  This configuration file is optional.

=head2 toolbar_interface_reload

Recreate the toolbar.

=head2 config_init

Create new connection configuration directory and install
configuration file(s) from defaults found in the application's
I<share> directory.

It won't overwrite an existing directory.

=head2 configdir

Return application configuration directory.  The config name is an
optional parameter with default as the current application config
name.

=head2 sharedir

Returns the share directory for the current application configuration.
The config name is an optional parameter with default as the current
application config name.

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

=head2 get_log_filename

Return a file name and path for logging.

=head2 config_data_from

Load a config file and return the Perl data structure.  It loads a
file in Config::General format or in YAML::Tiny format, depending on
the extension of the file.

=head2 config_scr_file_name

Return fully qualified screen configuration file name.

=head2 list_config_files

List screen configuration files.

=head2 application_class

Main application class name.

=head2 resource_path_for

Return the absolute path for a resource file or directory.  The
parameters are: resource name and type. Where type is a list of dirs.

=head2 resource_data_for

Return a configuration datastructure loaded from a .yaml or a .conf
file from a path in configdir.

=head2 menubar

Return the Tpda3::Config::Menu instance object.

=head2 toolbar

Return the Tpda3::Config::Toolbar instance object.

=cut
