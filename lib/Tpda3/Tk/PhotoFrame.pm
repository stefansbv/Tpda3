package Tpda3::Tk::PhotoFrame;

# ABSTRACT: Create a frame widget for photos (pictures)

use 5.010;
use strict;
use warnings;

use Tk;
use Tk::Photo;
#use Tk::PNG;
use Tk::JPEG;
#use Tk::TIFF;

use base qw(Tk::Derived Tk::Canvas);

Construct Tk::Widget 'PhotoFrame';

our $foto;

sub ClassInit {
    my ( $class, $mw ) = @_;
    $foto = $mw->Photo;
    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my ( $self, $args ) = @_;

    $self->ConfigSpecs(
        -width              => [ qw(SELF width              Width              320   ) ],
        -height             => [ qw(SELF height             Height             240   ) ],
        -relief             => [ qw(SELF relief             Relief             raised) ],
        -borderwidth        => [ qw(SELF borderWidth        BorderWidth        1     ) ],
        -highlightthickness => [ qw(SELF highlightThickness HighlightThickness 0     ) ],
        -takefocus          => [ qw(SELF takefocus          Takefocus          0     ) ],
        DEFAULT             => [ 'SELF' ],
    );

    $self->SUPER::Populate($args);

    $self->{iid} = $self->createImage(0, 0,
        -anchor => 'nw',
        -image  => $foto,
    );
}

sub write_data {
    my ( $self, $stream ) = @_;
    $stream //= '';
    $foto->blank;
    $foto->configure( -format => 'jpeg', -data => $stream ) if $stream;
    return 1;
}

sub read_data {
    return $foto->cget('-data');
}

sub write_image {
    my ( $self, $file ) = @_;
    $foto->blank;
    $foto->configure( -file => $file ) if $file;
    return 1;
}

sub get_photo {
    return $foto;
}

1;
