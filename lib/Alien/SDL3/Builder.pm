package Alien::SDL3::Builder;
use v5.40;
use parent qw[Module::Build];
use Path::Tiny;
our $VERSION = 'v0.0.1';

sub check_manifest { }

sub ACTION_build {
    my $self = shift;

    #~ require Alien::Xrepo::Build;
    #~ my $dist = $self->dist_name;
    #~ my $snapshot = path( $self->blib, 'lib', 'auto', 'share', 'dist' )
    #~ ->child($dist)
    #~ ->child('xrepo-snapshot.json');
    #~ $snapshot->parent->mkpath;
    #~ Alien::Xrepo::Build->new(
    #~ recipe   => $self->base_dir,
    #~ snapshot => $snapshot->stringify,
    #~ verbose  => $self->verbose
    #~ )->run;
    require Alien::Xrepo;
    my $repo = Alien::Xrepo->new( verbose => 1 );
    $repo->install( 'libsdl3',       undef, kind => 'shared' );
    $repo->install( 'libsdl3_mixer', undef, kind => 'shared' );
    $repo->install( 'libsdl3_image', undef, kind => 'shared' );
    $repo->install( 'libsdl3_ttf',   undef, kind => 'shared' );
    #
    $self->SUPER::ACTION_build(@_);
    return 0;
}
1;
