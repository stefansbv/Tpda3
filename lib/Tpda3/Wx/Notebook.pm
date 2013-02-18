package Tpda3::Wx::Notebook;

use strict;
use warnings;

use Wx qw(:everything);    # TODO: Eventualy change this!
use Wx::AUI;

use base qw{Wx::AuiNotebook};

=head1 NAME

Tpda3::Wx::Notebook - Create a notebook

=head1 VERSION

Version 0.64

=cut

our $VERSION = 0.64;

=head1 SYNOPSIS

    use Tpda3::Wx::Notebook;

    $self->{_nb} = Tpda3::Wx::Notebook->new( $gui );

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $gui ) = @_;

    #- The Notebook

    my $self = $class->SUPER::new(
        $gui, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxAUI_NB_TAB_FIXED_WIDTH,
    );


    $self->{pages} = {
        0 => 'rec',
        1 => 'lst',
        2 => 'det',
    };

    $self->{nb_prev} = q{};
    $self->{nb_curr} = q{};

    return $self;
}

=head2 create_notebook_page

Create a notebook_panel and page.

=cut

sub create_notebook_page {
    my ( $self, $name, $label ) = @_;

    $self->{$name} = Wx::Panel->new(
        $self,
        -1,
        wxDefaultPosition,
        wxDefaultSize,
    );

    $self->AddPage( $self->{$name}, $label );

#    my $idx = $self->GetPageCount - 1;
#    $self->{pages}{$idx} = $name;            # store page idx => name

    return;
}

sub get_current {
    my $self = shift;

    my $idx = $self->GetSelection();

    return $self->{pages}{$idx};
}

sub set_nb_current {
    my ( $self, $page ) = @_;

    $self->{nb_prev} = $self->{nb_curr};    # previous tab name
    $self->{nb_curr} = $page;               # current tab name

    return;
}

sub page_widget {
    my ( $self, $page ) = @_;

    if ($page) {
        return $self->{$page};
    }
    else {
        return $self;
    }
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::Notebook
