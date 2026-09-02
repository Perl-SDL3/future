requires 'Alien::Xrepo';
requires 'File::ShareDir', '1.00';
requires 'Path::Tiny';
requires 'perl', '5.040000';
on configure => sub {
    requires 'Alien::Xmake';
    requires 'Alien::Xrepo';
    requires 'Alien::Xrepo::Base';
    requires 'CPAN::Meta';
    requires 'Config';
    requires 'ExtUtils::Helpers', '0.028';
    requires 'JSON::PP',          '2';
    requires 'Path::Tiny';
};
on build => sub {
    requires 'Alien::Xrepo';
    requires 'CPAN::Meta';
    requires 'ExtUtils::Install';
    requires 'ExtUtils::InstallPaths', '0.002';
    requires 'JSON::PP',               '2';
    requires 'Path::Tiny';
};
on test => sub {
    requires 'Test2::V0';
};
