package Tpda3::Observable;

# ABSTRACT: the observer patern implementation

use strict;
use warnings;

=head1 SYNOPSIS

    use Tpda3::Observable;

    sub new {
        my $class = shift;

        my $self = {
            _data1 => Tpda3::Observable->new(),
            _data2 => Tpda3::Observable->new(),
        };

        bless $self, $class;

        return $self;
    }

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $value ) = @_;

    my $self = {
        _data      => $value,
        _callbacks => {},
    };

    bless $self, $class;

    return $self;
}

=head2 add_callback

Add a callback

=cut

sub add_callback {
    my ( $self, $callback ) = @_;

    $self->{_callbacks}{$callback} = $callback;

    return $self;
}

=head2 del_callback

Delete a callback

=cut

sub del_callback {
    my ( $self, $callback ) = @_;

    delete $self->{_callbacks}{$callback};

    return $self;
}

=head2 _docallbacks

Run callbacks

=cut

sub _docallbacks {
    my $self = shift;

    foreach my $cb ( keys %{ $self->{_callbacks} } ) {
        $self->{_callbacks}{$cb}->( $self->{_data} );
    }

    return;
}

=head2 set

Set data value

=cut

sub set {
    my ( $self, $data ) = @_;

    $self->{_data} = $data;
    $self->_docallbacks();

    return;
}

=head2 get

Return data

=cut

sub get {
    my $self = shift;

    return $self->{_data};
}

=head2 unset

Set data to undef

=cut

sub unset {
    my $self = shift;

    $self->{_data} = undef;

    return $self;
}

1;

=head1 ACKNOWLEDGMENTS

From: Cipres::Registry::Observable
Author: Rutger Vos, 17/Aug/2006 13:57
        http://svn.sdsc.edu/repo/CIPRES/cipresdev/branches/guigen \
             /cipres/framework/perl/cipres/lib/Cipres/
Thank you!

Copyright: Rutger Vos, 2006
