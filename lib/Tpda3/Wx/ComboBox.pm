package Tpda3::Wx::ComboBox;

# ABSTRACT: A subclass of Wx::ComboBox

use strict;
use warnings;

use Wx qw ( wxCB_SORT wxTE_PROCESS_ENTER wxNOT_FOUND );
use Wx::Event qw(EVT_SET_FOCUS EVT_CHAR EVT_KEY_DOWN EVT_KEY_UP);

use base qw( Wx::ComboBox );


sub new {
    #my $class = shift;
    my ( $class, $parent, $id, $pos, $size, $style ) = @_;

    #my $self = $class->SUPER::new();
    my $self = $class->SUPER::new(
        $parent,
        $id || -1,
        q{},
        $pos  || [ -1, -1 ],
        $size || [ -1, -1 ],
        [],
        ( $style || 0 ) | wxCB_SORT | wxTE_PROCESS_ENTER
    );

    $self->{lookup} = {};

    return $self;
}

sub add_choices {
    my ($self, $choices) = @_;

    foreach my $choice ( @{$choices} ) {
        $self->{lookup}{ $choice->{-value} } = $choice->{-name};
    }

    unshift @{$choices}, { -name => '', -value => '' };

    $self->Clear();
    $self->Append($_->{-name}, $_->{-value}) foreach @{$choices};

    return;
}

sub set_selected {
    my ($self, $choice) = @_;

    $choice = q{} unless defined $choice; # allow undef as choice

    my $selection;
    if ( $choice and exists $self->{lookup}{$choice} ) {
        $selection = $self->{lookup}{$choice};
    }
    else {
        $selection = q{};
    }

    $self->SetStringSelection($selection);

    return;
}

sub get_selected {
    my $self = shift;

    my $selected = $self->GetSelection();
    my $value = $self->GetValue();

    if ($selected == wxNOT_FOUND) {
        return;
    }
    else {
        return $self->GetClientData($selected)
    }
}

1;

=head1 SYNOPSIS

    use Tpda3::Wx::ComboBox;
    ...

=head2 new

Constructor method.

=head1 ACKNOWLEDGEMENTS

Default paramaters handling inspired from Wx::Perl::ListView,
Copyright (c) 2007 Mattia Barbon

=cut
