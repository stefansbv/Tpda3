package TpdaMvc::Config;

use strict;
use warnings;

use Data::Dumper;

use File::HomeDir;
use File::UserConfig;
use File::Spec::Functions;

use TpdaMvc::Config::Utils;

use base qw(Class::Singleton Class::Accessor);

=head1 NAME

TpdaMvc::Config - Tpda Tpda configuration module

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';


=head1 SYNOPSIS

Reads configuration files in I<Config::General> format and create a
complex Perl data structure (HoH).  Then using I<Class::Accessor>,
automatically create methods from the keys of the hash.

    use TpdaMvc::Config;

    my $cfg = TpdaMvc::Config->instance($args); # first time init

    my $cfg = TpdaMvc::Config->instance(); # later, in other modules


=head1 METHODS

=head2 _new_instance

Constructor method, the first and only time a new instance is created.
All parameters passed to the instance() method are forwarded to this
method. (From I<Class::Singleton> docs).

=cut

sub _new_instance {
    my ($class, $args) = @_;

    my $self = bless {}, $class;

    $args->{cfgmain} = 'etc/main.conf'; # hardcoded main config file name

    # Load configuration and create accessors
    $self->_config_main_load($args);

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
}

=head2 _config_main_load

Initialize configuration variables from arguments, also initialize the
user configuration tree if not exists, with the I<File::UserConfig>
module.

Load the main configuration file and return a HoH data structure.

Make accessors.

=cut

sub _config_main_load {
    my ( $self, $args ) = @_;

    my $configpath = File::UserConfig->new(
        dist     => 'tpda-mvc',
        sharedir => 'share',
    )->configdir;

    # Main config file name, load
    my $main_qfn = catfile( $configpath, $args->{cfgmain} );

    my $msg = qq{\nConfiguration error: \n Can't read 'main.conf'};
    $msg   .= qq{\n  from '$main_qfn'!};
    my $maincfg = $self->_config_file_load($main_qfn, $msg);

    print Dumper( $maincfg );
    $self->_make_accessors($maincfg);

    return $maincfg;
}

=head2 _config_file_load

Load a generic config file and return the Perl data structure.  Die,
if can't read file.

=cut

sub _config_file_load {
    my ($self, $conf_file, $message) = @_;

    print "Config file: $conf_file\n";
    if (! -f $conf_file) {
        print "$message\n";
        die;
    }

    return TpdaMvc::Config::Utils->load($conf_file);
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

1; # End of TpdaMvc::Config
