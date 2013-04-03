########################################################################
# Package       CP::Class
# Description:  Class Base
# Created       Thu Dec 08 09:16:41 2011
# svn id        $Id: Class.pm 531 2012-03-31 17:05:47Z Mark Dootson $
# Copyright:    Copyright (c) 2011 Mark Dootson
# Licence:      This program is free software; you can redistribute it 
#               and/or modify it under the same terms as Perl itself
########################################################################

package Tpda3::Wx::CP::Class;

########################################################################

#use Citrus::Perl;
##
use 5.012;
use strict;
use warnings;
use IO::File   ();
use IO::Handle ();
use feature qw ( :5.12 );
use Try::Tiny;
use Carp;
##

require Exporter;
use base qw( Exporter );

our $VERSION = '0.66';

#-------------------------------------------------------------------
# Object Constructor
#-------------------------------------------------------------------

sub new {
    my ($class, $params) = @_;
    my $self = bless {'_zpwx_object_property_data' => {} }, $class;
    $self->init_zpwx_object($params);
}

#-------------------------------------------------------------------
# We can also inherit as a mixin.
# Note that internally datanames are always lower case so we
# can have Wx style accessors GetSomeThing and SetSomeThing but
# these will point to a data member named 'something'.
# We could create all of the accessors below and these would
# all point at $obj->{_zpwx_object_property_data}->{'something'}
#
# GetSomeThing()
# SetSomeThing($val)
# get_something()
# set_something($val)
# something()
# something($val)
# SomeThing()
# SomeThing($val)
#-------------------------------------------------------------------

sub init_zpwx_object {
    my ($self, $params) = @_;
    foreach my $key (sort keys( %$params ) ) {
        my $dataname = lc($key);
        $self->{_zpwx_object_property_data}->{$dataname} = $params->{$key};
    }
    return $self;
}

#-------------------------------------------------------------------
# Accessors
#-------------------------------------------------------------------

#-----------------------------------
# create_get_accessors
#   get_method()
#-----------------------------------

sub create_get_accessors {
    no strict 'refs';
    my $package = shift;
    foreach my $method ( @_ ) {
        my $lcmethod = lc($method);
        my $getmethod = ( $lcmethod eq $method ) ? qq(get_${method}) : qq(Get${method});
        *{"${package}::${getmethod}"} = sub {
            return $_[0]->{_zpwx_object_property_data}->{$lcmethod};
        };
    }
}

#-----------------------------------
# create_set_accessors
#   set_method($val)
#-----------------------------------

sub create_set_accessors {
    no strict 'refs';
    my $package = shift;
    foreach my $method ( @_ ) {
        my $lcmethod = lc($method);
        my $setmethod = ( $lcmethod eq $method ) ? qq(set_${method}) : qq(Set${method});
        *{"${package}::${setmethod}"} = sub {
            return $_[0]->{_zpwx_object_property_data}->{$lcmethod} = $_[1];
        };
    }
}

#-----------------------------------
# create_both_accessors
#   get_method()
#   set_method($val)
#-----------------------------------

sub create_both_accessors {
    my ($package, @args) = @_;
    $package->create_get_accessors( @args );
    $package->create_set_accessors( @args );
}

#-----------------------------------
# create_dual_accessors
#   method()
#   method($val)
#-----------------------------------

sub create_dual_accessors {
    no strict 'refs';
    my $package = shift;
    foreach my $method ( @_ ) {
        my $lcmethod = lc($method);
        *{"${package}::${method}"} = sub {
            return $_[0]->{_zpwx_object_property_data}->{$lcmethod} = $_[1] if @_ == 2;
            return $_[0]->{_zpwx_object_property_data}->{$lcmethod};
        };
    }
}

#-----------------------------------
# create_ro_accessors
#   method()
#-----------------------------------

sub create_ro_accessors {
    no strict 'refs';
    my $package = shift;
    foreach my $method ( @_ ) {
        my $lcmethod = lc($method);
        *{"${package}::${method}"} = sub {
            return $_[0]->{_zpwx_object_property_data}->{$lcmethod};
        };
    }
}

#-----------------------------------
# create_asym_accessors
#   IsEnabled()
#   Enable($val)
#-----------------------------------

sub create_asym_accessors {
    no strict 'refs';
    my $package = shift;
    foreach my $method ( @_ ) {
        my $dataname = lc($method->{read});
        my $readmethod = $method->{read};
        *{"${package}::${readmethod}"} = sub {
            return $_[0]->{_zpwx_object_property_data}->{$dataname};
        };
        if( my $writemethod = $method->{write} ) {
            *{"${package}::${writemethod}"} = sub {
                 return $_[0]->{_zpwx_object_property_data}->{$dataname} = $_[1];
        };
        }
    }
}

#------------------------------------
# Some naughty procs to access by val
# name as we allow data without
# accessors in $obj initialisation.
# This removes the temptation to
# do $obj->{data}->{$name} and adds
# some name checking at least.
#------------------------------------

sub get_cpclass_data {
    my($self, $valname) = @_;
    my $dataname = lc($valname);
    if(exists($self->{_zpwx_object_property_data}->{$dataname})) {
        return $self->{_zpwx_object_property_data}->{$dataname};
    } else {
        die qq(There is no class data member named $valname);   
    }
}

sub set_cpclass_data {
    my($self, $valname, $val) = @_;
    my $dataname = lc($valname);
    if(exists($self->{_zpwx_object_property_data}->{$dataname})) {
        return $self->{_zpwx_object_property_data}->{$dataname} = $val;
    } else {
        die qq(There is no class data member named $valname);   
    }
}

1;
