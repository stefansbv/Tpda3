package Tpda3::Tk::Entry;

# ABSTRACT: Subclass of Tk::Entry

use strict;
use warnings;

use Tk;
use base qw(Tk::Entry);

Construct Tk::Widget 'MEntry';

sub ClassInit {
    my ( $class, $mw ) = @_;

    $class->SUPER::ClassInit($mw);

    $mw->bind( $class, '<KeyRelease>', sub { $mw->set_modified_record(); } );

    return;
}

1;

=head1 SYNOPSIS

Create new binding for the L<< <KeyRelease> >> event type.

    use Tpda3::Tk::Entry;

    my $entry = Entry->new();

=cut
