#!/usr/bin/perl

use strict;
use File::Path qw(make_path);
use Time::Seconds;
use Time::Piece;

# Read configs
open my $cfg, "<config.txt" or die "config.txt file needed.";
open my $log, ">log.txt";

my $src_root = GetCfg();
my $exts = GetCfg();
my $threshold = GetCfg();
close $cfg;

my @exts= split(/,/, $exts);

# Const define
my $data_root = "AnalysisData/";
my $stat_root = "${data_root}Statistics/";
my $copied_src = "${data_root}Source/";
my $licenseChange = "${stat_root}LicenseChanged.csv";

if (!-d $stat_root) {
	# print "make_path($stat_root);\n";
	make_path($stat_root);
}

if (!-d $copied_src) {
	make_path($copied_src);
}
 
open my $licFh, ">$licenseChange";

my $ext = 'java';

my $oldTime;
my $newTime;
my $timeDiff;


$oldTime = localtime;

print "Listing files of folder: $src_root\n";
print `collect_info/list_files.pl $src_root $stat_root $ext`;

$newTime = localtime;
$timeDiff = $newTime - $oldTime;
print $log "Listing used: ". $timeDiff->seconds ." sec(s)\n";


$oldTime = localtime;

print "Generating hash values for token files...\n";
print `collect_info/gen_hash.pl $stat_root $ext`;

$newTime = localtime;
$timeDiff = $newTime - $oldTime;
print $log "Generating Hash used: ". $timeDiff->seconds ." sec(s)\n";



$oldTime = localtime;

print "Copying files...\n";
my $dest_dir = $copied_src.$ext;
print `copy_files/copy_files.pl $dest_dir $stat_root $ext`;

$newTime = localtime;
$timeDiff = $newTime - $oldTime;
print $log "Copying used: ". $timeDiff->seconds ." sec(s)\n";

my $licenseDetectionTime = 0;
my $changeDetectionTime = 0;

my @folders = `find $dest_dir -mindepth 1 -maxdepth 1 -type d`;

foreach my $folder (@folders) {

	chomp $folder;

	$oldTime = localtime;
	 print "License detection: [$folder]";
	`find $folder -name '*$ext' | xargs NinkaWrapper.pl -s -x -o $folder -- 2>/dev/null`;
	$newTime = localtime;
	$timeDiff = $newTime - $oldTime;
	$licenseDetectionTime += $timeDiff->seconds;

	$oldTime = localtime;
#			 print "analyse/check_license_result.pl -d $folder\n";
	my $inconsis = `analyse/check_license_result.pl -d $folder`;
	$newTime = localtime;
	$timeDiff = $newTime - $oldTime;
	$changeDetectionTime += $timeDiff->seconds;

	if ($inconsis) {
		print " <-----Inconsistent!";

		my ($fileNum, $licNum, $noneNum, $unknownNum, $familyNum, $gplNum, $bsdNum, $apacheNum, $licStr) =split(/#/, $inconsis);	
		my $metrics="$folder,$fileNum,$licNum,$noneNum,$unknownNum,$familyNum,$gplNum,$bsdNum,$apacheNum,\"$licStr\"";
		print $licFh "$metrics\n";
	}
	else {
		print " OK.";
	}
	print "\n";
}

print "\n";
print $log "Ninka:[$licenseDetectionTime] Incon:[$changeDetectionTime]\n";


close $licFh;

#print $log "Copying:[$copyTime] Grouping:[$groupTime] Ninka:[$licenseDetectionTime] Incon:[$changeDetectionTime]\n";

close $log;

sub GetCfg
{
	my $line = <$cfg>;
	chomp $line;
	return $line;
}

