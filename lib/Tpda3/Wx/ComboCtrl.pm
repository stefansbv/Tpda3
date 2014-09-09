package Tpda3::Wx::ComboCtrl;

# ABSTRACT: A subclass of Wx::ComboCtrl.

use strict;
use warnings;

use Wx qw (wxTE_PROCESS_ENTER);
use base qw{Wx::ComboCtrl};


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

1;

=head1 SYNOPSIS

    use Tpda3::Wx::ComboCtrl;
    ...

=head2 new

Constructor method.

=head1 ACKNOWLEDGEMENTS

Default paramaters handling inspired from Wx::Perl::ListView,
Copyright (c) 2007 Mattia Barbon

=cut
