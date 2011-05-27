package Tpda3::Tk::Validation;

use strict;
use warnings;

=head1 NAME

Tpda3::Tk::Validation - The great new Tpda3::Tk::Validation!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Tpda3::Tk::Validation;

    my $foo = Tpda3::Tk::Validation->new();
    ...

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my $class = shift;

    return bless {
        alpha        => \&alpha,
        alphanum     => \&alphanum,
        alphanumplus => \&alphanum,
        integer      => \&integer,
        numeric      => \&numeric,
        anychar      => \&anychar,
        email => \&email,
        data => \&data,
    }, $class;
}

=head2 validate

Entry validation for Tk::Entry widgets.

=cut

sub validate {
    my ($self, $text_param, $p1, $p2, $p3, $myindex, $p5) = @_;

    my ( $proc, $maxlen, $zecim ) = split /:/, $text_param;

    # $proc = 'anychar' if $find_mode;# allow 'NULL' string to be entered

    my $retval;
    if ( exists $self->{$proc} ) {
        $retval = $self->{$proc}->( $self, $p1, $maxlen, $zecim );
    }
    else {
        print "WW: Validation for '$proc' not yet implemented!";
        $retval = 1;
    }

    return $retval;
}

sub alpha {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = qr/^\p{IsAlpha}{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"alpha:$maxlen", "red");
        return 0;
    }
}

sub alphanum {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = qr/^[\p{IsAlnum} +-]{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"alphanum:$maxlen", "red");
        return 0;
    }
}

sub alphanumplus {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = qr/^[\p{IsAlnum}\p{IsP} %&@,.+-]{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"alphanum+:$maxlen", "red");
        return 0;
    }
}

sub integer {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = qr/^\p{IsDigit}{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"digit:$maxlen", "red");
        return 0;
    }
}

sub numeric {
    my ($self, $myvar, $maxlen, $zecim) = @_;

    $zecim = 0 unless ( defined $zecim );

    my $pattern = sprintf "\^\-?[0-9]{0,%d}(\\.[0-9]{0,%d})?\$",
        $maxlen - $zecim - 1, $zecim;

    # my $pattern =
    #   qr/^\-?\p{IsDigit}{0,$maxlen -$zecim -1}(\.\p{IsDigit}{0,$zecim})?$/x;


    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"digit:$maxlen:$zecim", "red");
        return 0;
    }
}

sub anychar {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = qr/^\p{IsPrint}{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
#        $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
#        $self->{tpda}{gui}->refresh_sb('ll',"anychar:$maxlen", "red");
        return 0;
    }
}

sub email {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = qr/^[\p{IsAlnum}\p{IsP} %&@,.+-]{0,$maxlen}$/;

    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"alphanum+:$maxlen", "red");
        return 0;
    }
}

sub data {
    my ($self, $myvar, $maxlen) = @_;

    my $pattern = sprintf "\^[0-9]{2}\.[0-9]{2}\.[0-9]{4}\$", $maxlen;

    if ( $myvar =~ m/$pattern/ ) {
        # $self->{tpda}{gui}->refresh_sb('ll',"");
        return 1;
    }
    else {
        # $self->{tpda}{gui}->refresh_sb('ll',"date:dmy|mdy", "red");
        return 0;
    }
}

# sub entry_limit_tbl {

#     # Description: Entry validation for tables                                |

#     my $self    = $_[0];
#     my $eobjtab = $_[1];

#     # my $eobjtab = $screen_name->get_eobj_tab();

#     # my $row  = $_[0];    # print "r   = $row\n";
#     # my $col  = $_[1];    # print "c   = $col\n";
#     # my $old  = $_[2];    # print "old = $old\n";
#     # my $new  = $_[3];    # print "new = $new\n";
#     # my $cidx = $_[4];    # print "ind = $cidx\n";

#     my $text_param = '';

#     # Cam scumpa procedura ...
#     foreach my $camp ( keys %{$eobjtab} ) {

#         # print "Camp = $camp\n";
#         my $indice = $eobjtab->{$camp}[0];
#         if ( $indice == $col ) {
#             $text_param = $eobjtab->{$camp}[6];
#             last;
#         }
#     }

#     # print "Text param = $text_param\n";
#     my ( $proc, $maxlen, $zecim ) = split( ':', $text_param );

#     no strict 'refs';
#     my $retval = &{$proc}( $self, $new, $maxlen, $zecim );

#     # $retval =~ s/\n$//; Nu mere sa curat de aici stringul de \n

#     return $retval;
# }

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Tk::Validation

=head1 ACKNOWLEDGEMENTS

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

1; # End of Tpda3::Tk::Validation
