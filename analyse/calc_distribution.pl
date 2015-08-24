#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use Getopt::Std;
use Cwd;


my $dir_root = "AnalysisData/";
my $dist = "${dir_root}Distribution.txt";

chomp(my @subs = `find $dir_root -mindepth 1 -maxdepth 1 -type d`);

my $larT=0;
my $lcT=0;
my $ludT=0;
my $totalT=0;

foreach my $sub (@subs) {

	print "Processing [$sub]...\n";

	my $stat_root = "$sub/Statistics/";
	my $inconList = "${stat_root}LicenseChanged.csv";
	my $distri = "${stat_root}Distribution.txt";

	my $lar=0;
	my $lc=0;
	my $lud=0;
	my $total=0;
	open(FILE, "<$inconList") or die $!;
	while(<FILE>) {
		chomp;
		my @arr = split(/#/);
#print "$arr[2],$arr[4],$arr[5]\n";
		if ($arr[2] > 0) {
			$lar++;
		}
		if ($arr[4] > 1) {
			$lc++;
		}
		if ($arr[5] > 1) {
			$lud++;
		}
		$total++;
	}
	close(FILE);

	$larT+=$lar;
	$lcT+=$lc;
	$ludT+=$lud;
	$totalT+=$total;

	open(FILE, ">$distri") or die $!;
	print FILE "LAR: $lar\nLC: $lc\nLUD: $lud\nTotal:$total\n";
	close(FILE);
#	exit;
}

open(FILE, ">$dist") or die $!;
print FILE "LAR: $larT\nLC: $lcT\nLUD: $ludT\nTotal:$totalT\n";
close(FILE);
