#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use Getopt::Std;
use Cwd;


my $dir_root = "AnalysisData/";
my $dist = "${dir_root}FileNumPerGroup.txt";

chomp(my @subs = `find $dir_root -mindepth 1 -maxdepth 1 -type d`);

my $groupCountT=0;
my $fileCountT=0;

foreach my $sub (@subs) {

	print "Processing [$sub]...\n";

	my $stat_root = "$sub/Statistics/";
	my $distri = "${stat_root}FileNumPerGroup.txt";
	my $srcUniqList = "${stat_root}SrcUniqList.txt";

	my $groupCount=0;
	my $fileCount=0;
	open(FILE, "<$srcUniqList") or die $!;
	while(<FILE>) {
		chomp;

		my $list=$_ . "/list.txt";
		chomp(my $count=`wc -l '$list'`);
		$fileCount += $count;

		$groupCount++;
	}
	close(FILE);

	$groupCountT+=$groupCount;
	$fileCountT+=$fileCount;
	
	my $avg=$fileCount/$groupCount;

	open(FILE, ">$distri") or die $!;
	print FILE "$sub\nGroupTotal: $groupCount\nFileCount: $fileCount\nAvg: $avg\n";
	close(FILE);
#	exit;
}

my $avgT=$fileCountT/$groupCountT;
open(FILE, ">$dist") or die $!;
print FILE "GroupTotal: $groupCountT\nFileCount: $fileCountT\nAvg: $avgT\n";
close(FILE);
