package Tpda3::Wx::ComboDate;

use strict;
use warnings;

use Wx qw{wxTE_PROCESS_ENTER};
use Tpda3::Wx::DatePopup;
use base qw{Tpda3::Wx::ComboCtrl};

=head1 NAME

Tpda3::Wx::ComboDate - Tpda3::Wx::ComboCtrl with a Calendar popup.

=head1 VERSION

Version 0.57

=cut

our $VERSION = 0.57;

=head1 SYNOPSIS

    use Tpda3::Wx::ComboDate;
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
        ( $style || 0 ) | wxTE_PROCESS_ENTER
    );
    my $popup = Tpda3::Wx::DatePopup->new();
    $self->SetPopupControl( $popup );

    return $self;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Default parameters handling inspired from Wx::Perl::ListView,
Copyright (c) 2007 Mattia Barbon

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::ComboDate
