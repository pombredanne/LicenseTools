#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use Getopt::Std;
use Cwd;


my $dir_root = "AnalysisData/";
my $dist = "${dir_root}FileNumPerGroup.csv";

chomp(my @subs = `find $dir_root -mindepth 1 -maxdepth 1 -type d`);

my $txt;

foreach my $sub (@subs) {

	print "Processing [$sub]...\n";

	my $stat_root = "$sub/Statistics/";
	my $srcUniqList = "${stat_root}SrcUniqList.txt";

	open(FILE, "<$srcUniqList") or die $!;
	while(<FILE>) {
		chomp;

		my $list=$_ . "/list.txt";
		chomp(my $count=`wc -l < '$list'`);
		$txt .= "$sub,$_,$count\n";

	}
	close(FILE);


#	exit;
}

open(FILE, ">$dist") or die $!;
print FILE $txt; 
close(FILE);
