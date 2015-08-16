#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use Getopt::Std;
use Cwd;


my $dir_root = "AnalysisData/";

chomp(my @subs = `find $dir_root -mindepth 1 -maxdepth 1 -type d`);

foreach my $sub (@subs) {

	print "Processing [$sub]...\n";

	my $src_root = "$sub/Source/";
	my $stat_root = "$sub/Statistics/";
	my $inconList = "${stat_root}LicenseChanged.csv";
	my $inconListSorted = "${stat_root}LicenseChanged.sorted.csv";
	my $inconListHash = "${stat_root}LicenseChanged.hash.csv";
	my $errList = "${stat_root}LicenseChanged.error.csv";
	my $hashTable = "${stat_root}hash_map.txt";


	if (!-e $inconListSorted) {
	  print "Sorting $inconList...\n";
	  `cat $inconList | sort -n > $inconListSorted`;
	}

	my $lastProcessedGroup=-1;

	if (-e $inconListHash) {
	  chomp(my $lastLine=`tail -n 1 $inconListHash`);
	  (my $hash, my $r) = split(/,/,$lastLine);
	  if ($r) {
	    $lastProcessedGroup = $r;
	  }
	}

	print "lastProcessedGroup: $lastProcessedGroup\n";

	chomp(my $totalGroups=`wc -l < '$inconListSorted'`);

	open(my $inconFH, "<$inconListSorted") or die$!;
	open(my $hashFH, ">>$inconListHash");

	my $count=1;
	while(<$inconFH>) {

		chomp;
		(my $groupNum) = split(/,/);

		if ($groupNum <= $lastProcessedGroup) {
			print "Skip $groupNum\r";
			$count++;
			next;
		}

		print "Processing $groupNum [$count/$totalGroups]\n";

		my $list="${src_root}$groupNum/list.txt";
		my $hash;

		if (-e $list) {
			chomp(my $file=`head -n 1 '$list'`);
			my @r=`grep '$file,' $hashTable` if ($file);
			my $num=@r;
			if ($num==1) {
				my $line=$r[0];
				($hash)=split(/,/,$line) if ($line);
			} else {
				# exception.
				`echo '$list,$file\n' >> $errList`;
			}
		} else {
			`echo '$list,\n' >> $errList`;
		}

		print $hashFH "$hash,$_\n";
		$count++;
	}

	close($inconFH);
	close($hashFH);
}
