package Tpda3::Config::Toolbar;

# ABSTRACT: Toolbar configurations

use Mouse;
use Locale::TextDomain 1.20 qw(Tpda3);
use namespace::autoclean;


has 'toolnames' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [   "tb_fm", "tb_fe", "tb_fc", "tb_pr", "tb_gr", "tb_tn",
            "tb_tr", "tb_rr", "tb_ad", "tb_rm", "tb_sv", "tb_at",
            "tb_qt",
        ],
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
        {   tb_rr => {
                tooltip => __ 'Reload record',
                help    => __ 'Reload record',
                'icon'  => 'actreload16',
                'sep'   => 'after',
                'type'  => '_item_normal',
                'id'    => '1008',
                'state' => {
                    'rec' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                    'det' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                },
            },
            tb_fm => {
                tooltip => __ 'Toggle find mode',
                help    => __ 'Toggle find mode',
                'icon'  => 'filefind16',
                'sep'   => 'none',
                'type'  => '_item_check',
                'id'    => '1001',
                'state' => {
                    'rec' => {
                        'add'  => 'disabled',
                        'find' => 'normal',
                        'edit' => 'normal',
                        'idle' => 'normal',
                        'sele' => 'disabled',
                    },
                    'det' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'disabled',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                },
            },
            tb_qt => {
                tooltip => __ 'Quit',
                help    => __ 'Quit the application',
                'icon'  => 'actexit16',
                'sep'   => 'after',
                'type'  => '_item_normal',
                'id'    => '1013',
                'state' => {
                    'rec' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'normal',
                        'sele' => 'disabled',
                    },
                    'det' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'normal',
                        'sele' => 'disabled',
                    },
                },
            },
            tb_tr => {
                tooltip => __ 'Paste record',
                help    => __ 'Paste record',
                'icon'  => 'editpaste16',
                'sep'   => 'after',
                'type'  => '_item_normal',
                'id'    => '1007',
                'state' => {
                    'rec' => {
                        'add'  => 'normal',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                    'det' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'disabled',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                },
            },
            tb_fe => {
                tooltip => __ 'Execute search',
                help    => __ 'Execute search',
                'icon'  => 'actcheck16',
                'sep'   => 'none',
                'type'  => '_item_normal',
                'id'    => '1002',
                'state' => {
                    'rec' => {
                        'add'  => 'disabled',
                        'find' => 'normal',
                        'edit' => 'disabled',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                    'det' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'disabled',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                },
            },
            tb_sv => {
                tooltip => __ 'Save record',
                help    => __ 'Save record',
                'icon'  => 'filesave16',
                'sep'   => 'after',
                'type'  => '_item_normal',
                'id'    => '1011',
                'state' => {
                    'rec' => {
                        'add'  => 'normal',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                    'det' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                },
            },
            tb_pr => {
                tooltip => __ 'Print preview',
                help    => __ 'Print preview default report',
                'icon'  => 'fileprint16',
                'sep'   => 'none',
                'type'  => '_item_normal',
                'id'    => '1004',
                'state' => {
                    'rec' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                    'det' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                },
            },
            tb_ad => {
                tooltip => __ 'Add record',
                help    => __ 'Add record',
                'icon'  => 'actitemadd16',
                'sep'   => 'none',
                'type'  => '_item_check',
                'id'    => '1009',
                'state' => {
                    'rec' => {
                        'add'  => 'normal',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'normal',
                        'sele' => 'disabled',
                    },
                    'det' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'disabled',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                },
            },
            tb_at => {
                tooltip => __ 'Save current window geometry',
                help    => __ 'Save current window geometry',
                'icon'  => 'actattach16',
                'sep'   => 'after',
                'type'  => '_item_normal',
                'id'    => '1012',
                'state' => {
                    'rec' => {
                        'add'  => 'normal',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'normal',
                        'sele' => 'normal',
                    },
                    'det' => {
                        'add'  => 'normal',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'normal',
                        'sele' => 'normal',
                    },
                },
            },
            tb_rm => {
                tooltip => __ 'Remove record',
                help    => __ 'Remove record',
                'icon'  => 'actitemdelete16',
                'sep'   => 'none',
                'type'  => '_item_normal',
                'id'    => '1010',
                'state' => {
                    'rec' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                    'det' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'disabled',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                },
            },
            tb_gr => {
                tooltip => __ 'Generate document',
                help    => __ 'Generate default document',
                'icon'  => 'edit16',
                'sep'   => 'after',
                'type'  => '_item_normal',
                'id'    => '1005',
                'state' => {
                    'rec' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                    'det' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                },
            },
            tb_tn => {
                tooltip => __ 'Copy record',
                help    => __ 'Copy record',
                'icon'  => 'editcopy16',
                'sep'   => 'none',
                'type'  => '_item_normal',
                'id'    => '1006',
                'state' => {
                    'rec' => {
                        'add'  => 'normal',
                        'find' => 'disabled',
                        'edit' => 'normal',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                    'det' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'disabled',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                },
            },
            tb_fc => {
                tooltip => __ 'Execute count',
                help    => __ 'Execute count',
                'icon'  => 'acthelp16',
                'sep'   => 'after',
                'type'  => '_item_normal',
                'id'    => '1003',
                'state' => {
                    'rec' => {
                        'add'  => 'disabled',
                        'find' => 'normal',
                        'edit' => 'disabled',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
                    },
                    'det' => {
                        'add'  => 'disabled',
                        'find' => 'disabled',
                        'edit' => 'disabled',
                        'idle' => 'disabled',
                        'sele' => 'disabled',
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

1;
