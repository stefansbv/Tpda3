package Tpda3::Types;

# ABSTRACT: Tpda3 custom types

use 5.010;
use strict;
use warnings;
use utf8;
use Type::Library 0.040 -base, -declare => qw(
    DateRange
    DateSimple
    ExcelWriterXLSX
    ListCompare
    MailOutlook
    MailOutlookMessage
    Path
    TimeMoment
    Tpda3Compare
    Tpda3Config
    Tpda3Hollyday
    Tpda3Record
    URIdb
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
class_type ListCompare,        { class => 'List::Compare' };
class_type URIdb,              { class => 'URI::db' };
class_type ExcelWriterXLSX,    { class => 'Excel::Writer::XLSX' };
class_type Tpda3Config,   { class => 'Tpda3::Config' };
class_type Tpda3Hollyday, { class => 'Tpda3::Hollyday' };
class_type Tpda3Compare,  { class => 'Tpda3::Model::Update::Compare' };
class_type Tpda3Record ,  { class => 'Tpda3::Model::Table::Record' };

1;
