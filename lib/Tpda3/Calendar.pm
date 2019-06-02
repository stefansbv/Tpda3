package Tpda3::Calendar;

# ABSTRACT: Calendar

use utf8;
use 5.010001;
use Moose;
use MooseX::Types::Path::Tiny qw(File);
use Time::Moment;
use namespace::autoclean;

use Tpda3::Hollyday;

has 'year' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    default  => sub {
        my $tm     = Time::Moment->now;
        my $tm_new = $tm->minus_months(1);
        return $tm_new->year;
    },
);

has 'month' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    default  => sub {
        my $tm     = Time::Moment->now;
        my $tm_new = $tm->minus_months(1);
        return $tm_new->month;
    },
);

has 'config' => (
    is       => 'ro',
    isa      => 'Tpda3::Config',
    required => 0,
);

has 'hollyday_file' => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
    default  => sub {
        my $self = shift;
        return $self->config->resource_path_for( 'sarbatori.yml', 'res' );
    },
);

has 'hollyday' => (
    is      => 'ro',
    isa     => 'Tpda3::Hollyday',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Tpda3::Hollyday->new(
            year          => $self->year,
            month         => $self->month,
            hollyday_file => $self->hollyday_file,
        );
    },
);

has 'first_day_week_day' => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_first_day_week_day',
);

sub _build_first_day_week_day {
    my $self = shift;
    my $tm   = Time::Moment->new(
        year  => $self->year,
        month => $self->month,
        day   => 1,
    );
    return $tm->day_of_week;
}

has 'last_day' => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_last_day',
);

sub _build_last_day {
    my $self = shift;
    my $tm   = Time::Moment->new(
        year  => $self->year,
        month => $self->month,
        day   => 1,
    );
    my $tm_new = $tm->plus_months(1)->minus_days(1);
    return $tm_new->day_of_month;
}

has 'last_day_week_day' => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_last_day_week_day',
);

sub _build_last_day_week_day {
    my $self = shift;
    my $tm   = Time::Moment->new(
        year  => $self->year,
        month => $self->month,
        day   => 1,
    );
    my $tm_new = $tm->plus_months(1)->minus_days(1);
    return $tm_new->day_of_week;
}

has '_week_end_days' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Int]',
    lazy    => 1,
    builder => '_build_week_end_days',
    handles => {
        all_weekend_days   => 'elements',
        count_weekend_days => 'count',
        find_weekend       => 'first',
    },
);

sub _build_week_end_days {
    my $self = shift;
    my $week_end_days = [];
    for my $day ( 1 .. $self->last_day ) {
        my $tm = Time::Moment->new(
            year  => $self->year,
            month => $self->month,
            day   => $day,
        );
        # say $tm->strftime('%Y-%m-%d');
        if ( $tm->day_of_week >= 6 ) {
            push @{$week_end_days}, $day;
        }
    }
    return $week_end_days;
}

has '_hollyday_days' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Int]',
    lazy    => 1,
    builder => '_build_hollyday_days',
    handles => {
        all_hollyday_days   => 'elements',
        count_hollyday_days => 'count',
        find_hollyday       => 'first',
    },
);

sub _build_hollyday_days {
    my $self          = shift;
    my $hollyday_days = [];
    foreach my $s ( $self->hollyday->records ) {
        push @{$hollyday_days}, $s->[0];
    }
    return $hollyday_days;
}

has 'work_days_count' => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_work_days_count',
);

sub _build_work_days_count {
    my $self        = shift;
    my $z_work_days = $self->last_day;
    for my $day ( 1 .. $self->last_day ) {
        if ( $self->is_weekend($day) || $self->is_holliday($day) ) {
            $z_work_days--;
        }
    }
    return $z_work_days;
}

sub is_weekend {
    my ($self, $day) = @_;
    my $found_w = $self->find_weekend( sub  { $day == $_ } );
    return $found_w;
}

sub is_weekend_sat {
    my ($self, $day) = @_;
    my $tm   = Time::Moment->new(
        year  => $self->year,
        month => $self->month,
        day   => $day,
    );
    return $tm->day_of_week == 6;
}

sub is_weekend_sun {
    my ($self, $day) = @_;
    my $tm   = Time::Moment->new(
        year  => $self->year,
        month => $self->month,
        day   => $day,
    );
    return $tm->day_of_week == 7;
}

sub is_holliday {
    my ($self, $day) = @_;
    my $found_h = $self->find_hollyday( sub { $day == $_ } );
    return $found_h;
}

has 'tm' => (
    is      => 'ro',
    isa     => 'Time::Moment',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Time::Moment->new(
            year  => $self->year,
            month => $self->month,
            day   => 1,
        );
    },
);

sub hist_month {
    my ( $self, $count ) = @_;
    my $tm    = $self->tm->minus_months($count);
    my $year  = $tm->year;
    my $month = sprintf( "%02d", $tm->month );
    return "${year}_${month}";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 SYNOPSIS


=head1 DESCRIPTION

Tpda3::Calendar - Calendar utils

=head1 INTERFACE

=head2 ATTRIBUTES

=head3 year

=head3 month

=head3 config

=head3 hollyday_file

=head3 hollyday

=head3 first_day_week_day

=head3 last_day

=head3 last_day_week_day

=head3 _week_end_days

=head3 _hollyday_days

=head3 work_days_count

=head3 tm

=head2 METHODS

=head3 _build_first_day_week_day

=head3 _build_last_day

=head3 _build_last_day_week_day

=head3 _build_week_end_days

=head3 _build_hollyday_days

=head3 _build_work_days_count

=head3 is_weekend

=head3 is_weekend_sat

=head3 is_weekend_sun

=head3 is_holliday

=head3 hist_month

=cut
