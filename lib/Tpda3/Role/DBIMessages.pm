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
            badtoken    => 'error#Token unknown: {name}',
            checkconstr => 'error#Check: {name}',
            colnotfound => 'error#Column not found {name}',
            dbnotfound  => 'error#Database {name} not found',
            driver      => 'error#Database driver {name} not found',
            duplicate   => 'error#Duplicate {name}',
            nethost     => 'error#Network problem with host {name}',
            network     => 'error#Network problem',
            notconn     => 'error#Not connected',
            nullvalue   => 'error#Null value for {name}',
            passname    => 'error#Authentication failed for {name}',
            password    => 'error#Authentication failed, password?',
            relforbid   => 'error#Permission denied',
            relnotfound => 'error#Relation {name} not found',
            syntax      => 'error#SQL syntax error',
            unknown     => 'error#Database error',
            username    => 'error#Wrong user name: {name}',
            userpass    => 'error#Authentication failed',
            servererror => 'error#Server not available',
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
