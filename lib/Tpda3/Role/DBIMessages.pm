package Tpda3::Role::DBIMessages;

# ABSTRACT: Database engines error messages

use 5.0100;
use utf8;
use Moose::Role;

has '_messages' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['Hash'],
    init_arg => undef,
    default  => sub {
        return {
            badtoken    => 'token unknown: {name}',
            checkconstr => 'check: {name}',
            colnotfound => 'column not found {name}',
            dbnotfound  => 'database {name} not found',
            driver      => 'database driver {name} not found',
            duplicate   => 'duplicate {name}',
            nethost     => 'network problem with host {name}',
            network     => 'network problem',
            notconn     => 'not connected',
            nullvalue   => 'null value for {name}',
            passname    => 'authentication failed for {name}',
            password    => 'authentication failed, password?',
            relforbid   => 'permission denied',
            relnotfound => 'relation {name} not found',
            syntax      => 'SQL syntax error',
            unknown     => 'database error',
            username    => 'wrong user name: {name}',
            userpass    => 'authentication failed',
            servererror => 'server not available',
        };
    },
    handles => { get_message => 'get', },
);

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Name

Tpda3::Role::DBIMessages - User messages for engines based on the DBI

=head1 Synopsis

  package Tpda3::Engine::firebird;
  extends 'Tpda3::Engine';
  with 'Tpda3::Role::DBIMessages';

=head1 Description

This role encapsulates the common attributes and methods required by
DBI-powered engines.

=head1 Interface

=head2 Attributes

=head3 C<_messages>

A hash reference attribute.  The keys are codes for error messages
thrown by the engines and the values are the messages presented to the
user.

=head1 Author

Ștefan Suciu <stefan@s2i2.ro>

=head1 License

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
