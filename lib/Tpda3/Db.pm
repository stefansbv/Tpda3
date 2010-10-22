package Tpda3::Db;

use strict;
use warnings;

use Log::Log4perl qw(get_logger);

use Tpda3::Db::Connection;

use base qw(Class::Singleton);

=head1 NAME

Tpda3::Db - Database operations module

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Connect to a database.

    use Tpda3::Db;

    my $db = Tpda3::Db->_new_instance();

    my $dbh = $db->dbh;


=head1 METHODS

=head2 new

Constructor method.

=cut

sub _new_instance {
    my $class = shift;

    my $conn = Tpda3::Db::Connection->new;

    return bless { conn => $conn }, $class;
}

=head2 dbh

Return database handle.

=cut

sub dbh {
    my $self = shift;

    return $self->{conn}{dbh};
}

=head2 dbc

Module instance

=cut

sub dbc {
    my $self = shift;

    return $self->{conn}{dbc};
}

=head2 DESTROY

Destroy method.

=cut

sub DESTROY {
    my $self = shift;

#    $self->{conn}->disconnect () if defined $self->{conn};
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Inspired from PerlMonks node [id://609543] by GrandFather.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1; # End of Tpda3::Db
