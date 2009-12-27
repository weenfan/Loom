package Loom::Test::SHA256;
use strict;
use Loom::Digest::SHA256;

=pod

=head1 NAME

Test suite for SHA-256 hash

=cut

sub new
	{
	my $class = shift;
	my $TOP = shift;

	my $s = bless({},$class);
	$s->{TOP} = $TOP;
	return $s;
	}

sub run
	{
	my $s = shift;

	$s->test_hash(
	"",
	"e3b0c442 98fc1c14 9afbf4c8 996fb924 27ae41e4 649b934c a495991b 7852b855",
	"(null string)"
	);

	$s->test_hash(
	"a",
	"ca978112 ca1bbdca fac231b3 9a23dc4d a786eff8 147c4e72 b9807785 afee48bb",
	);

	$s->test_hash(
	"abc",
	"ba7816bf 8f01cfea 414140de 5dae2223 b00361a3 96177a9c b410ff61 f20015ad"
	);

	$s->test_hash(
	"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
	"248d6a61 d20638b8 e5c02693 0c3e6039 a33ce459 64ff2167 f6ecedd4 19db06c1"
	);

	$s->test_hash(
	'z' x 127,
	"87cdeb38 0917879f cd4c3b86 9ad644cb c7cbc6ff 36b989cd 4fe0f812 3c13ca19",
	"127 'z's"
	);

	$s->test_hash(
	'z' x 128,
	"8169c725 edd39f00 140ffcf5 7c45b9c5 143e2ffe 375869e4 cf280534 2715d2b1",
	"128 'z's"
	);

	$s->test_hash(
	'z' x 255,
	"d8f9abad 0f43ffe2 fce0032f d245bfc9 8edbdab8 e222f7b6 c313a35a bfd2782a",
	"255 'z's"
	);

	$s->test_hash(
	'z' x 256,
	"fcc01087 70388f35 2679507f fcf73b79 716e81ff 5c20f9bf 5257af73 7d001514",
	"256 'z's"
	);

	$s->test_hash(
	'a' x 1000000,
	"cdc76e5c 9914fb92 81a1c7e2 84d73e67 f1809a48 a497200e 046d39cc c7112cd0",
	"(a million 'a's)"
	);

	$s->test_hash(
	"93a4bcfb69824c901bd2ba64bd7cc522",
	"e90c1415 102c3b4d 6c6e74b9 15490a4d ddf8f254 4aea91eb 796eddfe de86ec39"
	);

	$s->test_hash(
	"93a4bcfb69824c901bd2ba64bd7cc5224b603c6c76132927caccb2ff5a4f04e2",
	"6b58c709 8bc8c04d cd6e35c3 f84e8482 316b12d2 62fb1044 5e4f330a e9a1e7d1"
	);


	$s->test_hash(
	"242f361b178cf8b8be6ce8f994c2de9da401c0cfe805ec058b2415288c218fa83d3134afd9963a1086b0eda4f034471e",
	"f46db532 c3e2c1dc 0228d035 726e852e 230ab090 5af5af57 417cebfc 345b4ab8"
	);

	# try some purely binary hashes

	$s->test_hash_binary(
		pack("H*", "6646a8e353ec71267c7e7cddd61fb2d2") .
		pack("H*", "6717d4dbc6870edb8fd2f748266e1e0d"),

		"dabdcde4 2e39979f 83a6a459 b29829d6 41f942f9 ca40fd7c c756cc4b 05eb5798",
		);

	$s->test_hash_binary(
		pack("H*", "f8001edf1496b5c6fab743ac17aaa0ef") .
		pack("H*", "00000000000000000000000000000002"),
		"ed7f2294 1cbee85d 27fb5268 29b79509 a6088648 2da4dd00 c42a11a3 ad9ac9b8",
		);

	$s->test_hash_binary(
		pack("H*", "00000000000000000000000000000000") .
		pack("H*", "00000000000000000000000000000000"),
		"66687aad f862bd77 6c8fc18b 8e9f8e20 08971485 6ee233b3 902a591d 0d5f2925",
		);

	$s->test_hash_binary(
		pack("H*", "ffffffffffffffffffffffffffffffff") .
		pack("H*", "ffffffffffffffffffffffffffffffff"),
		"af961376 0f72635f bdb44a5a 0a63c39f 12af30f9 50a6ee5c 971be188 e89c4051",
		);
	}

sub test_hash_binary
	{
	my $s = shift;
	my $str = shift;
	my $expected = shift;

	$s->test_hash($str, $expected, "(packed binary) ".unpack("H*", $str));
	}

sub test_hash
	{
	my $s = shift;

	my $str = shift;
	my $expected = shift;
	my $str_desc = shift;

	my $hash = Loom::Digest::SHA256->new->sha256_hex($str);

	# double-check against binary version of sha256 as well.
	{
	my $check = $hash;
	$check =~ s/ //g;
	my $h2 = unpack("H*",Loom::Digest::SHA256->new->sha256($str));

	die if $h2 ne $check;
	}

	my $gpg_hash = $s->GPG_sha256_hex($str);

	print "---\n";

	if (!defined $str_desc)
		{
		print "str:\n";
		print "  $str\n";
		}
	else
		{
		print "str:  $str_desc\n";
		}

	print "hash:\n";
	print "  $hash\n";
	print "expected:\n";
	print "  $expected\n";
	print "GPG says:\n";
	print "  $gpg_hash\n";

	if ($hash eq $expected && $expected eq $gpg_hash)
		{
		print "Correct.\n";
		}
	elsif ($expected ne $gpg_hash)
		{
		print "=======> OOPS!!!!\n";
		print "The result from GPG did not match your expected value:\n";
		print "  $expected\n";
		die;
		}
	else
		{
		print "=======> OOPS!!!!!\n";
		die;
		}
	print "\n";
	}

sub GPG_sha256_hex
	{
	my $s = shift;
	my $str = shift;

	my $fh;

	if (open($fh,"-|"))
		{
		my $hash = <$fh>;
		chomp $hash;
		close($fh);
		return lc($hash);
		}
	else
		{
		my $fh;
		if (open($fh,"|gpg --no-secmem-warning --print-md sha256"))
			{
			print $fh $str;
			close($fh);
			}
		exit;
		}
	}

return 1;

__END__

# Copyright 2006 Patrick Chkoreff
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions
# and limitations under the License.
