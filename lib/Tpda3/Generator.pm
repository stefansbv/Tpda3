package Tpda3::Generator;

# ABSTRACT: The document generator

use strict;
use warnings;

use IPC::System::Simple 1.17 qw(capture);
use List::MoreUtils qw(uniq);
use File::Basename;
use File::Which;
use Path::Tiny;
use Try::Tiny;
use Log::Log4perl qw(get_logger :levels);
use Template;
use Template::Context;

use Tpda3::Exceptions;
use Tpda3::Config;
use Tpda3::Utils;

sub new {
    my $type = shift;

    my $self = {
        _cfg => Tpda3::Config->instance(),
        _log => get_logger(),
    };

    bless( $self, $type );

    return $self;
}

sub _log {
    my $self = shift;

    return $self->{_log};
}

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

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
    $rec->{images_path} = path($output_path, 'images') . '/';
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

    return path( $output_path, qq{$model.tex} );
}

sub pdf_from_latex {
    my ($self, $tex_file, $docs_path, $suffix) = @_;

    my $pdflatex_exe;
    unless ( $pdflatex_exe = $self->find_pdflatex() ) {
        $self->_log->info(qq{pdfTeX (pdflatex) not found.});
        return;
    }

    my $output_path = $docs_path || $self->cfg->cfrun->{docsoutpath};

    Tpda3::Utils->check_file($tex_file);
    Tpda3::Utils->check_path($output_path);

    $self->_log->info(qq{Generating PDF from "$tex_file" in "$output_path"});

    my ( $name, $path, $ext ) = fileparse( $tex_file, qr/\Q.tex\E/ );
    foreach my $ext (qw{aux log pdf}) {
        my $temp_file = path( $output_path, qq{$name.$ext} );
        my $cnt = unlink $temp_file;
        if ( $cnt == 1 ) {
            $self->_log->info(qq{Removed temporary file: "$temp_file"});
        }
    }

    # Options for TeXLive
    #my @opts  = qw{-halt-on-error -no-shell-escape -interaction=batchmode};
    # Options for standard TeX
    my @opts  = qw{-halt-on-error -interaction=batchmode -file-line-error};
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

    my $output_pdf = path( $output_path, qq{$name.pdf} );

    # Rename with suffix
    if ($suffix) {
        my $new = path( $output_path, qq{$name-$suffix.pdf} );
        $output_pdf->move($new);
        $output_pdf = $new if $new->exists;
    }

    print "pdf: $output_pdf\n" if $self->cfg->verbose;

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

    my $template  = path($model_file)->slurp_utf8;
    my $context   = Template::Context->new(TRACE_VARS => 1);
    my $compiled  = $context->template(\$template) or die $context->error;
    my $variables = $compiled->variables;

    my @unique = uniq sort keys %{ $variables->{r} };

    return \@unique;
}

1;

=head1 SYNOPSIS

   use Tpda3::Generator;

   my $gen = Tpda3::Generator->new();

   my $tex_file = $gen->tex_from_template($record, $model, $output_path);

   my $pdf_file = $gen->pdf_from_latex($tex_file);

=head2 new

Constructor method.

=head2 _log

Return log instance variable.

=head2 cfg

Return configuration instance object.

=head2 tex_from_template

Generate LaTeX source from TT template.

=head2 pdf_from_latex

Generate PDF from LaTeX source using L<pdflatex>.  On success
L<pdflatex> returns 0.

Has a L<sufix> parameter.

=head2 find_pdflatex

Try to locate the pdflatex executable.

=head2 check_pdflatex

Check the pdflatex executable.

=head2 extract_tt_fields

Extract the field names from the TT template and return the list.

# Thanks to: Borodin
# http://stackoverflow.com/questions/16088203/perl-template-toolkit-how-get-list-of-variables-in-the-template

=cut
