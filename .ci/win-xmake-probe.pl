use v5.36;
use Capture::Tiny qw(capture);
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(getcwd);

$| = 1;

sub find_lua ( $dir, $depth = 0 ) {
    my @hits;
    return () if $depth > 14;
    opendir my $dh, $dir or return ();
    for my $e ( grep { $_ !~ /^\.\.?$/ } readdir $dh ) {
        my $p = File::Spec->catdir( $dir, $e );
        if ( -d $p && -l $p == 0 ) { push @hits, find_lua( $p, $depth + 1 ); }
        elsif ( $e eq 'xmake.lua' && -f $p ) { push @hits, $p; }
    }
    closedir $dh;
    return @hits;
}

sub diag ( $tag ) {
    say "\n[DIAG $tag] cwd=" . getcwd();
    opendir my $dh, '.';
    say "[DIAG $tag] '.' entries: " . join( ', ', sort grep { $_ !~ /^\.+$/ } readdir $dh );
    closedir $dh;
    if ( -f 'xmake.lua' ) {
        open my $fh, '<:raw', 'xmake.lua' or die "open xmake.lua: $!";
        local $/;
        my $content = <$fh>;
        close $fh;
        say "[DIAG $tag] xmake.lua bytes=" . length( $content // '' );
        say "[DIAG $tag] xmake.lua content:\n$content";
    }
    else {
        say "[DIAG $tag] no xmake.lua in cwd";
    }
    for my $k ( sort grep { /^XMAKE|^TEMP|^TMP|^LOCALAPPDATA|^USERPROFILE/ } keys %ENV ) {
        say "[DIAG $tag] ENV $k=[$ENV{$k}]";
    }
    my $xm = $ENV{LOCALAPPDATA} . '\\.xmake';
    if ( -d $xm ) {
        my @found = find_lua($xm);
        say "[DIAG $tag] .xmake xmake.lua files: " . ( scalar @found || 'none' );
        for my $f (@found) {
            open my $fh, '<:raw', $f;
            local $/;
            my $c = <$fh>;
            close $fh;
            say "[DIAG $tag] FILE $f bytes=" . length( $c // '' );
            say "[DIAG $tag] FILE $f content:\n$c" if length( $c // '' ) < 4000;
        }
    }
    else {
        say "[DIAG $tag] no $xm";
    }
    my $txm = $ENV{TEMP} . '\\.xmake';
    if ( -d $txm ) {
        my @tfound = ( find_lua($txm) );
        say "[DIAG $tag] TEMP\\.xmake lua files: " . ( scalar @tfound || 'none' );
        for my $f (@tfound) {
            open my $fh, '<:raw', $f;
            local $/;
            my $c = <$fh>;
            close $fh;
            say "[DIAG $tag] TFILE $f bytes=" . length( $c // '' );
            say "[DIAG $tag] TFILE $f content:\n$c" if length( $c // '' ) < 4000;
        }
    }
    else {
        say "[DIAG $tag] no TEMP\\.xmake";
    }
}
say "== win-xmake-probe ==";
say "perl=$^X :: $^O :: v$]";

use Alien::Xmake;
my $exe = $ENV{XMAKE_PROBE_EXE} ? $ENV{XMAKE_PROBE_EXE} : Alien::Xmake->new->exe;
say "exe=[$exe]";
say "exe exists=" . (-e $exe ? 1 : 0) . " size=" . (-s $exe // 'undef');
say "exe has space=" . ($exe =~ / / ? 1 : 0);

my %res;
sub try ( $label, $code ) {
    my $out;
    my $ok = eval {
        local $SIG{__DIE__};
        ( $out ) = $code->();
        1;
    };
    $res{$label} = { ok => $ok, err => $@ // '', out => ( $out // '' ) };
    say "RESULT $label ok=" . ($ok ? 1 : 0) . ($ok ? '' : " ERR=$@");
}

try 'list-version' => sub {
    return ( system( $exe, '--version' ) == 0 ? "rc0\n" : "rc" . ($? >> 8) . "\n" );
};

try 'string-version' => sub {
    my $cmd = qq{"$exe" --version};
    my $rc = system $cmd;
    return ( $rc == 0 ? "rc0\n" : "rc" . ($rc >> 8) . " errno=$!\n" );
};

try 'qx-version' => sub {
    my $out = qx{"$exe" --version};
    my $rc  = $? >> 8;
    return ( $rc == 0 ? "rc0 outlen=" . length($out) . "\n" : "rc$rc\n" );
};

try 'capture-list-version' => sub {
    my ( $out, $err, $exit ) = capture { system( $exe, '--version' ) };
    return ( $exit == 0 ? "rc0 outlen=" . length($out) . "\n" : "rc$exit err=$err" );
};

# Isolate every xrepo scratch project (incl. the add-repo `create working`
# scaffold) under probe-temp so the probe itself never poisons the CI job's
# real %TEMP%\.xmake -- the very bug it exists to pin down.
my $real_tmp  = $ENV{TEMP};
my $tmp       = tempdir( 'xprobe-XXXX', CLEANUP => 1, TMPDIR => 1 );
my $probe_tmp = File::Spec->catdir( $tmp, 'probe-temp' );
mkdir $probe_tmp or die "mkdir $probe_tmp: $!" unless -d $probe_tmp;
$ENV{TEMP} = $probe_tmp;
$ENV{TMP}  = $probe_tmp;

# add-repo using a bogus URL: proves the FIRST xmake spawn path works
try 'capture-addrepo' => sub {
    my ( $out, $err, $exit ) = capture {
        system( $exe, 'lua', 'private.xrepo', 'add-repo', '-y', 'probe-repo', 'http://127.0.0.1:9/nope.git' );
    };
    return "exit=$exit err=[$err] fullout_len=" . length($out) . "\nFULLOUT:\n$out\n";
};

diag('after-addrepo');

# The wrapper's install() path is functionally: xmake lua private.xrepo install -y
# <flags> <pkg>. Flags include --extra={system=false} which triggers xmake's OWN
# re-exec of itself. Probe that exact shape in a scratch project.
open my $fh, '>', File::Spec->catfile( $tmp, 'xmake.lua' ) or die "open: $!";
print {$fh} qq{add_requires("zlib")\ntarget("p")\n    set_kind("static")\n};
close $fh;
chdir $tmp or die "chdir $tmp: $!";

try 'capture-install-plain' => sub {
    my ( $out, $err, $exit ) = capture {
        local $ENV{XMAKE_THEME} = 'plain';
        system( $exe, 'lua', 'private.xrepo', 'install', '-y', 'zlib' );
    };
    return "exit=$exit err_tail=[$err] out_len=" . length($out) . "\nOUT_TAIL:\n" . substr( $out, -1200 ) . "\n";
};

diag('after-install-plain');

try 'capture-install-tmp' => sub {
    my ( $out, $err, $exit ) = capture {
        local $ENV{XMAKE_THEME} = 'plain';
        local $ENV{TEMP}        = $probe_tmp;
        local $ENV{TMP}         = $probe_tmp;
        system( $exe, 'lua', 'private.xrepo', 'install', '-y', 'zlib' );
    };
    return "exit=$exit err_tail=[$err] out_len=" . length($out) . "\nOUT_TAIL:\n" . substr( $out, -1200 ) . "\n";
};

say "\n[DIAG probe-temp]== dir /s /b of real TEMP\\.xmake ==";
say qx{cmd /c dir /s /b "$real_tmp\\.xmake"} if -d "$real_tmp\\.xmake";
say "[DIAG after-install-tmp] cwd=" . getcwd();
my @probe_hits = find_lua($probe_tmp);
say "[DIAG after-install-tmp] probe-temp .xmake lua files: " . ( scalar @probe_hits || 'none' );
for my $f (@probe_hits) {
    open my $fh2, '<:raw', $f;
    local $/;
    my $c = <$fh2>;
    close $fh2;
    say "[DIAG after-install-tmp] FILE $f bytes=" . length( $c // '' );
    say "[DIAG after-install-tmp] FILE $f content:\n$c" if length( $c // '' ) < 4000;
}
opendir( my $pd, $probe_tmp );
say "[DIAG after-install-tmp] probe-temp/.xmake entries: " . join( ', ', grep { $_ !~ /^\.+$/ } readdir $pd );
closedir $pd;

try 'capture-install-extra' => sub {
    my ( $out, $err, $exit ) = capture {
        local $ENV{XMAKE_THEME} = 'plain';
        system( $exe, 'lua', 'private.xrepo', 'install', '-y', '--extra={system=false}', 'zlib' );
    };
    return "exit=$exit err_tail=[$err] out_len=" . length($out) . "\nOUT_TAIL:\n" . substr( $out, -1200 ) . "\n";
};

diag('after-install-extra');

try 'capture-list-repo' => sub {
    local $ENV{XMAKE_THEME} = 'plain';
    my ( $out, $err, $exit ) = capture {
        system( $exe, 'lua', 'private.xrepo', 'list-repo' );
    };
    return "exit=$exit err=[$err] out_len=" . length($out) . "\nOUT_TAIL:\n" . substr( $out, -1200 ) . "\n";
};

diag('after-list-repo');

say "\n== SUMMARY ==";
for my $k ( sort keys %res ) {
    my $r = $res{$k};
    say "--- $k ---";
    say "ok=" . ($r->{ok} ? 1 : 0) . " err=" . ( $r->{err} // '' );
    print $r->{out};
}
say "== probe done ==";