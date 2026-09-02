use v5.40;
use Test2::V0;
use blib;
use Alien::SDL3;
use experimental 'class';
#
# Simulate a build where libsdl3_ttf could not be built/installed (e.g. a missing
# transitive link dependency) so the ConfigData records an error instead of a library.
class Alien::SDL3::NoTTF : isa(Alien::SDL3) {
}

package Alien::SDL3::NoTTF::ConfigData {
    use v5.40;
    sub _ok ($version, $link) {
        { includedirs => [], libfiles    => [], license => 'unknown', linkdirs => [],
          links       => [$link], shared => 1, static  => 0, version => $version,
          installdir  => 'C:/fake/' . $link };
    }
    my %config = (
        libsdl3       => _ok( '3.4.12', 'SDL3' ),
        libsdl3_mixer => _ok( '3.2.4', 'SDL3_mixer' ),
        libsdl3_image => _ok( '3.4.0', 'SDL3_image' ),
        libsdl3_ttf   => { error  => 'link failed: BZ2_bzDecompress (libbz2)' },
    );
    sub config ($class)                { \%config }
    sub package ($class, $pkg = undef) { $config{$pkg} }
}
#
my $broken = Alien::SDL3::NoTTF->new;
#
is [ $broken->missing_packages ], [qw[libsdl3_ttf]], 'missing_packages reports the unavailable ffi library';
is $broken->package_error('libsdl3_ttf'), 'link failed: BZ2_bzDecompress (libbz2)', 'package_error carries the install error';
ok !defined $broken->package_error('libsdl3'), 'installed libraries have no recorded error';
is [ map { $_->version } $broken->package_infos ], [ '3.4.12', '3.2.4', '3.4.0' ], 'unavailable library is excluded from package_infos';
is [ $broken->links ], [qw[SDL3 SDL3_mixer SDL3_image]], 'unavailable library is excluded from links';
is +[ $broken->ffi_libs ], [], 'no ffi library for the failed package';
#
my $good = Alien::SDL3->new;
is [ $good->missing_packages ], [], 'a full install has nothing missing';
#
done_testing;