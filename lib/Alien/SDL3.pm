use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Base;
#
class Alien::SDL3 : isa(Alien::Xrepo::Base) {
    method pkg_name { [ 'libsdl3', 'libsdl3_image', 'libsdl3_mixer' ] }
    method install_opts {  return ( kind => 'shared'); }
}
#
1;
