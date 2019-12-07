package Tpda3::Tk::PhotoFrame;

# ABSTRACT: Create a frame widget for photos (pictures)

use 5.010;
use strict;
use warnings;

use Tk;
use Tk::Photo;
use Tk::PNG;
use Tk::JPEG;
use Tk::TIFF;

use base qw(Tk::Derived Tk::Canvas);

Construct Tk::Widget 'PhotoFrame';

our $foto;

sub ClassInit {
    my ( $class, $mw ) = @_;
    $foto = $mw->Photo();
    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my ( $self, $args ) = @_;

    $self->ConfigSpecs(
        -width              => [ qw(SELF width              Width              400   ) ],
        -height             => [ qw(SELF height             Height             100   ) ],
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

sub load_data {
    my ( $self, $stream ) = @_;
    die "load_image: parameter \$stream missing\n" unless $stream;
    $foto->blank;
    $foto->configure( -data => $stream );
    return 1;
}

sub load_image {
    my ( $self, $file ) = @_;
    die "load_image: parameter \$file missing\n" unless $file;
    $foto->blank;
    $foto->configure( -file => $file );
    return 1;
}

1;
