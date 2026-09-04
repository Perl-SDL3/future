requires 'Alien::Xrepo';
requires 'Alien::Xrepo::Base', '0.000010';
requires 'File::ShareDir',     '1.00';
requires 'Path::Tiny';
requires 'perl', '5.040000';
recommends 'Affix';
on configure => sub {
    requires 'Alien::Xmake';
    requires 'Alien::Xrepo';
    requires 'Alien::Xrepo::Base', '0.000010';
    requires 'CPAN::Meta';
    requires 'Config';
    requires 'ExtUtils::Helpers', '0.028';
    requires 'IO::Socket::SSL';
    requires 'JSON::PP', '2';
    requires 'Path::Tiny';
};
on build => sub {
    requires 'Alien::Xrepo::Base', '0.000010';
    requires 'CPAN::Meta';
    requires 'ExtUtils::Install';
    requires 'ExtUtils::InstallPaths', '0.002';
    requires 'JSON::PP',               '2';
    requires 'Path::Tiny';
};
on test => sub {
    requires 'Test2::V0';
    recommends 'Affix';
};
