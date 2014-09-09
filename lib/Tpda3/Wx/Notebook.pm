package Tpda3::Wx::Notebook;

# ABSTRACT: Create a notebook

use strict;
use warnings;

use Wx qw(:everything);    # TODO: Eventualy change this!
use Wx::AUI;

use base qw{Wx::AuiNotebook};


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

1;

=head1 SYNOPSIS

    use Tpda3::Wx::Notebook;

    $self->{_nb} = Tpda3::Wx::Notebook->new( $gui );

=head2 new

Constructor method.

=head2 create_notebook_page

Create a notebook_panel and page.

=cut
