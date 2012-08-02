package Tpda3::Wx::ComboBox;

use strict;
use warnings;

use Wx qw (wxCB_SORT wxTE_PROCESS_ENTER wxNOT_FOUND);
use base qw{Wx::ComboBox};
use Wx::Event qw(EVT_SET_FOCUS EVT_CHAR EVT_KEY_DOWN EVT_KEY_UP);

=head1 NAME

Tpda3::Wx::ComboBox - A subclass of Wx::ComboBox.

=head1 VERSION

Version 0.57

=cut

our $VERSION = 0.57;

=head1 SYNOPSIS

    use Tpda3::Wx::ComboBox;
    ...

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $parent, $id, $pos, $size, $style ) = @_;

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

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Default paramaters handling inspired from Wx::Perl::ListView,
Copyright (c) 2007 Mattia Barbon

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::ComboBox
