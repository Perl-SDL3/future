use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Base;
#
class Alien::SDL3 : isa(Alien::Xrepo::Base) {
    use Path::Tiny qw[path];

    # Bind to the SDL3 family: core + the common extension libraries. Each is
    # installed separately and exposed via the Alien::Build-style `alt()` accessor
    # (e.g. `Alien::SDL3->alt('libsdl3_ttf')->cflags`) or a package-name argument.
    method pkg_name { [ 'libsdl3', 'libsdl3_image', 'libsdl3_ttf', 'libsdl3_mixer' ] }

    method install_opts {
        # This module exists to hand SDL3's shared libraries to an FFI binding
        # (Affix). Ask for shared explicitly; the wrapper no longer forces a
        # kind, so a bare `xrepo install` would hand back archives here.
        return ( kind => 'shared' );
    }
}
#
1;