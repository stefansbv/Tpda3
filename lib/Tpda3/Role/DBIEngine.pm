package Tpda3::Role::DBIEngine;

# ABSTRACT: DBI engine role

use 5.010001;
use utf8;
use Moose::Role;
use DBI;
use Try::Tiny;
use Locale::TextDomain qw(App-Tpda3Dev);
use SQL::Abstract;
use namespace::autoclean;

with 'MooX::Log::Any';

requires 'dbh';

has 'sql' => (
    is      => 'ro',
    isa     => 'SQL::Abstract',
    default => sub {
        return SQL::Abstract->new;
    },
);

sub begin_work {
    my $self = shift;
    $self->dbh->begin_work;
    return $self;
}

sub finish_work {
    my $self = shift;
    $self->dbh->commit;
    return $self;
}

sub rollback_work {
    my $self = shift;
    $self->dbh->rollback;
    return $self;
}

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Name

Tpda3::Role::DBIEngine - An engine based on the DBI

=head1 Synopsis

  package Tpda3::Engine::firebird;
  extends 'Tpda3::Engine';
  with 'Tpda3::Role::DBIEngine';

=head1 Description

This role encapsulates the common attributes and methods required by
DBI-powered engines.

=head1 Interface

=head2 Instance Methods

=head3 C<begin_work>

=head3 C<finish_work>

=head3 C<rollback_work>

=head3 C<insert>

Build and execute a INSERT SQL statement.

=head3 C<lookup>

Build and execute a SELECT SQL statement and return a limited set of
the results as an array of arays references.

=head3 C<records_aoa>

Build and execute a SELECT SQL statement and return the results as an
array of arays references.

=head3 C<records_aoh>

Build and execute a SELECT SQL statement and return the results as an
array of hash references.

=head1 See Also

=over

=item L<Tpda3::Engine::pg>

The PostgreSQL engine.

=item L<Tpda3::Engine::firebird>

The Firebird engine.

=back

=head1 Author

David E. Wheeler <david@justatheory.com>

Ștefan Suciu <stefan@s2i2.ro>

=head1 License

Copyright (c) 2012-2014 iovation Inc.

Copyright (c) 2014-2015 Ștefan Suciu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
