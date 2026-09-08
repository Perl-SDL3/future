use v5.40;
use lib 'lib';
use Alien::SDL3::Builder;

Alien::SDL3::Builder->new(
    module_name  => 'Alien::SDL3',
    dist_version => 'v0.0.1',
    license      => 'artistic_2',
    dist_author  => 'Sanko Robinson',
    requires     => {
        'Alien::Xrepo::Build' => 'v1.0.0',
        'File::ShareDir'      => '0',
        'Path::Tiny'          => '0'
    }
)->create_build_script;
