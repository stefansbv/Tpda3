package Tpda3::Template::Plugin::Words;

use strict;
use warnings;

use Template::Plugin;
use base qw( Template::Plugin );

use Tpda3::Nums2Words;

use vars qw($FILTER_NAME);
$FILTER_NAME = 'words';

sub new {
    my($self, $context, @args) = @_;

    my $name = $args[0] || $FILTER_NAME;
    $context->define_filter($name, \&words, 0);

    return $self;
}

sub words {
    return num2word($_[0]);
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

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Template::Plugin::Words
