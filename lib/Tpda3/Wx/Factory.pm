package Tpda3::Wx::Factory;

# ABSTRACT: Factory

use base 'Wx::XmlSubclassFactory';

sub DESTROY { }    # work around another bug

sub Create {
    return $_[1]->new;
}

1;

=head1 ACKNOWLEDGEMENTS

The implementation of the Wx interface is heavily based on the work
of Mark Dootson.

The implementation of the localization code is based on the work of
David E. Wheeler.

Thank You!

=head1 COPYRIGHT AND LICENSE

Copyright: (c) 2003 Mattia Barbon

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
