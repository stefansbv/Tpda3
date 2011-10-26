package Tpda3::Nums2Words;

use strict;
use warnings;

use Exporter;
use utf8;

our @ISA = qw(Exporter);
our @EXPORT = qw(num2word);

our $VERSION = "0.01";

# Private File-Global Variables
# Initialization Function init_mod_vars() sets up these variables

my @classifications;
my @MD;
my @categories;

# At module load time, initialize our static, file-global variables.
# We use these file-global variables to increase performance when one
# needs to compute many iterations for numbers to words.  The alternative
# would be to re-instantiate the never-changing variables over and over.
init_mod_vars();

# Public Functions

sub num2word {
  my $number = shift;

  return( num2word_internal($number, 0) );
}

# Private Functions

sub num2word_internal {
    my $number = shift;

    my $keep_trailing_zeros = shift;

    my ( $classification_index, %breakdown, $index );
    my ( $negative_flag, $classification );
    my ( $word, $final, $decimal_verbiage ) = ( "", "", "" );

    # Hand the number off to a function to get the verbiage
    # for what appears after the decimal
    $decimal_verbiage = handle_decimal( $number, $keep_trailing_zeros );

    # Determine if the number is negative and if so,
    # remember that fact and then make it positive
    if ( length($number) && ( $number < 0 ) ) {
        $negative_flag = 1;
        $number        = $number * -1;
    }

    # Take only the integer part of the number for the
    # calculation of the integer part verbiage
    # NOTE: Changed to regex 06/08/1998 by LHH because the int()
    #       was preventing the code from doing very large numbers
    #       by restricting the precision of $number.
    # $number = int($number);
    if ( $number =~ /^([0-9]*)\./ ) {
        $number = $1;
    }

    # Go through each of the @classifications breaking off each
    # three number pair from right to left corresponding to
    # each of the @classifications
    $classification_index = 0;

    while ( length($number) > 0 ) {
        if ( length($number) > 2 ) {
            $breakdown{ $classifications[$classification_index] }
                = substr( $number, length($number) - 3 );
            $number = substr( $number, 0, length($number) - 3 );
        }
        else {
            $breakdown{ $classifications[$classification_index] } = $number;
            $number = "";
        }
        $classification_index++;
    }

    # Go over each of the @classifications producing the verbiage
    # for each and adding each to the verbiage stack ($Final)
    $index = 0;
    foreach $classification (@classifications) {

        # If the value of these three digits == 0 then they can be ignored
        if (   ( !defined( $breakdown{$classification} ) )
            || ( $breakdown{$classification} < 1 ) )
        {
            $index++;
            next;
        }

        # Retrieves the $Word for these three digits
        $word = handle_three_digit( $breakdown{$classification} );

        # Leaves "$classifications[0] off of sute-TENs-ONEs numbers
        if ( $index > 0 ) {
            $word .= " " . $classification;
        }

        # Adds this $Word to the $Final and determines if it needs a comma
        if ( length($final) > 0 ) {
            $final = $word . ", " . $final;
        }
        else {
            $final = $word;
        }
        $index++;
    }

    # If our $Final verbiage is an empty string then our original number
    # was zero, so make the verbiage reflect that.
    if ( length($final) == 0 ) {
        $final = "zero";
    }

    # If we marked the number as negative in the beginning, make the
    # verbiage reflect that by prepending NEGATIVE
    if ($negative_flag) {
        $final = "minus " . $final;
    }

    # Now append the decimal portion of the verbiage calculated at the
    # beginning if there is any
    if ( length($decimal_verbiage) > 0 ) {
        $final .= " și " . $decimal_verbiage;
    }

    # Return the verbiage to the calling program
    return $final;
}

# Helper function which handles three digits from the @classifications
# level (mii, milioane, etc) - Deals with the sute

sub handle_three_digit {
    my $number = shift(@_);

    my ( $hundreds, $hundred_verbiage, $ten_verbiage, $verbiage );

    if ( length($number) > 2 ) {
        $hundreds = substr( $number, 0, 1 );
        $hundred_verbiage = handle_two_digit($hundreds);

        if ( length($hundred_verbiage) > 0 ) {
            $hundred_verbiage .= " sute";
        }
        $number = substr( $number, 1 );
    }

    $ten_verbiage = handle_two_digit($number);
    if ( ( defined($hundred_verbiage) ) && ( length($hundred_verbiage) > 0 ) ) {
        $verbiage = $hundred_verbiage;
        if ( length($ten_verbiage) ) { $verbiage .= " " . $ten_verbiage; }
    }
    else {
        $verbiage = $ten_verbiage;
    }

    return $verbiage;
}

# Helper function which handles two digits (from 99 to 0)

sub handle_two_digit {
    my $number = shift(@_);

    my($verbiage, $tens, $ones);

    if ( length($number) < 2 ) {
        return ( $MD[$number] );
    }
    else {
        if ( $number < 20 ) {
            return ( $MD[$number] );
        }
        else {
            $tens = substr( $number, 0, 1 );
            $tens = $tens * 10;
            $ones = substr( $number, 1, 1 );
            if ( length( $MD[$ones] ) > 0 ) {
                $verbiage = $MD[$tens] . " și " . $MD[$ones];
            }
            else {
                $verbiage = $MD[$tens];
            }
        }
    }

    return $verbiage;
}

sub handle_decimal {
    my $dec_number = shift;

    my $keep_trailing_zeros = shift;
    my $verbiage = "";
    my $categories_index = 0;
    my $category_verbiage = '';

    # I'm choosing to do this string-wise rather than mathematically
    # because the error in the mathematics can alter the number from
    # exactly what was sent in for high significance numbers
    # NOTE: Changed "if" to regex 06/08/1998 by LHH because the int()
    #       was preventing the code from doing very large numbers
    #       by restricting the precision of $number.
    if ( !( $dec_number =~ /\./ ) ) {
        return ('');
    }
    else {
        $dec_number = substr( $dec_number, rindex( $dec_number, '.' ) + 1 );

        # Trim off any trailing zeros...
        if ( !$keep_trailing_zeros ) { $dec_number =~ s/0+$//; }
    }

    $categories_index = length($dec_number);
    $category_verbiage = $categories[$categories_index - 1];
    if ( length $dec_number && $dec_number == 1 ) {

        # if the value of what is after the decimal place is one, then
        # we need to chop the "s" off the end of the $CategoryVerbiage
        # to make is singular
        chop($category_verbiage);
    }

    $verbiage = num2word($dec_number) . " " . $category_verbiage;

    return $verbiage;
}

# NOTE: sprintf(%f) fails on very large decimal numbers, thus the
# need for RoundToTwoDecimalPlaces().

sub round_to_two_decimal_places($) {
    my $number=shift @_;

    my ($mint, $mdec, $user_screw_up) = split(/\./, $number, 3);

    if (defined($user_screw_up) && length($user_screw_up)) {
        warn "num2usdollars() given invalid value."; }

    $mint = 0 if ! length $mint;

    $mdec = 0 if not defined($mdec);

    my $dec_part = int( sprintf( "%0.3f", "." . $mdec ) * 100 + 0.5 );

    $number = $mint . '.' . $dec_part;

    return $number;
}

# This function initializes our static, file-global variables.
sub init_mod_vars {
  @categories =     (
                "zeci",
                "sute",
                "mii",
                "zecidemii",
                "sutedemii",
                "milioane",
                "zecidemilioane",
                "sutedemilioane",
                "miliarde",
                "zecidemiliarde",
                "sutedemiliarde",
            );

  ###################################################

  $MD[0]  = "";
  $MD[1]  = "unu";
  $MD[2]  = "doi";
  $MD[3]  = "trei";
  $MD[4]  = "patru";
  $MD[5]  = "cinci";
  $MD[6]  = "șase";
  $MD[7]  = "șapte";
  $MD[8]  = "opt";
  $MD[9]  = "nouă";
  $MD[10] = "zece";
  $MD[11] = "unsprezece";
  $MD[12] = "doisprezece";
  $MD[13] = "treisprezece";
  $MD[14] = "paisprezece";
  $MD[15] = "cincisprezece";
  $MD[16] = "șaisprezece";
  $MD[17] = "șaptesprezece";
  $MD[18] = "optsprezece";
  $MD[19] = "nouăsprezece";
  $MD[20] = "douăzeci";
  $MD[30] = "treizeci";
  $MD[40] = "patruzeci";
  $MD[50] = "cincizeci";
  $MD[60] = "șaizeci";
  $MD[70] = "șaptezeci";
  $MD[80] = "opzeci";
  $MD[90] = "nouăzeci";

  @classifications = ( "HUNDREDs-TENs-ONEs", "mii", "milion", "miliard", );
}

1;

=head1 NAME

Nums2Words - generate Romanian verbiage from numerical values.

=head1 SYNOPSIS

  use Tpda3::Nums2Words;

  my $number   = 42;
  my $verbiage = num2word($number);

=head1 DESCRIPTION

This module provides functions that can be used to generate Roamnian
verbiage for numbers.

=head1 ACKNOWLEDGEMENTS

This is a stripped-down and adapted for Romanian version of the module
Lingua::EN::Nums2Words by Lester Hightower.

=head1 COPYRIGHT

Lingua::EN::Nums2Words - Numbers to Words Module for Perl.

Copyright (C) 1996-2011, Lester Hightower <hightowe@cpan.org>

Tpda3::Nums2Words - Romanian Numbers to Words Module for Perl.

Copyright (C) 2011 Ștefan Suciu.

=head1 LICENSE

Original license for Lingua::EN::Nums2Words:

As of version 1.13, this software is licensed under the OSI certified
Artistic License, one of the licenses of Perl itself.

L<http://en.wikipedia.org/wiki/Artistic_License>

=cut
