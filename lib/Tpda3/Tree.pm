package Tpda3::Tree;

# ABSTRACT: A tree data structure

use strict;
use warnings;
use utf8;

use base qw(Tree::DAG_Node);

my @maindata;                  # TODO: find better way to collect data
my $expdata  = {};
my $colslist = [];


sub new {
    my ( $class, $options ) = @_;

    my $self = bless $class->SUPER::new();

    $self->attributes($options);

    $expdata = {};

    return $self;
}


sub set_header {
    my ($self, $args) = @_;

    $colslist = $args;

    return;
}


sub set_attributes {
    my ( $self, $field, $val ) = @_;

    $self->attributes->{$field} = qq{$val};

    return;
}


sub get_attributes {
    my ( $self, $field ) = @_;

    return $self->attributes->{$field};
}


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


sub get_tree_data {
    my ( $self, $name ) = @_;

    $self->walk_down( { callback => \&process_node, _depth => 0 } );

    return (\@maindata, $expdata);
}


sub process_node {
    my ($node, $options) = @_;

    return 1 if ! defined $node->name;

    my $depth = $options->{_depth};
    my $nodeidx = $node->get_attributes('idx');
    # print ' ' x ($depth * 3);
    # print $nodeidx ? $nodeidx : '', ' ', $node->name, "\n";

    if ($depth == 1) {
        $node->collect_main_data();
    }
    elsif ($depth >= 2) {
        $node->collect_detail_data();
    }
    else {
        # Ignore
    }

    return 1;
}


sub collect_main_data {
    my $node = shift;

    my $rec = {};
    foreach my $field ( @{$colslist} ) {
        $rec->{$field} = $node->get_attributes($field);
    }
    push @maindata, $rec;

    return;
}


sub collect_detail_data {
    my ($node) = @_;

    my @vdata = (undef);                     # start with 1 element
    foreach my $field ( @{$colslist} ) {
        push @vdata, $node->get_attributes($field);
    }

    # Reversed list of ancestors indexes
    my @idxs = grep { defined $_ }
        map { $_->get_attributes('nr_crt') } $node->ancestors;

    my $depth_factor = scalar @idxs;
    my $mrow         = pop @idxs;

  SWITCH: {
        $depth_factor == 1 && do {
            $expdata->{$mrow}{tag} = 'detail';
            push @{ $expdata->{$mrow}{data} }, \@vdata;
            last SWITCH;
        };
        $depth_factor == 2 && do {
            my $row1 = pop @idxs;
            $expdata->{$mrow}{expandData}{$row1}{tag} = 'detail2';
            push @{ $expdata->{$mrow}{expandData}{$row1}{data} }, \@vdata;
            last SWITCH;
        };
        $depth_factor == 3 && do {
            my $row1 = pop @idxs;
            my $row2 = pop @idxs;
            $expdata->{$mrow}{expandData}{$row1}{expandData}{$row2}{tag}
                = 'detail3';
            push @{ $expdata->{$mrow}{expandData}{$row1}{expandData}{$row2}
                    {data} }, \@vdata;
            last SWITCH;
        };
        print "depth: $depth_factor is not equal with 1 or 2 or 3\n";
    }

    return;
}


sub clear_totals {
    my ( $self, $fields, $numscale ) = @_;

    $self->walk_down({
        callback => sub {
            my ($node, $options) = @_;
            if ( $node->daughters ) {
                foreach my $field ( @{$fields} ) {
                    $node->set_attributes( $field, 0 );
                }
            }
            1;
        }
    });

    return;
}


sub format_numbers {
    my ( $self, $fields, $numscale ) = @_;

    $self->walk_down({
        callback => sub {
            my ($node, $options) = @_;
                foreach my $field ( @{$fields} ) {
                    my $cell_value = $node->get_attributes($field);
                    $node->set_attributes( $field,
                        sprintf( "%.${numscale}f", $cell_value ) );
                }
            1;
        }
    });

    return;
}


sub sum_up {
    my ( $self, $fields, $numscale ) = @_;

    $self->walk_down({
        callbackback => sub {
            my ($node, $options) = @_;
            if ($node->mother) {
                # print "processing ", $node->name, "\tof ",
                #     $node->mother->name, ' [', $options->{_depth},"]\n";
                #print Dumper( $node->mother->attributes );
            }
            return 1 unless $node->mother;
            foreach my $field ( @{$fields} ) {
                $node->mother->attributes->{$field}
                    += $node->attributes->{$field};
            }
            1;
        }
    });

    return;
}


sub print_wealth {
    my ( $self, $field ) = @_;

    $self->walk_down({
        callback => sub {
            my ($node, $options) = @_;
            printf "%s%.15s\t facturat: %s\n",
                "  " x $options->{_depth},
                    $node->name, $node->get_attributes($field);
        },
        _depth => 0,
    });

    return;
}

1;

=head1 SYNOPSIS

    use Tpda3::Tree;
    my $tree = Tpda3::Tree->new({});
    $tree->name('root');
    ...

=head2 new

Constructor method.

=head2 set_header

Initialize header data.

TODO: This should be integrated in the I<new> method (when I learn how).

=head2 set_attributes

Set node attributes.

=head2 get_attributes

Get node attributes.

=head2 by_name

Search node by name.

=head2 get_tree_data

Return tree data.

=head2 process_node

Gather attributes data from each node.

=head2 collect_main_data

Return data from depth level 1 from the tree attributes.

=head2 collect_detail_data

Return data from depth level > 1 from the tree attributes.

Builds expandData variable for the TMSHR widget.

Limited to 3 levels deep.

TODO: Replace the switch with some kind of a loop for arbitrary depth
level.

=head2 clear_totals

Clear totals.  The fields are those configured with I<=sumup> value in
the I<datasource> section.

=head2 format_numbers

Traverse once again the tree and format the columns configured with
I<=sumup> value in the I<datasource> section.

Have to do the formatting after sum, because the format is not
preserved when summing up.

=head2 sum_up

Calculate sum.  The fields are those configured with I<=sumup> value
in the I<datasource> section.

=head2 print_wealth

Debug method.

=head1 ACKNOWLEDGEMENTS

Heavily inspired from the I<Introduction to Tree::DAG_Node> article by
gmax, from: http://www.perlmonks.org/?node_id=153259

Thank You!

=cut
