package Tpda3::Wx::Notebook;

use strict;
use warnings;

use Wx qw(:everything);    # TODO: Eventualy change this!
use Wx::AUI;

use base qw{Wx::AuiNotebook};

=head1 NAME

Tpda3::Wx::Notebook - Create a notebook

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

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

    return $self;
}

=head2 create_notebook_page

Create a notebook_panel and page.

=cut

sub create_notebook_page {
    my ( $self, $name, $label ) = @_;

    $self->{$name}
        = Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize, );

    $self->AddPage( $self->{$name}, $label );

    my $idx = $self->GetPageCount - 1;

    $self->{pages}{$idx} = $name;            # store page idx => name

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

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::Notebook
