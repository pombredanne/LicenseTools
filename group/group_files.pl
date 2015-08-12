#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use Time::Seconds;
use Time::Piece;
use List::MoreUtils qw(firstidx);


my $dest_root = $ARGV[0];
my $stat_root = $ARGV[1];
my $threshold = $ARGV[2];

my $rootFolder = ${dest_root};
if (!-d $rootFolder) {
#  print "$rootFolder not exist!\n";
 make_path($rootFolder);
}

my $hashFile="${stat_root}hash_map.txt";
my $filteredFile="${stat_root}hash_map.filtered.$threshold.txt";
my $sortedFile="${stat_root}hash_map.sorted.txt";
my $rankFile="${stat_root}hash_rank.txt";

if (!-e $hashFile) {

  print "Merge tables...\n";
  `cat ${stat_root}hash_table*.txt > $hashFile`;
}

if (!-e $filteredFile) {

	print "Filter tables...\n";

	open(FILE,"<$hashFile") or die "Can't open: $hashFile\n";
	open(my $rfh, ">$filteredFile") or die "Can't open for write: $filteredFile\n";
	while(<FILE>){
		chomp;
		my($hash,$file,$lc)=split(/,/);
		if ($lc>$threshold) {
			print $rfh "$_\n";
		}
	}
	close(FILE);
	close($rfh);
}

if (!-e $sortedFile) {
  print "Sort table...\n";
  `grep -Ev '^,' $filteredFile | sort > $sortedFile`; # Sort the hash table
}

my @topHash;

if (!-e $rankFile) {

	print "Make rank file...\n";

	chomp(my @rankings = `cat  $sortedFile | cut -d ',' -f 1 | sort | uniq -c | sort -nr`);


	my $count = 0;
	foreach my $sha (@rankings) {

		$sha =~ s/^\s+|\s+$//g;
		
	#	print "[$sha]\n";
		
		(my $number, my $hash) = split(/ /, $sha);
		
		if ($number >= 2) {
			push(@topHash, $hash);
		} else {
			last;
		}
		$count++;
	}

	@topHash=sort @topHash;

	open(my $fh, ">$rankFile");
	print $fh join("\n",@topHash),"\n";
	close($fh);
} else {
	print "Read from rank file...\n";

	open my $handle, '<', $rankFile;
	chomp(@topHash= <$handle>);
	close $handle;
}


my $total_count=@topHash;
my $group_count=0;

print "[$total_count] groups in total.\n";

foreach my $hash (@topHash) {

my $process=100*$group_count/$total_count;
my $r=sprintf("%.1f",$process);
print "[${r}%] Done. [${group_count}/${total_count}].\r";

my $groupFolder = "${rootFolder}${group_count}/";
my $fileList = "${groupFolder}list.txt";

# Make dir for group
if (!-d $groupFolder) {
 # print "$groupFolder not exist!\n";
 make_path($groupFolder);
}

if (!-e $fileList) {
`grep '$hash' '$sortedFile' | cut -d ',' -f 2 > '$fileList'`;
}

$group_count++;
}

print "\nDone.\n";
