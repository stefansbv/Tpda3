# Exemplu de BLOB

use 5.010;
use strict;
use warnings;

use File::Basename;
use MIME::Base64;

my $img_file  = shift;

usage() unless $img_file;

open my $img_fh, '<', $img_file
    or die "Can't open file ", $img_file, ": $!";
binmode $img_fh;

my ($infile, $buffer);
while ( my $bytes = read( $img_fh, $buffer, 1024 ) ) {
    $infile .= $buffer;
}
close $img_fh;

my $stream = encode_base64($infile);
my ( $name, $path, $ext ) = fileparse( $img_file, qr/\.[^\.]*/ );
my $data_file = "$name.data";
open my $out_fh, '>', $data_file
    or die "Can't open file ", $data_file, ": $!";
print {$out_fh} $stream;
close $out_fh;

print "Done!\n";

exit 0;

sub usage {
    print "$0 <image-file>\n";
    exit 0;
}
