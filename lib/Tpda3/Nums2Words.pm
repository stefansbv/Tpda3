package Tpda3::Nums2Words;

use strict;
use warnings;

use Data::Dumper;

use Exporter;
use utf8;

use Tpda3::Utils;

our @ISA = qw(Exporter);
our @EXPORT = qw(num2word);

our $names;

_init_vars();

=head1 NAME

Tpda3::Nums2Words - Romanian numbers to words module.

=head1 VERSION

Version 0.02

=cut

our $VERSION = "0.02";

=head1 SYNOPSIS

  use Tpda3::Nums2Words;

  print num2word(1234432);

  # un milion două sute trei zeci patru mii patru sute trei zeci și doi

=cut

=head2 num2word

Translate numbers to words for the Romanian language.

=cut

=head2 _init_vars

Initialize global variables.

=cut

sub num2word {
    my ($number) = @_;

    my $comified1 = Tpda3::Utils->commify($number);

    my @cuvinte;
    my @grupe = reverse split /,/, $comified1;

    for (my $grp = 0; $grp <= $#grupe; $grp++) {
        my $cuvinte = process_group($grupe[$grp], $names->{ordin}[$grp]);
        unshift @cuvinte, join ' ', @{$cuvinte};
    }

    # Corectii

    my $cuvant = join ' ', @cuvinte;

    $cuvant =~ s{\A\s*și}{};
    $cuvant =~ s{unu sute}{una sută}gm;
    # $cuvant =~ s{unu mii}{una mie}gm;
    $cuvant =~ s{unu milioane}{un milion}gm;
    $cuvant =~ s{unu (?=milioane|miliarde)}{una }g;
    $cuvant =~ s{doi (?=zeci|sute|mii|milioane|miliarde)}{două }g;
    $cuvant =~ s{\s+}{ }g;      # just one space between words

    return $cuvant;
}

sub process_group {
    my ($group, $ordin ) = @_;

    my @cifre = reverse split //, $group;
    my @cuvinte;

    for ( my $subgrup = 0; $subgrup <= $#cifre; $subgrup++ ) {

        my $subordin = $names->{subordin}[$subgrup];

        my $cifra = $cifre[$subgrup];
        my $cuvant = '';

        next if $cifra eq '0';

        my $grup_cifre = reverse @cifre[0,$subgrup];

        if ($subordin eq 'zeci') {
            $cuvant = group_name($grup_cifre);
        }

        if ($cuvant) {
            shift @cuvinte;     # suprascrie rezultatul de la unitati
            push  @cuvinte, $cuvant;
        }
        else {
            $cuvant = process_subgrup($cifra, $subordin);
            unshift @cuvinte, $cuvant;
        }
    }

    if ($ordin ne 'sute') {
        push @cuvinte, $ordin if scalar @cuvinte; # mii, milionane ...
    }

    return \@cuvinte;
}

sub process_subgrup {
    my ($cifra, $subordin) = @_;

    my $cuvant = $names->{cifre}{$cifra};

    if ($subordin eq 'unitati') {
        $cuvant = ' și ' . $cuvant;
    }
    else {
        $cuvant =  $cuvant . ' ' . $subordin;
    }

    return $cuvant;
}

sub group_name {
    my $grup = shift;

    return $names->{exceptii}{$grup}
        if exists $names->{exceptii}{$grup};

    return q{};                 # empty
}

sub _init_vars {

    $names->{cifre} = {
        0   => '',
        1   => 'unu',
        2   => 'doi',
        3   => 'trei',
        4   => 'patru',
        5   => 'cinci',
        6   => 'șase',
        7   => 'șapte',
        8   => 'opt',
        9   => 'nouă',
    };

    $names->{exceptii} = {
        10  => 'zece',
        11  => 'unsprezece',
        12  => 'doisprezece',
        13  => 'treisprezece',
        14  => 'paisprezece',
        15  => 'cincisprezece',
        16  => 'șaisprezece',
        17  => 'șaptesprezece',
        18  => 'optsprezece',
        19  => 'nouăsprezece',
    };

    $names->{ordin} = [ 'sute', 'mii', 'milioane', 'miliarde' ];

    $names->{subordin} = [ 'unitati', 'zeci', 'sute' ];

    return;
}

=head1 DESCRIPTION

Translate numbers to words for the Romanian language.  Limited to
positive integers up to 999 milions, developed for the financial
environment.

=head1 ACKNOWLEDGEMENTS

Inspired by Lingua::EN::Nums2Words by Lester Hightower.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Nums2Words
