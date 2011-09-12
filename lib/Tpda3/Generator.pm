package Tpda3::Generator;

use strict;
use warnings;

use IPC::Run3 qw( run3 );
use File::Spec::Functions;
use File::Basename;
use Template;

use Log::Log4perl qw(get_logger :levels);

use Tpda3::Config;

=head1 NAME

Tpda3::Generator - The Generator

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

   use Tpda3::Generator;

   my $gen = Tpda3::Generator->new();

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

Return log instance variable

=cut

sub _log {
    my $self = shift;

    return $self->{_log};
}

sub _cfg {
    my $self = shift;

    return $self->{_cfg};
}

sub tex_from_template {
    my ($self, $record, $model_file, $output_path) = @_;

    #-- Generate TeX

    $self->_log->info("Generating LaTeX from '$model_file'");

    my ($name, $path, $ext) = fileparse( $model_file, qr/\Q.tt\E/ );

    my $file_in   = $model_file;
    my $latex_src = "$name.tex";

    if ( !-f $file_in ) {
        print " $file_in NOT found\n";
        return;
    }

    print "File in  = $file_in\n";
    print "File out = $latex_src\n";

    my $cnt = unlink $latex_src;
    if ($cnt == 1) {
        print "Removed temp file: $latex_src\n";
    }

    my $tt = Template->new({
        ENCODING     => 'utf8',
        INCLUDE_PATH => './',
        OUTPUT_PATH  => $output_path,
        ABSOLUTE     => 1,
        RELATIVE     => 1,
    });

    # Cleanup values and prepare for LaTeX, (translate '&' in '\&')
    foreach my $field ( keys %{$record->[0]{data}} ) {
        if (defined $record->[0]{data}{$field}) {
            $record->[0]{data}{$field} =~ s/^\s+//;
            $record->[0]{data}{$field} =~ s/\s+$//;
            $record->[0]{data}{$field} =~ s/[\n\r]/ /;
            $record->[0]{data}{$field} =~ s/,(\w)/, $1/;
            $record->[0]{data}{$field} =~ s/&/\\&/;
        }
    }

    eval {
        $tt->process( $file_in, $record->[0]{data},
            $latex_src, binmode => ':utf8' );
    };
    if ($@) {
        print " Failed!\n";
    }

    my $tex_file = catfile($output_path, $latex_src);

    #-- Generate PDF

     $self->pdf_from_latex($tex_file);

    return;
}

sub pdf_from_latex {
    my ($self, $tex_file) = @_;

    if ( -f $tex_file ) {
        print "File in  = $tex_file\n";
    }
    else {
        print " $tex_file NOT found\n";
        return;
    }

    print " Generating pdf ...\n";

    my $pdflatex_exe = $self->_cfg->cfextapps->{pdflatex}{exe_path};
    my $pdflatex_opt = $self->_cfg->cfextapps->{pdflatex}{options};
    my $docspath     = $self->_cfg->cfrun->{docspath};

    $pdflatex_opt .= ' -output-directory=' . qq{"$docspath"};

    my $cmd = qq{"$pdflatex_exe" $pdflatex_opt "$tex_file"};
    print "cmd: $cmd\n";

    #-- From PerlMonks
    # http://www.perlmonks.org/index.pl?node_id=766502
    run3 $cmd, undef, \my @out, \my @err;

    # The output should be logged !!!
    print "STDOUT: $_" for @out;
    print "STDERR: $_" for @err;

    # PDF file path and name
    # Get file name from tex source fqn
    # my (undef, undef, $pdf_fn) = File::Spec->splitpath($tex_file);

    # $pdf_fn =~ s/\.tex$/\.pdf/g; # Change the extension
    # my $pdf_qn = catfile($outdir, $pdf_fn);

    # if ( -f $pdf_qn ) {
    #     print "File $pdf_qn generated.\n";
    #     $self->{tpda}{gui}->refresh_sb( 'll', "Out: $pdf_qn", 'blue' );
    # }
    # else {
    #     print " Error: $pdf_qn NOT found!\n";
    #     $self->{tpda}{gui}->refresh_sb( 'll', "Error!", 'red' );
    # }

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Generator

=head1 ACKNOWLEDGEMENTS

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

1;    # End of Tpda3::Generator
