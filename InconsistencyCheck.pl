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
my $family_folder_list = "${stat_root}FamilyFolderList.txt";

if (!-d $stat_root) {
	# print "make_path($stat_root);\n";
	make_path($stat_root);
}

if (!-d $copied_src) {
	die "Source file don't exsit!\n";
}
 
open my $licFh, ">$licenseChange";

my $oldTime;
my $newTime;
my $timeDiff;

my $changeDetectionTime=0;
my @folders;

if (!-e $family_folder_list) {
	@folders = `find ${copied_src} -type d -name 'src_uniq_*'`;
	open(my $fh, '>', $family_folder_list);
	foreach my $folder (@folders) {
		print $fh $folder;
	}
	close $fh;
	
} else {
	open(my $fh, '<', $family_folder_list);
	@folders=<$fh>;
	close $fh;
}

$oldTime = localtime;
foreach my $folder (@folders) {

	chomp $folder;

	$folder =~ /$copied_src(.*?)\/src_uniq_/;
	my $src_name = $1;

    print "Check inconsistency for: [$folder]";
	my $inconsis = `analyse/check_license_result.pl -d $folder`;

	if ($inconsis) {
		print " <-----Inconsis:[$inconsis]";
		print $licFh "$src_name,$folder,$inconsis\n";
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

close $log;

