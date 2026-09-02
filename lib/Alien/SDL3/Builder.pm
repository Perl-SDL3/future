use v5.40;
use experimental 'class';

class Alien::SDL3::Builder 0.01 {
    use CPAN::Meta;
    use ExtUtils::Install qw[install];
    use ExtUtils::InstallPaths;
    use Path::Tiny;
    use JSON::PP;
    use Alien::Xrepo;
    #
    field $alien_class : param;
    field $action      : param  //= 'build';
    field $argv        : param  //= [];
    field $meta        : reader //= CPAN::Meta->load_file('META.json');
    field $verbose     : param  //= 0;
    #
    method execute() {
        my $method = 'ACTION_' . $action;
        if ( $self->can($method) ) {
            $self->$method();
        }
        else {
            die 'No such action: ' . $action;
        }
    }

    method ACTION_build() {
        say 'Building ' . $meta->name;
        path('blib/lib')->mkpath;
        path('blib/arch')->mkpath;
        $self->_copy_libs();
        my $config_data = $self->_resolve_alien();
        $self->_write_config_data($config_data);
        say 'Build complete';
    }

    method ACTION_test() {
        $self->ACTION_build();
        say 'Running tests...';
        require Test::Harness;
        my @tests = sort map { $_->stringify } path('t')->children;
        Test::Harness::runtests(@tests) if @tests;
    }

    method ACTION_install() {
        say 'Installing...';
        my $ip = ExtUtils::InstallPaths->new( dist_name => $meta->name );
        install( $ip->install_map, 1, 0, 0 );
    }

    method ACTION_clean() {
        say 'Cleaning...';
        path('blib')->remove_tree;
        path('_build_params')->remove;
        path('Build')->remove;
        path('MYMETA.json')->remove;
        path('MYMETA.yml')->remove;
    }

    method _copy_libs() {
        my $src_root = path('lib');
        return unless $src_root->exists;
        my $iter = $src_root->iterator( { recurse => 1 } );
        while ( my $file = $iter->() ) {
            next unless $file->is_file;
            my $rel = $file->relative($src_root);
            next if $rel =~ m{(^|/)\.};
            my $dest = path('blib/lib')->child($rel);
            $dest->parent->mkpath;
            $file->copy($dest) or die 'Copy failed: ' . $!;
        }
    }

    method _resolve_alien() {
        eval "require $alien_class; 1" or die "Could not load $alien_class: $@";
        my $alien     = $alien_class->new;
        my %opts      = $alien->can('install_opts') ? $alien->install_opts : ();
        my $dist_name = $meta->name;
        my $share_dir = path('blib/lib/auto/share/dist')->child($dist_name)->absolute;
        $share_dir->mkpath;
        my $repo = Alien::Xrepo->new( root => $share_dir->stringify, verbose => $verbose );
        my $make_rel = sub ($p) {
            return undef unless defined $p;
            my $path = path($p);
            return $path->relative($share_dir)->stringify if $share_dir->subsumes($path);
            return $path->stringify;
        };
        my %data;
        for my $pkg ( $alien->package_names ) {
            say "Installing $pkg via Xrepo into $share_dir";
            my $info = $repo->install( $pkg, undef, %opts );
            $data{$pkg} = {
                version     => $info->version,
                kind        => $info->kind,
                links       => $info->links,
                libfiles    => [ map { $make_rel->($_) } @{ $info->libfiles    // [] } ],
                includedirs => [ map { $make_rel->($_) } @{ $info->includedirs // [] } ],
                linkdirs    => [ map { $make_rel->($_) } @{ $info->linkdirs    // [] } ],
                bindirs     => [ map { $make_rel->($_) } @{ $info->bindirs     // [] } ],
                libpath     => $make_rel->( $info->libpath ),
                installdir  => $make_rel->( $info->installdir ),
                license     => $info->license,
                shared      => $info->shared ? 1 : 0,
                static      => $info->static ? 1 : 0
            };
        }
        return \%data;
    }

    method _write_config_data($data) {
        my $package       = $alien_class . '::ConfigData';
        my @parts         = split( /::/, $package );
        my $target_config = path('blib/lib')->child( @parts[ 0 .. $#parts - 1 ] )->child( $parts[-1] . '.pm' );
        $target_config->parent->mkpath;
        my $json = encode_json($data);
        $json =~ s/\\/\\\\/g;
        $json =~ s/'/\\'/g;
        my $depth   = scalar(@parts);
        my $content = sprintf <<~'PERL', $package, $meta->name, $depth, $json;
        package %s {
            use v5.40;
            use JSON::PP qw[decode_json];
            use File::ShareDir qw[dist_dir];
            use Path::Tiny qw[path];
            my $dist_name = '%s';
            my $depth     = %d;
            my $config    = decode_json('%s');
            my $share_dir;
            try {
                $share_dir = path( dist_dir($dist_name) );
            } catch ($e) {
                $share_dir = path(__FILE__)->parent($depth)->child('auto', 'share', 'dist', $dist_name);
            }
            my $make_abs = sub ($p) {
                return undef unless defined $p;
                return $p if path($p)->is_absolute;
                return $share_dir->child($p)->stringify;
            };
            sub config ($class, $key //= ()) {
                state $expanded = do {
                    my $copy = {};
                    for my $pkg (keys %%$config) {
                        my $c = $config->{$pkg};
                        $copy->{$pkg} = {
                            %%$c,
                            libpath     => $make_abs->($c->{libpath}),
                            installdir  => $make_abs->($c->{installdir}),
                            includedirs =>[ map { $make_abs->($_) } @{ $c->{includedirs} // [] } ],
                            linkdirs    =>[ map { $make_abs->($_) } @{ $c->{linkdirs} // [] } ],
                            bindirs     =>[ map { $make_abs->($_) } @{ $c->{bindirs} // [] } ]
                        };
                    }
                    $copy;
                };
                defined $key ? $expanded->{$key} : $expanded;
            }
            sub package ($class, $pkg = undef) {
                $pkg //= (keys %%$config)[0];
                return __PACKAGE__->config->{$pkg};
            }
        };
        1;
        PERL
        $target_config->spew_utf8($content);
        say "Generated $target_config";
    }
}
1;