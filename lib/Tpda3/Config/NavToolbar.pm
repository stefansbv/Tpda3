package Tpda3::Config::NavToolbar;

# ABSTRACT: Navigation Toolbar configurations (for pagination)

use Mouse;
use Locale::TextDomain 1.20 qw(Tpda3);

has 'toolnames' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [ "tb5n1", "tb5n2", "tb5n3", "tb5n4", "tb5n5" ],;
    },
    handles => {
        all_buttons => 'elements',
    },
);

has 'tool' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {
            tb5n1 => {
                tooltip => __ 'First page',
                help    => __ 'First page',
                icon  => 'playstart22',
                sep   => 'none',
                type  => '_item_normal',
                id    => 1501,
                state => {
                    rec => {
                        add  => 'disabled',
                        find => 'disabled',
                        edit => 'disabled',
                        idle => 'disabled',
                        sele => 'disabled',
                    },
                    det => {
                        add  => 'disabled',
                        find => 'disabled',
                        edit => 'disabled',
                        idle => 'disabled',
                        sele => 'disabled',
                    },
                },
            },
            tb5n2 => {
                tooltip => __ 'Previous page',
                help    => __ 'Previous page',
                icon  => 'nav1leftarrow22',
                sep   => 'none',
                type  => '_item_normal',
                id    => 1502,
                state => {
                    rec => {
                        add  => 'disabled',
                        find => 'disabled',
                        edit => 'disabled',
                        idle => 'disabled',
                        sele => 'disabled',
                    },
                    det => {
                        add  => 'disabled',
                        find => 'disabled',
                        edit => 'disabled',
                        idle => 'disabled',
                        sele => 'disabled',
                    },
                },
            },
            tb5n3 => {
                tooltip => __ 'Page#',
                help    => __ 'Page number',
                label   => __ 'Page',
                sep   => 'none',
                type  => '_item_labentry',
                id    => 1503,
                state => {
                    rec => {
                        add  => 'disabled',
                        find => 'disabled',
                        edit => 'disabled',
                        idle => 'disabled',
                        sele => 'disabled',
                    },
                    det => {
                        add  => 'disabled',
                        find => 'disabled',
                        edit => 'disabled',
                        idle => 'disabled',
                        sele => 'disabled',
                    },
                },
            },
            tb5n4 => {
                tooltip => __ 'Next page',
                help    => __ 'Next page',
                icon  => 'nav1rightarrow22',
                sep   => 'none',
                type  => '_item_normal',
                id    => 1504,
                state => {
                    rec => {
                        add  => 'disabled',
                        find => 'disabled',
                        edit => 'disabled',
                        idle => 'disabled',
                        sele => 'disabled',
                    },
                    det => {
                        add  => 'disabled',
                        find => 'disabled',
                        edit => 'disabled',
                        idle => 'disabled',
                        sele => 'disabled',
                    },
                },
            },
            tb5n5 => {
                tooltip => __ 'Last page',
                help    => __ 'Last page',
                icon  => 'playend22',
                sep   => 'after',
                type  => '_item_normal',
                id    => 1505,
                state => {
                    rec => {
                        add  => 'disabled',
                        find => 'disabled',
                        edit => 'disabled',
                        idle => 'disabled',
                        sele => 'disabled',
                    },
                    det => {
                        add  => 'disabled',
                        find => 'disabled',
                        edit => 'disabled',
                        idle => 'disabled',
                        sele => 'disabled',
                    },
                },
            },
        };
    },
    handles => {
        ids_in_tool => 'keys',
        get_tool    => 'get',
    },
);

__PACKAGE__->meta->make_immutable;

no Mouse;

1;
