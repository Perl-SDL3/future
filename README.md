# NAME

Alien::SDL3 - Build and install SDL3, SDL3\_mixer, SDL3\_image, and SDL3\_ttf

# SYNOPSIS

```perl
use Alien::SDL3;

my $alien = Alien::SDL3->new;
say $alien->cflags;
say $alien->libs;
say $alien->ffi_lib;
```

# DESCRIPTION

Alien::SDL3 acquires `libsdl3`, `libsdl3_mixer`, `libsdl3_image`, and `libsdl3_ttf` via
[xrepo](https://xrepo.xmake.io/) in a single build. It is a subclass of [Alien::Xrepo::Base](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABase).

# METHODS

## `package_name( )`

```perl
my $package = Alien::SDL3->package_name;
```

Returns the primary `xrepo` package name, `libsdl3`.

## `package_names( )`

```perl
my @packages = Alien::SDL3->new->package_names;
```

Returns the `xrepo` package names installed by this distribution: `libsdl3`, `libsdl3_mixer`, `libsdl3_image`, and
`libsdl3_ttf`.

## `install_opts( )`

Options passed to [Alien::Xrepo](https://metacpan.org/pod/Alien%3A%3AXrepo) when each package is installed during the `Build` process.

## `package_infos( )`

```perl
my @infos = Alien::SDL3->new->package_infos;
```

Returns an [Alien::Xrepo::PackageInfo](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3APackageInfo) object for each installed package.

## `cflags( )`

Compiler flags for all four libraries.

## `libs( )`

Linker flags for all four libraries.

## `ffi_libs( )`

Absolute paths to the shared library of each installed package.

## `dynamic_libs( )`

The library files for all installed packages.

# SEE ALSO

[Alien::Xrepo::Base](https://metacpan.org/pod/Alien%3A%3AXrepo%3A%3ABase), [Alien::Xrepo](https://metacpan.org/pod/Alien%3A%3AXrepo), [Affix](https://metacpan.org/pod/Affix), [SDL3](https://metacpan.org/pod/SDL3)

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson &lt;https://github.com/sanko>
