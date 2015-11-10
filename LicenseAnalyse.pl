#!/usr/bin/perl

use strict;
use File::Path qw(make_path);
use Time::Seconds;
use Time::Piece;

# Read configs
open my $cfg, "<config.txt" or die "config.txt file needed.";
open my $log, ">>log.txt";

my $src_root = GetCfg();
my $extension = GetCfg();
my $threshold = GetCfg();
close $cfg;

my @exts= split(/,/, $extension);

foreach my $ext (@exts) {

if ($ext eq "cpp") {
#next;
}

if (!$ext) {
	next;
}

# Const define
my $data_root = "AnalysisData/$ext/";
my $stat_root = "${data_root}Statistics/";
my $copied_src = "${data_root}Source/";
my $licenseChange = "${stat_root}LicenseChanged.csv";
my $srcUniqList = "${stat_root}SrcUniqList.txt";

if (!-d $stat_root) {
	# print "make_path($stat_root);\n";
	make_path($stat_root);
}

if (!-d $copied_src) {
	make_path($copied_src);
}

#next; # open this when make dir only.

#my $ext = 'java';

my $oldTime;
my $newTime;
my $timeDiff;


$oldTime = localtime;

print "Listing [$ext] files of folder: $src_root\n";
print `collect_info/make_filelist.pl $src_root $stat_root $ext`;

$newTime = localtime;
$timeDiff = $newTime - $oldTime;
print $log "Listing $ext used: ". $timeDiff->seconds ." sec(s)\n";


$oldTime = localtime;

print "Generating [$ext] token files...\n";
print `collect_info/gen_tokens.pl $stat_root $ext`;


$newTime = localtime;
$timeDiff = $newTime - $oldTime;
print $log "Generating token files used: ". $timeDiff->seconds ." sec(s)\n";


$oldTime = localtime;

print "Generating hash value of token files...\n";
print `collect_info/gen_hashes.pl $stat_root $ext`;

$newTime = localtime;
$timeDiff = $newTime - $oldTime;
print $log "Generating hash value used: ". $timeDiff->seconds ." sec(s)\n";


$oldTime = localtime;

print "Grouping files...\n";
my $dest_dir = $copied_src;
#print "`group/group_files.pl $dest_dir $stat_root $threshold`\n";
print `group/group_files.pl $dest_dir $stat_root $threshold`;

$newTime = localtime;
$timeDiff = $newTime - $oldTime;
print $log "Grouping used: ". $timeDiff->seconds ." sec(s)\n";


if (!-e $srcUniqList) {
   `find $dest_dir -mindepth 1 -maxdepth 1 -type d > '$srcUniqList'`;
}


$oldTime = localtime;

print "Copying files...\n";
#print "copy_files/copy_files.pl $dest_dir $stat_root $ext";
#print `copy_files/copy_files.pl $dest_dir $stat_root $ext $threshold`;

$newTime = localtime;
$timeDiff = $newTime - $oldTime;
print $log "Copying used: ". $timeDiff->seconds ." sec(s)\n";


$oldTime = localtime;

print "License detection...\n";
#print "copy_files/copy_files.pl $dest_dir $stat_root $ext";
print `analyse/license_analyse_no_copy.pl $stat_root '$srcUniqList'`;

$newTime = localtime;
$timeDiff = $newTime - $oldTime;
print $log "License analysis used: ". $timeDiff->seconds ." sec(s)\n";


$oldTime = localtime;

print "Check license results...\n";
print `analyse/batch_check_license_result.pl '$licenseChange' '$srcUniqList'`;


$newTime = localtime;
$timeDiff = $newTime - $oldTime;
my $changeDetectionTime = $timeDiff->seconds;

print "\n";
print $log "Incon:[$changeDetectionTime]\n";


}


close $log;

sub GetCfg
{
	my $line = <$cfg>;
	chomp $line;
	return $line;
}

