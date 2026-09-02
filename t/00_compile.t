use Test2::V0;
use blib;
use Alien::SDL3;
#
diag 'Alien::SDL3::VERSION == ' . $Alien::SDL3::VERSION;
#
my $alien = Alien::SDL3->new;
isa_ok $alien, ['Alien::Xrepo::Base'], 'Alien::SDL3 subclasses Alien::Xrepo::Base';
is $alien->package_name,      'libsdl3',                                             'package_name is the core xrepo package';
is [ $alien->package_names ], [qw[libsdl3 libsdl3_mixer libsdl3_image libsdl3_ttf]], 'package_names covers all four libraries';
can_ok $alien,
    qw[package_names install_opts package_infos includedirs linkdirs links cflags libs dynamic_libs ffi_libs bin_dir install upgrade libpath ffi_lib version kind find_header package_info];
if ( my $info = $alien->package_info ) {
    isa_ok $info, ['Alien::Xrepo::PackageInfo'], 'package_info';
    diag '  - ' . ( $info->version // '?' ) . ' ' . ( $info->kind // '?' );
    diag '  - ' . $_ for grep {length} $alien->cflags;
    diag '  - ' . $_ for grep {length} $alien->libs;
}
#
done_testing;
