package Tpda3::Exceptions;

# ABSTRACT: Exceptions

use strict;
use warnings;

use Exception::Base
    'Exception::Db',
    'Exception::Db::Connect' => {
        isa               => 'Exception::Db',
        has               => [qw( usermsg logmsg attrib )],
        string_attributes => [qw( usermsg )],
    },
    'Exception::Db::SQL' => {
        isa               => 'Exception::Db',
        has               => [qw( usermsg logmsg attrib )],
        string_attributes => [qw( usermsg )],
    },
    'Exception::IO',
    'Exception::IO::PathNotFound' => {
        isa               => 'Exception::IO',
        has               => [qw( pathname )],
        string_attributes => [qw( message pathname )],
    },
    'Exception::IO::FileNotFound' => {
        isa               => 'Exception::IO',
        has               => [qw( filename )],
        string_attributes => [qw( message filename )],
    },
    'Exception::IO::SystemCmd' => {
        isa               => 'Exception::IO',
        has               => [qw( usermsg logmsg )],
        string_attributes => [qw( usermsg logmsg )],
    },
    'Exception::Config',
    'Exception::Config::Version' => {
        isa               => 'Exception::Config',
        has               => [qw( usermsg logmsg )],
        string_attributes => [qw( usermsg )],
    };

1;
