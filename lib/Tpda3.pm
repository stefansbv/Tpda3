package Tpda3;

use strict;
use warnings;

use 5.008005;

use Log::Log4perl qw(get_logger);

=head1 NAME

Tpda3 - The third incarnation of Tpda!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';

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

This project has two components, the B<Tpda3> I<runtime> and the
B<Tpda3> I<applications>.

The I<runtime> is responsible for loading the configuration files,
connect and work with the database, create the main application
I<Frame> with a menubar, toolbar and statusbar.

The B<Tpda3> I<application> is a collection of screens.  At run time,
after the main I<Frame> is created, the user can select a I<Screen>
from the menu.  Then the I<runtime> will create a I<NoteBook> with two
pages named I<Record> and I<List>. In the I<Record> page will create
the controls of the selected I<Screen>.  The I<List> page holds a list
control widget used for the search results.

TODO:

This application is designed to be very flexible, as a consequence the
configurations are ...

...

The application configuration file, located in the F<.tpda3>
tree in F<< apps/<appname>/etc/application.yml >>, has a (new) option
named I<widgetset> with Tk and Wx as valid values (case insensitive).

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

Initialize the configurations module and create the PerlTk or the
wxPerl application instance.

=cut

sub _init {
    my ( $self, $args ) = @_;

    my $cfg = Tpda3::Config->instance($args);

    my $widgetset = $cfg->application->{widgetset};

    if ( $widgetset =~ m{wx}ix ) {
        print " Wx application\n";
        require Tpda3::Wx::Controller;
        $self->{gui} = Tpda3::Wx::Controller->new();
    }
    elsif ( $widgetset =~ m{tk}ix ) {
        print " Tk application\n";
        require Tpda3::Tk::Controller;
        $self->{gui} = Tpda3::Tk::Controller->new();
    }
    else {
        warn "Unknown widget set!\n";
        exit;
    }

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
