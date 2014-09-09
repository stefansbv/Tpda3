package Tpda3::Config::Menu;

# ABSTRACT: Menu configurations

use Mouse;
use Locale::TextDomain 1.20 qw(Tpda3);
use namespace::autoclean;


has 'menu_names' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [ 'menu_app', 'menu_admin', 'menu_help', ],
    },
    handles => {
        all_menus => 'elements',
    },
);


has 'menu' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {   'menu_app' => {
                'id'        => '5001',
                'label'     => __ 'App',
                'underline' => 0,
                'popup'     => {
                    '1' => {
                        'name'      => 'mn_fm',
                        'label'     => __ 'Toggle find mode',
                        'underline' => 0,
                        'key'       => 'F7',
                        'sep'       => 'none',
                    },
                    '2' => {
                        'name'      => 'mn_fe',
                        'label'     => __ 'Execute search',
                        'underline' => 0,
                        'key'       => 'F8',
                        'sep'       => 'none',
                    },
                    '3' => {
                        'name'      => 'mn_fc',
                        'label'     => __ 'Execute count',
                        'underline' => 0,
                        'key'       => 'F9',
                        'sep'       => 'none',
                    },
                    '4' => {
                        'name'      => 'mn_pr',
                        'label'     => __ 'Preview report',
                        'underline' => 0,
                        'key'       => 'Alt-P',
                        'sep'       => 'before',
                    },
                    '5' => {
                        'name'      => 'mn_tt',
                        'label'     => __ 'Generate document',
                        'underline' => 0,
                        'key'       => 'Alt-G',
                        'sep'       => 'none',
                    },
                    '6' => {
                        'name'      => 'mn_qt',
                        'label'     => __ 'Quit',
                        'underline' => '1',
                        'key'       => 'Ctrl+Q',
                        'sep'       => 'before',
                    },
                },
            },
            'menu_admin' => {
                'id'        => '5008',
                'label'     => __ 'Admin',
                'underline' => '1',
                'popup'     => {
                    '1' => {
                        'name'      => 'mn_mn',
                        'label'     => __ 'Default app',
                        'underline' => 0,
                        'key'       => undef,
                        'sep'       => 'none',
                    },
                    '2' => {
                        'name'      => 'mn_cf',
                        'label'     => __ 'Configurations',
                        'underline' => 0,
                        'key'       => undef,
                        'sep'       => 'none',
                    },
                    '3' => {
                        'name'      => 'mn_er',
                        'label'     => __ 'Reports data',
                        'underline' => 0,
                        'key'       => undef,
                        'sep'       => 'before',
                    },
                    '4' => {
                        'name'      => 'mn_et',
                        'label'     => __ 'Templates data',
                        'underline' => 0,
                        'key'       => undef,
                        'sep'       => 'none',
                    },
                },
            },
            'menu_help' => {
                'id'        => '5009',
                'label'     => __ 'Help',
                'underline' => 0,
                'popup'     => {
                    '1' => {
                        'name'      => 'mn_gd',
                        'label'     => __ 'Manual',
                        'underline' => 0,
                        'key'       => undef,
                        'sep'       => 'none',
                    },
                    '2' => {
                        'name'      => 'mn_ab',
                        'label'     => __ 'About',
                        'underline' => 0,
                        'key'       => undef,
                        'sep'       => 'none',
                    }
                },
            },
        };
    },
    handles => {
        ids_in_menu    => 'keys',
        get_menu       => 'get',
    },
);

__PACKAGE__->meta->make_immutable;

1;
