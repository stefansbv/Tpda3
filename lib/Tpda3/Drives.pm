package Tpda3::Drives;

# ABSTRACT: Drives

use 5.010001;
use utf8;
use Moo;
use Sub::HandlesVia;
use Tpda3::Types qw(
    HashRef
    Str
);
use Win32::DriveInfo;

#---

has '_types' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef[Str],
    default => sub {
        {
            0 => 'Undetermined',
            1 => 'Does Not Exist',
            2 => 'Removable',
            3 => 'HDD',
            4 => 'Network',
            5 => 'CDROM',
            6 => 'RAM Disk',
        };
    },
    handles   => {
        get_type     => 'get',
        num_types    => 'count',
        type_pairs   => 'kv',
    },
);

has '_drives' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef[Str],
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @_drives = Win32::DriveInfo::DrivesInUse();
        my $drives  = {};
        foreach my $drive (@_drives) {
            my $type = Win32::DriveInfo::DriveType($drive);
            $drives->{$drive} = $self->get_type($type);
        }
        return $drives;
    },
    handles   => {
        get_drive   => 'get',
        num_drives  => 'count',
        drive_pairs => 'kv',
        drives      => 'keys',
    },
);

sub has_removables {
    my $self = shift;
    for my $pair ( $self->drive_pairs ) {
        return 1 if $pair->[1] eq 'Removable';
    }
    return 0;
}

sub get_removables {
    my $self = shift;
    my $removables = {};
    for my $pair ( $self->drive_pairs ) {
        # print "$pair->[0] = $pair->[1]\n";
        $removables->{$pair->[0]} = $pair->[1] if $pair->[1] eq 'Removable';
    }
    return $removables;
}

sub has_removable {
    my ( $self, $letter ) = @_;
    die "has_removable requires a drive letter parameter.\n"
      unless $letter =~ m/^[A-Z]$/;
    my $removables = $self->get_removables;
    return exists $removables->{$letter} ? 1 : 0;
}

sub print_drives {
    my ($self, $pre, $title) = @_;
    my $removables = {};
    $pre //= '';
    print "$title\n" if $title;
    for my $drive ( sort $self->drives ) {
        print "${pre}${drive} = ", $self->get_drive($drive), "\n";
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 ATTRIBUTES

=head3 _types

The _tipes private attribute, hold the description of the types
returned by the Win32::DriveInfo module.

The folowing methods are available and defined as delegations:

=over

=item get_type

=item num_types

=item type_pairs

=back

=head3 _drives

The _drives private attribute, hold the drive letters and the type of
the drives currently in use on the OS.

The folowing methods are available and defined as delegations:

=over

=item get_drive

=item num_drives

=item drive_pairs

=item drives

=back

=head2 INSTANCE METHODS

=head3 has_removables

=head3 get_removables

=head3 has_removable

=head3 print_drives

=cut
