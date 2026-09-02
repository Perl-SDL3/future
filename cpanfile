requires 'perl', '5.040000';
requires 'File::ShareDir', '1.00';
requires 'Path::Tiny';
requires 'Alien::Xrepo', '0.08';

on configure => sub {
    requires 'Alien::Xmake', '0.08';
    requires 'Alien::Xrepo', '0.08';
    requires 'CPAN::Meta';
    requires 'Config';
    requires 'ExtUtils::Helpers', '0.028';
    requires 'JSON::PP', '2';
    requires 'Path::Tiny';
};

on build => sub {
    requires 'Alien::Xrepo', '0.08';
    requires 'CPAN::Meta';
    requires 'ExtUtils::Install';
    requires 'ExtUtils::InstallPaths', '0.002';
    requires 'JSON::PP', '2';
    requires 'Path::Tiny';
};

on test => sub {
    requires 'Test2::V0';
};