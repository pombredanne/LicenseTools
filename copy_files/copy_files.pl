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
my $ext = $ARGV[2];
my $threshold = $ARGV[3];

my $rootFolder = ${dest_root};
if (!-d $rootFolder) {
#  print "$rootFolder not exist!\n";
 make_path($rootFolder);
}

my $hashFile="${stat_root}hash_map.txt";
my $filteredFile="${stat_root}hash_map.filtered.$threshold.txt";
my $sortedFile="${stat_root}hash_map.sorted.txt";

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

print "Get rank...\n";

chomp(my @rankings = `cat  $sortedFile | cut -d ',' -f 1 | sort | uniq -c | sort -nr`);


my @topHash;
my $count = 0;
my $totalFile=0;
foreach my $sha (@rankings) {

	$sha =~ s/^\s+|\s+$//g;
	
#	print "[$sha]\n";
	
	(my $number, my $hash) = split(/ /, $sha);
	
	if ($number >= 2) {
		$totalFile += $number;
		push(@topHash, $hash);
	} else {
		last;
	}
	$count++;
}


open my $handle, '<', $sortedFile;
chomp(my @lines = <$handle>);
close $handle;

my $prevHash = "";
my $currentFile=1;
my $group_count=-1;
my $file_index=0;
my $mapFh;

foreach my $line (@lines) {

	(my $hash, my $fileName)=split(/,/, $line);
	
	my $idx = firstidx { $_ eq $hash } @topHash;
	
	if ($idx >= 0) {

		my $process=100*$currentFile/$totalFile;
		my $r=sprintf("%.1f",$process);
		print "[${r}%] Done. [${currentFile}/${totalFile}].\r";


		if ($hash ne $prevHash) {
			$group_count++;
			$file_index=0;

			if ($mapFh) {
				close $mapFh;
				undef $mapFh;
			}

			$prevHash = $hash;
		}


		# Make dir for group
		my $groupFolder = "${rootFolder}${group_count}/";
		if (!-d $groupFolder) {
		 # print "$groupFolder not exist!\n";
		 make_path($groupFolder);
		}

		if (!$mapFh) {			
			# Create a mapping file
			my $mapping_list = "${groupFolder}mapping.txt";
			open $mapFh, ">>$mapping_list";
		}

		# Generate new file name
		(my $name, my $path, my $suffix) = fileparse($fileName,qr/\.[^.]*/);
		my $newName = "${file_index}_${name}${suffix}";

		print $mapFh "$newName,$fileName\n";

		my $newFullName = $groupFolder.$newName;
		copy($fileName, $newFullName);

		$file_index++;
		$currentFile++;	
	}

}

if ($mapFh) {
	close $mapFh;
	undef $mapFh;
}


