package Tpda3::Generator;

use strict;
use warnings;

use IPC::System::Simple 1.17 qw(capture);
use File::Spec::Functions;
use File::Basename;
use File::Copy qw(mv);
use Template;
use Try::Tiny;
use Log::Log4perl qw(get_logger :levels);
use File::Which;
use Regexp::Common qw/balanced/;

require Tpda3::Exceptions;
require Tpda3::Config;
require Tpda3::Utils;

=head1 NAME

Tpda3::Generator - The Generator

=head1 VERSION

Version 0.82

=cut

our $VERSION = 0.82;

=head1 SYNOPSIS

   use Tpda3::Generator;

   my $gen = Tpda3::Generator->new();

   my $tex_file = $gen->tex_from_template($record, $model, $output_path);

   my $pdf_file = $gen->pdf_from_latex($tex_file);

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $type = shift;

    my $self = {
        _cfg => Tpda3::Config->instance(),
        _log => get_logger(),
    };

    bless( $self, $type );

    return $self;
}

=head2 _log

Return log instance variable.

=cut

sub _log {
    my $self = shift;

    return $self->{_log};
}

=head2 cfg

Return config instance variable.

=cut

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

=head2 tex_from_template

Generate LaTeX source from TT template.

=cut

sub tex_from_template {
    my ($self, $rec, $model_file, $output_path) = @_;

    Tpda3::Utils->check_file($model_file);
    Tpda3::Utils->check_path($output_path);

    my ($model, $path, $ext) = fileparse( $model_file, qr/\Q.tt\E/ );

    my $file_out = qq{$model.tex};

    $self->_log->info(qq{Generating "$model.tex" from "$model.tt"});

    my $cnt = unlink $file_out;
    if ($cnt == 1) {
        $self->_log->info(qq{Removed temporary file: "$file_out"});
    }

    my $tt = Template->new({
        ENCODING     => 'utf8',
        INCLUDE_PATH => './',
        OUTPUT_PATH  => $output_path,
        ABSOLUTE     => 1,
        RELATIVE     => 1,
        PLUGIN_BASE  => 'Tpda3::Template::Plugin',
    });

    # Add images path to the record
    # The trailing slash is requred by TeX
    $rec->{images_path} = catdir($output_path, 'images') . '/';
    $rec->{images_path} =~ s{\\}{/}g;        # for TeX on M$Windows

    #- Cleanup values and prepare for LaTeX, (translate '&' in '\&')

    foreach my $field ( keys %{$rec} ) {
        if (defined $rec->{$field}) {
            $rec->{$field} =~ s/^\s+//;
            $rec->{$field} =~ s/\s+$//;
            $rec->{$field} =~ s/[\n\r]/ /;
            $rec->{$field} =~ s/,(\w)/, $1/;
            $rec->{$field} =~ s/&/\\&/;
        }
    }

    try {
        $tt->process(
            $model_file, { r => $rec },
            $file_out, binmode => ':utf8'
        )
            || die $tt->error(), "\n";
    }
    catch {
        $self->_log->error('TT Error: ' . $tt->error );
        return;
    };

    return catfile($output_path, qq{$model.tex});
}

=head2 pdf_from_latex

Generate PDF from LaTeX source using L<pdflatex>.  On success
L<pdflatex> returns 0.

Has a L<sufix> parameter.

=cut

sub pdf_from_latex {
    my ($self, $tex_file, $docspath, $suffix) = @_;

    my $pdflatex_exe;
    unless ( $pdflatex_exe = $self->find_pdflatex() ) {
        $self->_log->info(qq{pdfTeX (pdflatex) not found.});
        return;
    }

    my $output_path = $docspath || $self->cfg->cfrun->{docspath};

    Tpda3::Utils->check_file($tex_file);
    Tpda3::Utils->check_path($output_path);

    $self->_log->info(qq{Generating PDF from "$tex_file" in "$output_path"});

    my ( $name, $path, $ext ) = fileparse( $tex_file, qr/\Q.tex\E/ );
    foreach my $ext (qw{aux log pdf}) {
        my $temp_file = catfile( $output_path, qq{$name.$ext} );
        my $cnt = unlink $temp_file;
        if ( $cnt == 1 ) {
            $self->_log->info(qq{Removed temporary file: "$temp_file"});
        }
    }

    # Options for TeXLive
    #my @opts  = qw{-halt-on-error -no-shell-escape -interaction=batchmode};
    # Options for standard TeX
    my @opts  = qw{-halt-on-error -interaction=batchmode};
    push @opts, qq{-output-directory="$output_path"};
    push @opts, qq{"$tex_file"};

    my $output = q{};
    try {
        # Not capture($pdflatex_exe, @opts), always use the shell!
        $output = capture("$pdflatex_exe @opts");
    }
    catch {
        print "EE: '$pdflatex_exe @opts': $_\n";
    }
    finally {
        print "OUTPUT: >$output<\n" if $self->cfg->verbose;
    };

    my $output_pdf = catfile($output_path, qq{$name.pdf});

    # Rename with suffix
    if ($suffix) {
        my $new = catfile($output_path, qq{$name-$suffix.pdf});
        if ( mv($output_pdf, $new) ) {
            $output_pdf = $new;
        }
    }

    return $output_pdf;
}

sub find_pdflatex {
    my $self = shift;

    # First check the config
    my $pdflatex_exe = $self->cfg->cfextapps->{latex}{exe_path};
    if ( $pdflatex_exe = $self->check_pdflatex($pdflatex_exe) ) {
        return $pdflatex_exe if $pdflatex_exe;
    }

    # Try the find it in the PATH
    my $pdflatex = 'pdflatex' . ( $^O eq 'MSWin32' ? '.exe' : '' );
    $pdflatex_exe = File::Which::which($pdflatex);
    if ( $pdflatex_exe = $self->check_pdflatex($pdflatex_exe) ) {
        return $pdflatex_exe if $pdflatex_exe;
    }

    return;
}

sub check_pdflatex {
    my ($self, $exe) = @_;

    return unless defined $exe and -f $exe;

    $exe = Win32::GetShortPathName($exe) if $^O eq 'MSWin32';

    my $output = q{};
    try { $output = capture("$exe -version") } catch { $exe = '' }

    return $exe;
}

sub extract_tt_fields {
    my ($self, $model_file) = @_;

    open my $file_fh, '<', $model_file
        or die "Can't open file ", $model_file, ": $!";

    my @unique = ();
    my %seen   = ();
    while ( my $line = <$file_fh> ) {
        my (@fields)
            = $line =~ /$RE{balanced}{-begin => "[%"}{-end => "%]"}/gms;

        next unless @fields;

        foreach my $field (@fields) {

            # Trim spaces
            $field =~ s/^\s+//;
            $field =~ s/\s+$//;

            # Clean
            $field =~ s/^\[%\-?\s+//g;
            $field =~ s/\s+\-?%\]$//g;
            $field =~ s/\s*(IF|ELSIF|ELSE|END)\s*//i;
            $field =~ s/\s*(==.+)\s*//i;
            $field =~ s/^r\.//;

            if ($field) {
                # Store unique name
                next if $seen{$field}++;
                push @unique, $field;
            }
        }
    }

    close $file_fh;

    return \@unique;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Generator

=head1 ACKNOWLEDGEMENTS

PerlMonks: ikegami (http://www.perlmonks.org/index.pl?node_id=766502)

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Suciu.

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

1;    # End of Tpda3::Generator
