#!/usr/bin/perl

use strict;
use File::Path qw(make_path);
use Time::Seconds;
use Time::Piece;

open my $log, ">log.txt";

# Const define
my $data_root = "AnalysisData/";
my $stat_root = "${data_root}Statistics/";
my $copied_src = "${data_root}Source/";
my $licenseChange = "${stat_root}LicenseChanged.csv";
my $licenseChangeNew = "${stat_root}LicenseChanged_refined.csv";

if (!-d $stat_root) {
	# print "make_path($stat_root);\n";
	make_path($stat_root);
}

if (!-d $copied_src) {
	die "Source file don't exsit!\n";
}
 
open my $licSrc, "<$licenseChange";
open my $licFh, ">$licenseChangeNew";

my $oldTime;
my $newTime;
my $timeDiff;

my $changeDetectionTime=0;

# my @folders = `find ${copied_src} -type d -name 'src_uniq_*'`;
my @folders;

while(<$licSrc>) {
	(my $filename, my $path) = split(/,/, $_);
	push(@folders, $path);
}


$oldTime = localtime;
foreach my $folder (@folders) {

	chomp $folder;

	$folder =~ /$copied_src(.*?)\/src_uniq_(\d)/;
	my $src_name = $1;
	my $group_num = $2;

	print "Check inconsistency for: [$folder]";
	my $inconsis = `analyse/check_license_result.pl -d $folder`;

	if ($inconsis) {
		print " <-----Inconsistent!";
		print $licFh "${src_name}_${group_num},$inconsis\n";
	}
	else {
		print " OK.";
	}
	print "\n";
}

$newTime = localtime;
$timeDiff = $newTime - $oldTime;
$changeDetectionTime = $timeDiff->seconds;

print $log "Incon:[$changeDetectionTime]\n";

close $licFh;
close $licSrc;

close $log;
