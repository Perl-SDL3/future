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
        # Override the bundled xmake-repo recipe for libsdl3_ttf (see
        # recipes/libsdl3_ttf/xmake.lua) so a statically-linked system freetype
        # on macOS links its private pkg-config dependencies.
        my $recipe = path(__FILE__)->absolute->parent(3)->child( 'recipes', 'libsdl3_ttf', 'xmake.lua' )->stringify;
        return ( kind => 'shared', includes => $recipe );
    }
}
#
1;
