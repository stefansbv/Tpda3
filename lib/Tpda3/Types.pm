package Tpda3::Types;

# ABSTRACT: Tpda3 custom types

use 5.010;
use strict;
use warnings;
use utf8;
use Type::Library 0.040 -base, -declare => qw(
    DateSimple
    DateRange
    Path
    MailOutlook
    MailOutlookMessage
    Tpda3Config
    Tpda3Hollyday
    TimeMoment
);
use Type::Utils -all;
use Types::Standard -types;

# Inherit standard types.
BEGIN { extends "Types::Standard" };

# Other
class_type DateSimple,         { class => 'Date::Simple' };
class_type DateRange,          { class => 'Date::Range' };
class_type Path,               { class => 'Path::Tiny' };
class_type MailOutlook,        { class => 'Mail::Outlook' };
class_type MailOutlookMessage, { class => 'Mail::Outlook::Message' };
class_type TimeMoment,         { class => 'Time::Moment' };

class_type Tpda3Config,   { class => 'Tpda3::Config' };
class_type Tpda3Hollyday, { class => 'Tpda3::Hollyday' };


1;
