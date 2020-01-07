package Tpda3::Outlook;

# ABSTRACT: Outlook send mail

use Moo;
use Tpda3::Types qw(
    ArrayRef
    HashRef
    MailOutlook
    MailOutlookMessage
    Str
);
use Mail::Outlook;

has 'subject' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'contents' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'send_to' => (
    is       => 'ro',
    isa      => ArrayRef|HashRef|Str,
    required => 1,
);

has 'files' => (
    is  => 'ro',
    isa => ArrayRef,
);

#---

has '_to' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self    = shift;
        my $send_to = $self->send_to;
        if ( ref $send_to eq 'HASH' ) {
            return join ';', @{ $send_to->{to} };
        }
        elsif ( ref $send_to eq 'ARRAY' ) {
            return join ';', @{ $send_to };
        }
        return $send_to;
    },
);

has '_cc' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self    = shift;
        my $send_to = $self->send_to;
        if ( ref $send_to eq 'HASH' ) {
            return join ';', @{ $send_to->{cc} };
        }
        return '';
    },
);

has 'outlook' => (
    is      => 'ro',
    isa     => MailOutlook,
    lazy    => 1,
    default => sub {
        my $mail = Mail::Outlook->new;
        die "Cannot create mail object\n" unless $mail;
        return $mail;
    },
);

has 'message' => (
    is      => 'ro',
    isa     => MailOutlookMessage,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $message = $self->outlook->create();
        die "Cannot create message object\n" unless $message;
        return $message;
    },
);

sub make_message {
    my $self = shift;
    my $message = $self->message;
    $message->To( $self->_to );
    $message->Cc( $self->_cc ) if $self->_cc;
    $message->Subject( $self->subject );
    $message->Body( $self->contents );
    my $files = $self->files;
    $message->Attach( @{$files} ) if ref $files and scalar @{$files} > 0;
    return $message;
}

__PACKAGE__->meta->make_immutable;

no Mouse;

__END__

=encoding utf8

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 ATTRIBUTES

=head3 attr1

=head2 INSTANCE METHODS

=head3 meth1

=cut
