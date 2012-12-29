package Tpda3::Template::Plugin::Words;

use strict;
use warnings;

use Template::Plugin;
use base qw( Template::Plugin );

use Tpda3::Num2Words;

use vars qw($FILTER_NAME);
$FILTER_NAME = 'words';

=head1 NAME

Tpda3::Template::Plugin::Words  - A template plugin.

=head1 VERSION

Version 0.61

=cut

our $VERSION = 0.61;

=head1 SYNOPSIS

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my($self, $context, @args) = @_;

    my $name = $args[0] || $FILTER_NAME;
    $context->define_filter($name, \&words, 0);

    return $self;
}

=head2 words

Transform number in words.

=cut

sub words {
    return num2words($_[0]);
}

=head1 NAME

Tpda3::Template::Plugin::Words - TT Plugin to make words from numbers.

=head1 SYNOPSIS

  [% USE Words %]

  Prețul este de [% price %] ([% price | words %]) RON.

  # if price = 100,  output is:
  # Prețul este de 1000 (una sută) RON.

=head1 DESCRIPTION

Template::Plugin::Words is a plugin for TT, used to transform numbers
to words in templates.

=head1 ACKNOWLEDGEMENTS

Adapted from Template::Plugin::Comma module:

TT plugin implemented by Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Template::Plugin::Words
