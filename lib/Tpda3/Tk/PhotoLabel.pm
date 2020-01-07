package Tpda3::Tk::PhotoLabel;

# ABSTRACT: Create a frame widget for photos (pictures)

use 5.010;
use strict;
use warnings;

use Tk;
use Tk::Photo;
#use Tk::PNG;
use Tk::JPEG;
#use Tk::TIFF;

use base qw(Tk::Derived Tk::Label);

Construct Tk::Widget 'PhotoLabel';

our $image;

sub ClassInit {
    my ( $class, $mw ) = @_;
    $image = $mw->Photo( -format => 'jpeg' );
    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my ( $self, $args ) = @_;
    $self->SUPER::Populate($args);
    $self->ConfigSpecs(
        -image      => [qw(SELF Image  image), $image ],
        -width      => [qw(SELF Width  width   320   )],
        -height     => [qw(SELF Height height  240   )],
        -relief     => [qw(SELF Relief relief  raised)],
        -background => [qw(SELF Background background)],
        'DEFAULT'   => ['SELF'],
    );
}

sub write_data {
    my ( $self, $stream ) = @_;
    $stream //= '';
    $image->blank;
    $image->configure( -data => $stream ) if $stream;
    return 1;
}

sub read_data {
    return $image->cget('-data');
}

sub write_image {
    my ( $self, $file ) = @_;
    $image->blank;
    $image->configure( -file => $file ) if $file;
    return 1;
}

sub get_photo {
    return $image;
}

1;
