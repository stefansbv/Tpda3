package Tpda3::Config::Utils;

use strict;
use warnings;

use Log::Log4perl qw(get_logger);
use File::Basename;
use File::Copy;
use File::Find::Rule;
use File::Path qw( make_path );
use File::ShareDir qw(dist_dir);
use File::Slurp;
use File::Spec::Functions;
use Try::Tiny;
use YAML::Tiny;
use Config::General;

=head1 NAME

Tpda3::Config::Utils - Utility functions for config paths and files

=head1 VERSION

Version 0.89

=cut

our $VERSION = 0.89;

=head1 SYNOPSIS

    use Tpda3::Config::Utils;

    my $cu = Tpda3::Config::Utils->new();

=head1 METHODS

=head2 load_conf

Load a generic config file in Config::General format and return the
Perl data structure.

=cut

sub load_conf {
    my ( $self, $config_file ) = @_;

    my $conf = Config::General->new(
        -UTF8       => 1,
        -ForceArray => 1,
        -ConfigFile => $config_file,
    );

    my %config = $conf->getall;

    return \%config;
}

=head2 load_yaml

Use YAML::Tiny to load a YAML file and return as a Perl hash data
structure.

=cut

sub load_yaml {
    my ( $self, $yaml_file ) = @_;

    my $conf;
    try {
        $conf = YAML::Tiny::LoadFile($yaml_file);
    }
    catch {
        my $msg = YAML::Tiny->errstr;
        die " but failed to load because:\n $msg\n";
    };

    return $conf;
}

=head2 find_subdirs

Find subdirectories of a directory, not recursively

=cut

sub find_subdirs {
    my ( $self, $dir ) = @_;

    my $rule = File::Find::Rule->new->mindepth(1)->maxdepth(1);
    $rule->or( $rule->new->directory->name('.git')->prune->discard,
        $rule->new );    # ignore git

    my @subdirs = $rule->directory->in($dir);

    my @dbs = map { basename($_); } @subdirs;

    return \@dbs;
}

=head2 find_files

Find files in directory at depth 1, not recursively.

=cut

sub find_files {
    my ( $self, $dir ) = @_;

    my $rule = File::Find::Rule->new->mindepth(1)->maxdepth(1);
    $rule->or( $rule->new->directory->name('.git')->prune->discard,
        $rule->new );    # ignore git

    my @files = $rule->file->in($dir);

    my @justnames = map { basename($_); } @files;

    return \@justnames;
}

=head2 save_yaml

Read a YAML file or create a new one if it doesn't exists. Alter the
data structure using the provided parameters. Save the YAML file.

For deeper nested data structures the B<value> parameter can be a hash
reference.

=cut

sub save_yaml {
    my ( $self, $yaml_file, $section, $key, $value ) = @_;

    my $yaml
        = ( -f $yaml_file )
        ? YAML::Tiny->read($yaml_file)
        : YAML::Tiny->new;

    $yaml->[0]->{$section}{$key} = $value;

    $yaml->write($yaml_file);

    print "'$yaml_file' created.\n";

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
    my ( $self, $src_fqn, $dst_p ) = @_;

    if ( !-f $src_fqn ) {
        print "\nSource not found:\n $src_fqn\n";
        print "\nBACKUP and remove the configurations path,\n";
        print
            " run again this command to recreate the configuration paths!\n";
        die;
    }
    if ( !-d $dst_p ) {
        print "Destination path not found:\n $dst_p\n";
        die;
    }

    copy( $src_fqn, $dst_p ) or die $!;
}


=head2 get_license

Slurp license file and return the text string.  Return only the title
if the license file is not found, just to be on the save side.

=cut

sub get_license {
    my $self = shift;

    my $message = <<'END_LICENSE';

                      GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

END_LICENSE

    my $license = catfile( dist_dir('Tpda3'), 'license', 'gpl.txt' );

    if (-f $license) {
        return read_file($license);
    }
    else {
        return $message;
    }
}

=head2 get_doc_file_by_name

Return document file full path.

=cut

sub get_doc_file_by_name {
    my ($self, $doc_file) = @_;

    return catfile( dist_dir('Tpda3'), 'doc', $doc_file);
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Config::Utils
