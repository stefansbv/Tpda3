package Tpda3::Config::Utils;

use strict;
use warnings;
use Carp;

use Log::Log4perl qw(get_logger);
use File::Basename;
use File::Copy;
use File::Find::Rule;
use File::Path 2.07 qw( make_path );

use YAML::Tiny;
use Config::General;

=head1 NAME

Tpda3::Config::Utils - Utility functions for config paths and files

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Config::Utils;

    my $cu = Tpda3::Config::Utils->new();


=head1 METHODS

=head2 config_file_load

Load a config file and return the Perl data structure.  croak,
if can't read file.

It loads a file in Config::General format or in YAML::Tiny format,
depending on the extension of the file.

=cut

sub config_file_load {
    my ($self, $conf_file, $message) = @_;

    my $log = get_logger();

    if (! -f $conf_file) {
        if ($message) {
            print "$message";
            exit;
        }
        else {
            $log->info("No '$conf_file' yet");
            return;
        }
    }

    my $suf = ( fileparse($conf_file, qr/\.[^.]*/x) )[2];
    if ( $suf =~ m{conf} )  {
        return Tpda3::Config::Utils->load_conf($conf_file);
    }
    elsif ( $suf =~ m{yml} ) {
        return Tpda3::Config::Utils->load_yaml($conf_file);
    }
    else {
        croak("Config file: $conf_file has wrong suffix ($suf)");
    }

    return;
}

=head2 load_conf

Load a generic config file in Config::General format and return the
Perl data structure.

=cut

sub load_conf {
    my ( $self, $config_file ) = @_;

    my $conf = Config::General->new($config_file);

    my %config = $conf->getall;

    return \%config;
}

=head2 load_yaml

Use YAML::Tiny to load a YAML file and return as a Perl hash data
structure.

=cut

sub load_yaml {
    my ( $self, $yaml_file ) = @_;

    return YAML::Tiny::LoadFile( $yaml_file );
}

=head2 find_subdirs

Find subdirectories of a directory, not recursively

=cut

sub find_subdirs {
    my ($self, $dir) = @_;

    # Find all the sub directories of a given directory
    my $rule = File::Find::Rule->new
        ->mindepth(1)
        ->maxdepth(1);
    # Ignore git
    $rule->or(
        $rule->new
            ->directory
            ->name('.git')
            ->prune
            ->discard,
        $rule->new);

    my @subdirs = $rule->directory->in( $dir );

    my @dbs = map { basename($_); } @subdirs;

    return \@dbs;
}

=head2 save_yaml

Save a YAML config file

=cut

sub save_yaml {
    my ( $self, $yaml_file, $key, $value ) = @_;

    my $yaml;
    if (-f $yaml_file) {
        # Open file
        $yaml = YAML::Tiny->read($yaml_file);
    }
    else {
        # Create a new YAML file
        $yaml = YAML::Tiny->new;
    }

    $yaml->[0]->{geometry}{$key} = $value; # add new key => value

    # Save the file
    $yaml->write($yaml_file);

    return;
}

=head2 create_path

Create a new path or die.

=cut

sub create_path {
    my ( $self, $new_path ) = @_;

    make_path( $new_path, { error => \my $err } );
    if (@$err) {
        for my $diag (@$err) {
            my ( $file_err, $message ) = %{$diag};
            if ( $file_err eq '' ) {
                die "Error: $message\n";
            }
        }
    }

    return;
}

=head2 copy_files

Copy files or die.

=cut

sub copy_files {
    my ($self, $src_fqn, $dst_p) = @_;

    if ( !-f $src_fqn ) {
        print "\nSource not found:\n $src_fqn\n";
        print "\nBACKUP and remove the configurations path,\n";
        print " run again this command to recreate the configuration paths!\n";
        die;
    }
    if ( !-d $dst_p ) {
        print "Destination path not found:\n $dst_p\n";
        die;
    }

    copy( $src_fqn, $dst_p ) or die $!;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Tpda3::Config::Utils
