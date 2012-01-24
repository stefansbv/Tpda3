package Tpda3::Tree;

use strict;
use warnings;
use utf8;

use Tree::DAG_Node;
use base qw(Tree::DAG_Node);

my $expvar = {};                            # TODO: find better way...
our $colslist = [];

sub new {
    my ( $class, $options ) = @_;

    my $self = bless $class->SUPER::new();

    $self->attributes($options);

    $expvar = {};

    return $self;
}

sub set_header {
    my ($self, $args) = @_;

    $colslist = $args;

    return;
}

sub set_attributes {
    my ( $self, $field, $val ) = @_;

    $self->attributes->{$field} = $val if $val;

    return;
}

sub get_attributes {
    my ( $self, $field ) = @_;

    return $self->attributes->{$field};
}

=head2 by_name

Search node by name.

=cut

sub by_name {
    my ( $self, $name ) = @_;

    my @found = ();
    my $retvalue = wantarray ? 1 : 0;
    $self->walk_down({
        callback => sub {
            my $node = shift;
            if ( $node->name eq $name ) {
                push @found, $node;
                return $retvalue;
            }
            1;
        }
    });

    return wantarray ? @found : @found ? $found[0] : undef;
}

sub get_expand_data {
    my ( $self, $name ) = @_;

    $self->walk_down( { callback => \&process_node, _depth => 0 } );

    return $expvar;
}

sub process_node {
    my ($self, $options) = @_;

    return 1 if ! defined $self->name();

    my $depth = $options->{_depth};
    my $nodeidx = $self->get_attributes('idx');
    print ' ' x ($depth * 3);
    print $nodeidx ? $nodeidx : '', ' ', $self->name, "\n";

    if ($depth >= 2) {
        $self->add_detail_data();
    }

    return 1;
}

=head2 add_detail_data

Builds expandData variable for the TMSHR widget.

Limited to 3 levels deep.

TODO: Replace the switch with some kind of a loop.

=cut

sub add_detail_data {
    my ($self) = @_;

    my @vdata = (undef);                     # start with 1 element
    foreach my $field ( @{$colslist} ) {
        push @vdata, $self->get_attributes($field);
    }

    # Reversed list of ancestors indexes
    my @idxs = grep { defined $_ }
        map { $_->get_attributes('nr_crt') } $self->ancestors;

    my $depth_factor = scalar @idxs;
    my $mrow         = pop @idxs;

  SWITCH: {
        $depth_factor == 1 && do {
            $expvar->{$mrow}{tag} = 'detail';
            push @{ $expvar->{$mrow}{data} }, \@vdata;
            last SWITCH;
        };
        $depth_factor == 2 && do {
            my $row1 = pop @idxs;
            $expvar->{$mrow}{expandData}{$row1}{tag} = 'detail2';
            push @{ $expvar->{$mrow}{expandData}{$row1}{data} }, \@vdata;
            last SWITCH;
        };
        $depth_factor == 3 && do {
            my $row1 = pop @idxs;
            my $row2 = pop @idxs;
            $expvar->{$mrow}{expandData}{$row1}{expandData}{$row2}{tag}
                = 'detail3';
            push @{ $expvar->{$mrow}{expandData}{$row1}{expandData}{$row2}
                    {data} }, \@vdata;
            last SWITCH;
        };
        print "\$depth_factor is not equal with 1 or 2 or 3\n";
    }

    return;
}

sub clear_totals {
    my ( $self, $fields ) = @_;

    $self->walk_down({
        callback => sub {
            my $node = shift;
            if ( $node->daughters ) {
                foreach my $field ( @{$fields} ) {
                    $node->set_attributes( 'fact_val', 0 );
                }
            }
        }
    });
}

sub sum_up {
    my ( $self, $fields ) = @_;

    $self->walk_down({
        callbackback => sub {
            my $node = shift;
            return 1 unless $node->mother;
            foreach my $field ( @{$fields} ) {
                $node->mother->attributes->{$field}
                    += $node->attributes->{$field};
            }
        }
    });
}

sub print_wealth {
    my ( $self, $field ) = @_;

    $self->walk_down({
        callback => sub {
            my $node = shift;
            printf "%s%.15s\t facturat: %.2f\n",
                "  " x $_[0]->{_depth},
                    $node->name, $node->get_attributes($field);;
        },
        _depth => 0,
    });
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Heavily inspired from the I<Introduction to Tree::DAG_Node> article by
gmax, from: http://www.perlmonks.org/?node_id=153259

Thank You!

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Tree
