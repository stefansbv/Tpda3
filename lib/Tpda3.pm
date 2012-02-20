package Tpda3;

use strict;
use warnings;
use 5.008009;

use Log::Log4perl qw(get_logger);

require Tpda3::Config;

=head1 NAME

Tpda3 - Tpda3 (Tiny Perl Database Application 3.

=head1 VERSION

Version 0.44

=cut

our $VERSION = '0.44';

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

B<Tpda3> (Tiny Perl Database Application 3) is the successor of Tpda,
a classic desktop database application framework, written in Perl,
that aims to follow the Model View Controller (MVC) architecture.

Tpda3 has PerlTk and wxPerl support for the GUI part and Firebird,
PostgreSQL and (limited) SQLite support for the database.

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

    # $self->{_log} = get_logger();

    my $widgetset = $cfg->application->{widgetset};

    unless ($widgetset) {
        print "Required configuration not found: 'widgetset'\n";
        exit;
    }

    if ( $widgetset =~ m{wx}ix ) {
        require Tpda3::Wx::Controller;
        $self->{gui} = Tpda3::Wx::Controller->new();

        # $self->{_log}->info('Using Wx ...');
    }
    elsif ( $widgetset =~ m{tk}ix ) {
        require Tpda3::Tk::Controller;
        $self->{gui} = Tpda3::Tk::Controller->new();

        # $self->{_log}->info('Using Tk ...');
    }
    else {
        warn "Unknown widget set!\n";

        # $self->{_log}->debug('Unknown widget set!');

        exit;
    }

    $self->{gui}->start();    # stuff to run at start

    return;
}

=head2 run

Execute the application.

=cut

sub run {
    my $self = shift;

    # $self->{_log}->trace('Run ...');

    $self->{gui}{_app}->MainLoop();

    # $self->{_log}->trace('Stop.');

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users.sourceforge.net> >>

=head1 BUGS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3

You can also look for information at: http://tpda.sourceforge.net

=head1 ACKNOWLEDGEMENTS

The implementation of the MVC pattern is (heavily) based on the
implementation from the Cipres project:

Author: Rutger Vos, 17/Aug/2006
        http://svn.sdsc.edu/repo/CIPRES/cipresdev/branches/guigen \
             /cipres/framework/perl/cipres/lib/Cipres/

The Open Source movement, and all the authors, contributors and
community behind this great projects:

 Perl and Perl modules including CPAN
 Perl Monks - the best Perl support site. [http://www.perlmonks.org/]
 Kephra
 Padre
 GNU/Linux
 Firebird (and Flamerobin)
 Postgresql
 SQLite

Thank You!

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

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
