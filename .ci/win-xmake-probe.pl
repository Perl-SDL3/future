use v5.36;
use Capture::Tiny qw(capture);
use File::Temp qw(tempdir);
use File::Spec;

$| = 1;
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

# add-repo using a bogus URL: proves the FIRST xmake spawn path works
try 'capture-addrepo' => sub {
    my ( $out, $err, $exit ) = capture {
        system( $exe, 'lua', 'private.xrepo', 'add-repo', '-y', 'probe-repo', 'http://127.0.0.1:9/nope.git' );
    };
    return "exit=$exit err=[$err] fullout_len=" . length($out) . "\n";
};

# The wrapper's install() path is functionally: xmake lua private.xrepo install -y
# <flags> <pkg>. Flags include --extra={system=false} which triggers xmake's OWN
# re-exec of itself. Probe that exact shape in a scratch project.
my $tmp = tempdir( 'xprobe-XXXX', CLEANUP => 1, TMPDIR => 1 );
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

try 'capture-install-extra' => sub {
    my ( $out, $err, $exit ) = capture {
        local $ENV{XMAKE_THEME} = 'plain';
        system( $exe, 'lua', 'private.xrepo', 'install', '-y', '--extra={system=false}', 'zlib' );
    };
    return "exit=$exit err_tail=[$err] out_len=" . length($out) . "\nOUT_TAIL:\n" . substr( $out, -1200 ) . "\n";
};

say "\n== SUMMARY ==";
for my $k ( sort keys %res ) {
    my $r = $res{$k};
    say "--- $k ---";
    say "ok=" . ($r->{ok} ? 1 : 0) . " err=" . ( $r->{err} // '' );
    print $r->{out};
}
say "== probe done ==";