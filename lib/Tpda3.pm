package Tpda3;

use strict;
use warnings;

use 5.008005;

use Log::Log4perl qw(get_logger);

#use Tpda3::Tk::Controller;
use Tpda3::Wx::Controller;

=head1 NAME

Tpda3 - The third incarnation of Tpda!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Tpda3;

    my $foo = Tpda3->new();

=head1 DESCRIPTION

B<Tpda3> (Tiny Perl Database Application) is a classic desktop
database application framework, written in Perl, that aims to follow
the Model View Controller (MVC) architecture.  Tpda3 has PerlTk and
wxPerl support for the GUI part and Firebird, PostgreSQL and (limited)
SQLite support for the database.

This is the main module of the application.

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $args ) = @_;

    my $self = {};

    bless $self, $class;

    $self->_init($args);

    return $self;
}

=head2 _init

Initialize the configurations module and create the PerlTk application
instance.

=cut

sub _init {
    my ( $self, $args ) = @_;

    Tpda3::Config->instance($args);

    # $self->{gui} = Tpda3::Tk::Controller->new();
    $self->{gui} = Tpda3::Wx::Controller->new();

    $self->{gui}->start();

    return;
}

=head2 run

Execute the application

=cut

sub run {
    my $self = shift;

    $self->{gui}{_app}->MainLoop;

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users.sourceforge.net> >>

=head1 BUGS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3

You can also look for information at:

=head1 ACKNOWLEDGEMENTS

The implementation of the MVC pattern is (heavily) based on the
implementation from the Cipres project:

Author: Rutger Vos, 17/Aug/2006
        http://svn.sdsc.edu/repo/CIPRES/cipresdev/branches/guigen \
             /cipres/framework/perl/cipres/lib/Cipres/

The Open Source movement, and all the authors, contributors and
community behind this great projects:
 Perl and Perl modules
 Perl Monks - the best Perl support site. [http://www.perlmonks.org/]
 Firebird (and Flamerobin)
 Postgresql and SQLite
 GNU/Linux

And last but least, for the wxPerl stuff, Herbert Breunung for his
guidance, hints and for his Kephra project a very good source of
inspiration.

Thank You!

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

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

1;    # End of Tpda3
