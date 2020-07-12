package Tpda3::Config::Screen::Details;

# ABSTRACT: Config details from the screen section

use Moo;
use MooX::HandlesVia;
use Tpda3::Types qw(
    HashRef
    Maybe
    Str
);
use Data::Dump qw/dump/;

has 'details' => (
    is       => 'ro',
    isa      => Maybe[HashRef|Str],
    required => 0,
);

sub has_details_screen {
    my $self = shift;
    my $name = $self->details;
    return if !defined $name;
    return 1 if ref $name eq 'HASH';
    return 1 if $name;
    return;
}

has '_detail' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    default     => sub {
        my $self     = shift;
        my $detail   = $self->details->{detail};
        my $new_href = {};
        if ( ref $detail eq 'ARRAY' ) {
            foreach my $hr ( @{$detail} ) {
                $new_href->{ $hr->{value} } = $hr->{name};
            }
        }
        if ( ref $detail eq 'HASH' ) {
            return { $detail->{value} => $detail->{name} };
        }
        return $new_href;
    },
    handles => {
        get_detail    => 'get',
        has_no_detail => 'is_empty',
    },
);

has 'filter' => (
    is      => 'ro',
    isa     => Maybe[Str],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->details->{filter};
    },
);

has 'default' => (
    is      => 'ro',
    isa     => Maybe[Str],
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $det  = $self->details;
        return if !defined $det;
        if ( ref $det eq 'HASH' ) {
            if (exists $det->{default}) {
                return $det->{default};
            }
            else {
                return;
            }
        }
        return $det if $det;
        return;
    },
);

has 'match' => (
    is      => 'ro',
    isa     => Maybe[Str],
    lazy    => 1,
    default => sub {
        my $self    = shift;
        return $self->details->{match};
    },
);

__PACKAGE__->meta->make_immutable;

1;

=head1 SYNOPSIS

=head2 screen_detail_name

Detail screen module name from screen configuration.

Configuration:

    details             = Cursuri

In this, simplest, case the C<Cursuri> screen detail name is constant.

or

    <details>
        match           = cod_tip
        filter          = id_act
        <detail>
            value       = CS
            name        = Cursuri
        </detail>
        <detail>
            value       = CT
            name        = Consult
        </detail>
    </details>

In this case the screen detail name is variable, it depends on the
value ...

=head2 get_sdn_name

Find the selected row in the TM. Read it and return the name of the
detail screen module to load.  If there is no name to match, return
C<default>.

The configuration is like this:

  {
      'detail' => [
          {
              'value' => 'CS',
              'name'  => 'Cursuri'
          },
          {
              'value' => 'CT',
              'name'  => 'Consult'
          }
      ],
      'filter'  => 'id_act',
      'match'   => 'cod_tip'
      'default' => 'ScreenName'
  };

It can also be a hash reference if there is only one detail screen in
the configuration:

      'detail' => {
          'value' => 'CS',
          'name'  => 'Cursuri'
      },

=cut
