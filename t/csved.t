#!perl -w

use IPC::Run qw(run);
use Test::More;

my(@command) = ('perl', '../csved');

sub TestOK
{
	my($opts, $in, $expected_out, $msg) = @_;
	my $out;
	is(run([ @command, @$opts ], \$in, \$out), 1, "$msg (exec)");
	is($out, $expected_out, "$msg (output)");
}

sub TestFail
{
	my($opts, $in, $expected_err_re, $msg) = @_;
	my($out, $err);
	isnt(run([ @command, @$opts ], \$in, \$out, \$err), 1, "$msg (exec)");
	like($err, $expected_err_re, "$msg (error message)");
}

TestOK([ '$F[1] = 2' ], "0,1,3\n", "0,2,3\n", "replace value");
TestOK([ '++$F[1]' ], "0,1,2\n3,4,5\n", "0,2,2\n3,5,5\n", "calculate");
TestOK([ '@F = reverse @F' ], "0,1,2\n3,4,5\n", "2,1,0\n5,4,3\n", "reorder");
TestOK([ '@F = @F[0,2]' ], "0,1,2\n3,4,5\n", "0,2\n3,5\n", "select");
TestOK([ 'delete $F[1]' ], "0,1,2\n3,4,5\n", "0,2\n3,5\n", "delete");
TestOK([ '-h', 'delete $F{"b"}' ],
	"a,b,c\n0,1,2\n3,4,5\n",
	"a,c\n0,2\n3,5\n",
	"delete by name");
TestOK([ '-h', '@F = @F{"a","c"}' ],
	"a,b,c\n0,1,2\n3,4,5\n",
	"a,c\n0,2\n3,5\n",
	"select by name");
TestFail([ '-h', '++$F{d}' ],
	"a,b,c\n0,1,2\n3,4,5\n",
	qr/^d: No such field name/,
	"nonexisting field name");
TestFail([ '-h', '' ],
	"a,a,c,,\n",
	qr/^Duplicate field names: 'a?', 'a?'/,	# order is random
	"duplicate field names");
TestOK([ 'unshift @F, scalar @F' ],
	"a,b,c\nd\ne,f\n",
	"3,a,b,c\n1,d\n2,e,f\n",
	"scalar");
TestOK([ '-h', 'delete $F[2]; unshift @F, scalar %F' ],
	"a,b,c\nd\ne,f,g,h\n",
	"2,a,b\n1,d\n3,e,f,h\n",
	"delete via \@F and scalar via \%F");
TestOK([ 'unshift @F, exists $F[1]' ],
	"a,b,c\n1\n2,3\n4,5,6\n",
	"1,a,b,c\n,1\n1,2,3\n1,4,5,6\n",
	"exists");
TestOK([ '-h', 'unshift @F, exists $F{b}' ],
	"a,b,c\n1\n2,3\n4,5,6\n",
	"1,a,b,c\n,1\n1,2,3\n1,4,5,6\n",
	"exists by name");
TestOK([ '$F[5] = $.' ],
	"a,b,c\n1\n2,3\n4,5,6,0,7\n\n",
	"a,b,c,1\n1,2\n2,3,3\n4,5,6,0,7,4\n,5\n",
	"spare array");
TestOK([ '$F[0] = $.' ],
	"\n9\n8,7\n,5,6\n",
	"1\n2\n3,7\n4,5,6\n",
	"line number");
TestOK([ '-h', '++$F[0] if $. > 1' ],
	"0,b\n0,1,2\n3,4,5\n",
	"0,b\n1,1,2\n4,4,5\n",
	"check line number");
TestOK([ '-h', 'if ($. > 1) { $F{$_} = "$_=$F{$_}" foreach keys %F; }' ],
	"x,y,z\n1,2,3\n",
	"x,y,z\nx=1,y=2,z=3\n",
	"keys");
TestOK([ '-h',
	'if ( $. > 1 ) { $a = 0; $a += $_ foreach values %F; push @F, $a; }' ],
	"x,y,z\n1,2,3\n",
	"x,y,z\n1,2,3,6\n",
	"values");
TestOK([ '-n', 'say $F[0] if $F[1] > 5' ],
	"4,5\n6,7\n1,2\n8,9\n",
	"6\n8\n",
	"-n option");

done_testing();

