use v5.40;
use experimental 'class';

class Alien::SDL3 0.01 : isa(Alien::Xrepo::Base) {
    use Path::Tiny qw[path];
    use JSON::PP 2 qw[encode_json decode_json];
    use Alien::Xrepo::Base ();
    method package_name () { 'libsdl3' }

    method package_names () { qw[libsdl3 libsdl3_mixer libsdl3_image libsdl3_ttf] }

    method install_opts () {
        return (
            kind => 'shared',
        );
    }

    method package_infos () {
        my $class  = ref($self) . '::ConfigData';
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
        join ' ', map { "-I$_" } grep { !$seen{$_}++ } $self->includedirs;
    }

    method libs () {
        my %seen;
        join ' ', map { "-L$_" } grep { !$seen{$_}++ } $self->linkdirs, map { "-l$_" } $self->links;
    }

    method dynamic_libs () {
        my %seen;
        map { !$seen{$_}++ ? $_ : () } map { @{ $_->libfiles // [] } } $self->package_infos;
    }

    method ffi_libs () {
        my %seen;
        map { !$seen{$_}++ ? $_ : () } grep { defined } map { $_->libpath } $self->package_infos;
    }

    method bin_dir () {
        my %seen;
        map { !$seen{$_}++ ? $_ : () } map { $_->bin_dir } $self->package_infos;
    }

    # Build support

    sub Build_PL ($alien_class) {
        use CPAN::Meta;
        use Config;
        use ExtUtils::Helpers qw[make_executable];
        my $meta = CPAN::Meta->load_file('META.json');
        say sprintf 'Creating new Build script for %s %s (%s)', $meta->name, $meta->version, $alien_class;
        my $perl5lib = join( $Config{path_sep}, @INC );
        path('Build')->spew_raw( sprintf <<'EOF', $^X, $perl5lib, $alien_class, $alien_class, $alien_class );
#!%s
BEGIN { $ENV{PERL5LIB} = '%s' }
use lib 'lib';
use %s;
%s::Build('%s');
EOF
        make_executable('Build');
        path('_build_params')->spew_raw( encode_json( [ \@ARGV, $alien_class ] ) );
        $meta->save(@$_) for ['MYMETA.json'];
    }

    sub Build ( $alien_class = undef ) {
        require Alien::SDL3::Builder;
        my $action = shift @ARGV // 'build';
        if ( !$alien_class && -e '_build_params' ) {
            my $params = decode_json( path('_build_params')->slurp_raw );
            $alien_class = $params->[1];
        }
        Alien::SDL3::Builder->new( alien_class => $alien_class, action => $action, argv => \@ARGV )->execute();
    }
}
1;

=encoding utf-8

=head1 NAME

Alien::SDL3 - Build and install SDL3, SDL3_mixer, SDL3_image, and SDL3_ttf

=head1 SYNOPSIS

    use Alien::SDL3;

    my $alien = Alien::SDL3->new;
    say $alien->cflags;
    say $alien->libs;
    say $alien->ffi_lib;

=head1 DESCRIPTION

Alien::SDL3 acquires C<libsdl3>, C<libsdl3_mixer>, C<libsdl3_image>, and C<libsdl3_ttf> via
L<xrepo|https://xrepo.xmake.io/> in a single build. It is a subclass of L<Alien::Xrepo::Base>.

=head1 METHODS

=head2 C<package_name( )>

    my $package = Alien::SDL3->package_name;

Returns the primary C<xrepo> package name, C<libsdl3>.

=head2 C<package_names( )>

    my @packages = Alien::SDL3->new->package_names;

Returns the C<xrepo> package names installed by this distribution:
C<libsdl3>, C<libsdl3_mixer>, C<libsdl3_image>, and C<libsdl3_ttf>.

=head2 C<install_opts( )>

Options passed to L<Alien::Xrepo> when each package is installed during the C<Build> process.

=head2 C<package_infos( )>

    my @infos = Alien::SDL3->new->package_infos;

Returns an L<Alien::Xrepo::PackageInfo> object for each installed package.

=head2 C<cflags( )>

Compiler flags for all four libraries.

=head2 C<libs( )>

Linker flags for all four libraries.

=head2 C<ffi_libs( )>

Absolute paths to the shared library of each installed package.

=head2 C<dynamic_libs( )>

The library files for all installed packages.

=head1 SEE ALSO

L<Alien::Xrepo::Base>, L<Alien::Xrepo>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson <https://github.com/sanko>

=cut