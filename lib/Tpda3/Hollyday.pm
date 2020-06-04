package Tpda3::Hollyday;

# ABSTRACT: Salariu holydays

use Moo;
use MooX::HandlesVia;
use Tpda3::Types qw(
    Int
    Path
);
use Tpda3::Utils;
use namespace::autoclean;

has 'year' => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has 'month' => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has 'hollyday_file' => (
    is       => 'ro',
    isa      => Path,
    required => 1,
    coerce   => 1,
);

has '_hollyday' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy    => 1,
    init_arg => undef,
    builder  => '_build_hollyday',
    handles  => {
        get_hollyday    => 'get',
        has_no_hollyday => 'is_empty',
        num_hollyday    => 'count',
        records         => 'kv',
    },
);

sub _build_hollyday {
    my $self = shift;
    my $hollyday_file = $self->hollyday_file->stringify;
    my $yaml  = Tpda3::Utils->read_yaml($hollyday_file);
    my $year  = $self->year;
    my $month = $self->month;
    if ($year && $month) {
        if ( exists $yaml->{$year}{$month} ) {
            return $yaml->{$year}{$month};
        }
        else {
            return {};
        }
    }
    else {
       return {};
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 NAME

Tpda3::Hollyday - Hollydays

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 C<year>

=head2 C<month>

=head2 C<config>

=head2 C<_hollyday>

=head1 METHODS
