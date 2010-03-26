package Loom::Test::File;
use strict;

=pod

=head1 NAME

Stress test for concurrent file operations

=cut

use Getopt::Long;
use Loom::DB::Trans_File;
use Loom::File;
use Loom::Random;

sub new
	{
	my $class = shift;
	my $arena = shift;

	my $s = bless({},$class);
	$s->{arena} = $arena;
	$s->{show_final} = !$arena->{embedded};
	return $s;
	}

sub get_options
	{
	my $s = shift;

	if ($s->{arena}->{embedded})
		{
		$s->{count} = $s->{arena}->{count};
		$s->{delay} = $s->{arena}->{delay};
		$s->{verbose} = $s->{arena}->{verbose};
		return;
		}

	my $opt = {};
	my $ok = GetOptions($opt, "v", "d=n");
	$s->{verbose} = $opt->{v};
	$s->{delay} = $opt->{d};

	$s->{count} = $ARGV[0];

	$ok &&= defined $s->{count};
	$ok &&= $s->{count} =~ /^\d+$/;

	if (!$ok)
		{
		my $prog_name = $0;
		$prog_name =~ s#.*/##;

		print STDERR <<EOM;
Usage: $prog_name count [-v] [-d N]

count : number of processes to spawn
-v    : verbose output
-d N  : insert delay of N cycles to increase test coverage (default 100000)
EOM
		exit(2);
		}

	return;
	}

sub run
	{
	my $s = shift;

	$s->get_options;

	# Seed the random number generator.  If you don't seed it, you can get
	# repeatable sequences, which might be useful in some cases.
	#
	# When we spawn each child process, we call "rand" to generate a seed
	# for that process.  Then the child calls "srand" with the given seed.  
	#
	# Strangely, if we *don't* do that, and we happen to call "rand" here in
	# the parent process (which we normally don't), it seems to destroy any
	# entropy when calling rand in the child processes.  The stress test is
	# not shaken up enough, and you see all the child processes banging away
	# on just two specific locations.  Very bizarre and intricate behavior
	# there, but easily avoided by just calling srand in each child.

	srand( Loom::Random->new->get_ulong );

	my $TOP = $s->{arena}->{TOP};
	die if !defined $TOP;

	$s->{testdir} = Loom::File->new("$TOP/test");

	my $prog_name = $0;
	$prog_name =~ s#.*/##;

	$s->{data} = $s->{testdir}->child($prog_name);
	$s->{data}->create_path;

	$s->{data}->remove_tree;

	$s->{data}->create_dir;
	$s->{data}->restrict;

	# Insert a deliberate delay into the file module if nonzero.
	$s->{delay} = 100000 if !defined $s->{delay};
	$s->{data}->{delay} = $s->{delay} if $s->{delay} != 0;

	# Now wrap a put/get transaction object around the data directory.
	$s->{db} = Loom::DB::Trans_File->new($s->{data});

	if ($s->{data}->type ne "d")
		{
		print STDERR <<EOM;
Could not create the data directory.
EOM
		exit(1);
		}

	# I find that using 3 locations is pretty good.  Using 2 locations is
	# boring, and using more than 3 locations results in less contention.

	$s->{locs} = [qw(A B C)];
	#$s->{locs} = [qw(A B C D E F)];
	#$s->{locs} = [qw(A B)];
	#$s->{locs} = [qw(A/a/../1 B/b/../2/../../../Q)];  # too far up

	#$s->{locs} = [qw(A/a/../1 7/b/../2/../../Q)];
		# This is weird but OK.  It just normalizes to A/1 and Q.

	#$s->{locs} = [qw(A /tmp/B)];
		# This doesn't fool Loom::File.  It just normalizes to A and
		# tmp/B.

	# Now let's spawn all the children and wait for them to finish.

	$s->spawn_children($s->{count});
	$s->wait_children;

	# Display the final values, check for integrity, and clean up.

	print "\nFinal values:\n" if $s->{show_final};
	my $sum = 0;
	for my $name (@{$s->{locs}})
		{
		my $file = $s->{data}->child($name);

		my $val = $file->get;

		if ($s->{show_final})
			{
			my $q_val = defined $val ? $val : "undef";
			my $q_name = $file->local_path;
			print "$q_name : $q_val\n";
			}

		$sum += $val if defined $val && $val ne "";
		}

	print "sum = $sum\n" if $s->{show_final};

	if ($sum == 0)
		{
		# Success!
		$s->{data}->remove_tree;
		$s->{testdir}->remove_dir;  # remove empty test dir if possible
		return 0;
		}
	else
		{
		# Uh oh ... failure!
		print STDERR <<EOM;

!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!! CHECKSUM ERROR !!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!

EOM
		exit(3);
		}
	}

sub spawn_children
	{
	my $s = shift;
	my $count = shift;

	$s->{pid_table} = {};

	for my $child_no (1 .. $count)
		{
		my $seed = int rand(1000000);

		my $child = fork();

		if (defined $child && $child == 0)
			{
			my $option =
				{
				child_no => $child_no,
				seed => $seed,
				db => $s->{db},
				locs => $s->{locs},
				verbose => $s->{verbose},
				};

			Loom::Test::File::Child->new($option)->run;
			exit;
			}

		if (!defined $child)
			{
			print STDERR "Too many children! (Only spawned ".($child_no-1).")\n";
			return 0;
			}

		$s->{pid_table}->{$child} = $child_no;
		}

	return 1;
	}

# Wait for all children to finish.

sub wait_children
	{
	my $s = shift;

	while (1)
		{
		my $child = waitpid(-1, 0);
		last if $child <= 0;

		# Child process $child just finished.
		}
	}

package Loom::Test::File::Child;
use strict;

sub new
	{
	my $class = shift;
	my $option = shift;

	my $s = bless({},$class);
	$s->{option} = $option;

	srand($option->{seed}) if defined $option->{seed};

	return $s;
	}

sub run
	{
	my $s = shift;

	my $child_no = $s->{option}->{child_no};

	my $verbose = $s->{option}->{verbose};
	my $db = $s->{option}->{db};

	my $locs = $s->{option}->{locs};
	$locs = [@$locs];
	$s->shuffle($locs);

	my $key_orig = $locs->[0];
	my $key_dest = $locs->[1];

	print "$$ child $child_no begin\n" if $verbose;

	sleep(1);
		# If you have a lot of processes, the sleep will allow them all to be
		# created before they start doing their thing.  That creates more
		# opportunities for contention.

	my $amount = 1;

	while (1)
		{
		my $val_orig = $db->get($key_orig);
		$val_orig = 0 if $val_orig eq "";

		my $val_dest = $db->get($key_dest);
		$val_dest = 0 if $val_dest eq "";

		$val_orig -= $amount;
		$val_dest += $amount;

		$val_orig = "" if $val_orig == 0;
		$val_dest = "" if $val_dest == 0;

		$db->put($key_orig,$val_orig);
		$db->put($key_dest,$val_dest);

		print "$$ child $child_no attempt "
			."$key_orig:$val_orig "
			."$key_dest:$val_dest\n" if $verbose;

		my $ok = $db->commit;

		last if $ok;

		print "$$ child $child_no try again\n" if $verbose;
		}

	print "$$ child $child_no done\n" if $verbose;

	return;
	}

sub shuffle
	{
	my $s = shift;
	my $array = shift;

	my $i;
	for ($i = @$array; --$i;)
		{
		my $j = int rand($i+1);
		next if $i == $j;
		@$array[$i,$j] = @$array[$j,$i];
		}

	return;
	}

return 1;

__END__

# Copyright 2009 Patrick Chkoreff
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
