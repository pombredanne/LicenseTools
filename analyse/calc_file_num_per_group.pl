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
my $maxfileCountT=0;
my $txt;

foreach my $sub (@subs) {

	print "Processing [$sub]...\n";

	my $stat_root = "$sub/Statistics/";
	my $distri = "${stat_root}FileNumPerGroup.txt";
	my $srcUniqList = "${stat_root}SrcUniqList.txt";

	my $groupCount=0;
	my $fileCount=0;
	my $maxfileCount=0;
	open(FILE, "<$srcUniqList") or die $!;
	while(<FILE>) {
		chomp;

		my $list=$_ . "/list.txt";
		chomp(my $count=`wc -l < '$list'`);
		$fileCount += $count;
		$maxfileCount = $count>$maxfileCount ? $count : $maxfileCount;

		$groupCount++;
	}
	close(FILE);

	$groupCountT+=$groupCount;
	$fileCountT+=$fileCount;
	$maxfileCountT = $maxfileCount>$maxfileCountT ? $maxfileCount : $maxfileCountT;
	
	my $avg=$fileCount/$groupCount;

#	open(FILE, ">$distri") or die $!;
#	print FILE "$sub\nGroupTotal: $groupCount\nFileCount: $fileCount\nMaxFileCount: $maxfileCount\nAvg: $avg\n";
#	close(FILE);
#	exit;
$txt.="$sub\nGroupTotal: $groupCount\nFileCount: $fileCount\nMaxFileCount: $maxfileCount\nAvg: $avg\n";
}

my $avgT=$fileCountT/$groupCountT;
open(FILE, ">$dist") or die $!;
print FILE "GroupTotal: $groupCountT\nFileCount: $fileCountT\nMaxFileCount: $maxfileCountT\nAvg: $avgT\n\n$txt";
close(FILE);
