package Tpda3::Wx::ComboCtrl;

use strict;
use warnings;

use Wx qw (wxTE_PROCESS_ENTER);
use base qw{Wx::ComboCtrl};

=head1 NAME

Tpda3::Wx::ComboCtrl - A subclass of Wx::ComboCtrl.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Wx::ComboCtrl;
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

    return $self;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Default paramaters handling inspired from Wx::Perl::ListView,
Copyright (c) 2007 Mattia Barbon

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1;    # End of Tpda3::Wx::ComboCtrl
