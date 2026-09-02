use v5.40;
use experimental 'class';
class Alien::SDL3 v0.0.1 : isa(Alien::Xrepo::Base) {
    use Path::Tiny qw[path];
    use JSON::PP 2 qw[encode_json decode_json];
    use Alien::Xrepo::Base ();
    method package_name ()  {'libsdl3'}
    method package_names () {qw[libsdl3 libsdl3_mixer libsdl3_image libsdl3_ttf]}
    method install_opts ()  { return ( kind => 'shared' ) }

    method package_infos () {
        my $class = ref($self) . '::ConfigData';
        return () unless $class->can('config');
        my $config = $class->config or return ();
        my @out;
        for my $name ( $self->package_names ) {
            my $c = $config->{$name} or next;
            push @out, Alien::Xrepo::PackageInfo->new(%$c);
        }
        @out;
    }

    method includedirs () {
        my %seen;
        map { !$seen{$_}++ ? $_ : () } map { @{ $_->includedirs // [] } } $self->package_infos;
    }

    method linkdirs () {
        my %seen;
        map { !$seen{$_}++ ? $_ : () } map { @{ $_->linkdirs // [] } } $self->package_infos;
    }

    method links () {
        my %seen;
        map { !$seen{$_}++ ? $_ : () } map { @{ $_->links // [] } } $self->package_infos;
    }

    method cflags () {
        my %seen;
        join ' ', map {"-I$_"} grep { !$seen{$_}++ } $self->includedirs;
    }

    method libs () {
        my %seen;
        my @dirs = grep { !$seen{$_}++ } $self->linkdirs;
        my @libs = grep { !$seen{$_}++ } $self->links;
        join ' ', ( map {"-L$_"} @dirs ), ( map {"-l$_"} @libs );
    }

    method dynamic_libs () {
        my %seen;
        map { !$seen{$_}++ ? $_ : () } map { @{ $_->libfiles // [] } } $self->package_infos;
    }

    method ffi_libs () {
        my %seen;
        map { !$seen{$_}++ ? $_ : () } grep {defined} map { $_->libpath } $self->package_infos;
    }

    method bin_dir () {
        my %seen;
        map { !$seen{$_}++ ? $_ : () } map { $_->bin_dir } $self->package_infos;
    }
    }
    #
    1;
