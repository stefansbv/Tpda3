package Tpda3;

use 5.008009;
use strict;
use warnings;

use Log::Log4perl qw(get_logger);
use Locale::TextDomain 1.20 qw(Tpda3);
use Locale::Messages qw(bind_textdomain_filter);

require Tpda3::Config;

BEGIN {
    # Stolen from Sqitch...
    # Force Locale::TextDomain to encode in UTF-8 and to decode all messages.
    $ENV{OUTPUT_CHARSET} = 'UTF-8';
    bind_textdomain_filter 'Tpda3' => \&Encode::decode_utf8;
}

=head1 NAME

Tpda3 - Tpda3 (Tiny Perl Database Application 3).

=head1 VERSION

Version 0.70

=cut

our $VERSION = '0.70';

=head1 SYNOPSIS

B<Tpda3> is a classic desktop database application framework.

    use Tpda3;

    #-- Minimal options:

    my $opts = {};

    $opts->{user} = $user;
    $opts->{pass} = $pass;
    $opts->{cfname} = $cfname;

    Tpda3->new( $opts )->run;

=head1 DESCRIPTION

Tpda3 is a classic desktop database application framework and
run-time, written in Perl.  The graphical user interface is based on
PerlTk. It supports the CUBRID, Firebird, PostgreSQL and SQLite RDBMS.

There is also an early, experimental, graphical user interface based
on wxPerl.

B<Tpda3> should work on any OS where Perl and the required
dependencies can be installed, but currently it's only tested on
GNU/Linux and Windows (XP and 7).  Feedback and patches for other OSs
is welcome.

Tpda3 is the successor of TPDA and, hopefully, has a much better API
implementation, Tpda3 follows the Model View Controller (MVC)
architecture pattern.  The look and the user interface functionality
of Tpda3 is almost the same as of TPDA, with some minor improvements.

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
control widget used for the search results.  A I<Details> page can
also be used with the proper configuration options.

This application is designed to be flexible, as a consequence the
configurations are quite complex.

Another new feature of Tpda3 is the suuport for I<wxPerl>.  The
application configuration file, located in the F<.tpda3> tree in F<<
apps/<appname>/etc/application.yml >>, has a (new) option named
I<widgetset> with Tk and Wx as valid values (case insensitive).

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

    unless ($widgetset) {
        die "The required configuration not found: 'widgetset'";
    }

    if ( uc $widgetset eq q{WX} ) {
        require Tpda3::Wx::Controller;
        $self->{gui} = Tpda3::Wx::Controller->new();
    }
    elsif ( uc $widgetset eq q{TK} ) {
        require Tpda3::Tk::Controller;
        $self->{gui} = Tpda3::Tk::Controller->new();
    }
    else {
        die "Unknown widget set!: '$widgetset'";
    }

    $self->{gui}->start();    # stuff to run at start

    return;
}

=head2 run

Execute the application.

=cut

sub run {
    my $self = shift;

    $self->{gui}{_app}->MainLoop();

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3

You can also look for information at: http://tpda.sourceforge.net

=head1 ACKNOWLEDGEMENTS

The Open Source movement, and all the authors, contributors and
community behind this great projects, this project would not exist
without:

 Perl and Perl modules including CPAN
 Perl Monks - the best Perl support site. [http://www.perlmonks.org/]
 Kephra
 Padre
 GNU/Linux
 Firebird (and Flamerobin)
 Postgresql
 SQLite
 CUBRID

The implementation of the MVC pattern is heavily based on the
implementation from the Cipres project:

Author: Rutger Vos, 17/Aug/2006
        http://svn.sdsc.edu/repo/CIPRES/cipresdev/branches/guigen \
             /cipres/framework/perl/cipres/lib/Cipres/

The implementation of the Wx interface is heavily based on the work
of Mark Dootson.

The implementation of the localization code is based on the work of
David E. Wheeler.

Thank You!

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Stefan Suciu.

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
