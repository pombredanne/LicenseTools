#!/usr/bin/perl

use strict;
use DBI;
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

my $database = "${stat_root}InconsistencyMetrics.db";


if (!-d $stat_root) {
	# print "make_path($stat_root);\n";
	make_path($stat_root);
}

if (!-d $copied_src) {
	die "Source file don't exsit!\n";
}


my $driver   = "SQLite"; 
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, { AutoCommit => 0, RaiseError => 1 }) or die $DBI::errstr;

my $stmt = qq(CREATE TABLE IF NOT EXISTS INCONSIST
       (FILE_GROUP       TEXT    NOT NULL,
       FILE_NUM       INTEGER    NOT NULL,
       LICENSE_NUM       INTEGER    NOT NULL,
       FAMILY_NUM       INTEGER    NOT NULL,
       GPL_NUM       INTEGER    NOT NULL,
       BSD_NUM       INTEGER    NOT NULL,
       APACHE_NUM       INTEGER    NOT NULL,
       LICENSE_STRING      TEXT    NOT NULL););
my $rv = $dbh->do($stmt);
if($rv < 0){
   print $DBI::errstr;
}

my $sth = $dbh->prepare('INSERT INTO INCONSIST (FILE_GROUP, FILE_NUM, 
  LICENSE_NUM, FAMILY_NUM, GPL_NUM, BSD_NUM, APACHE_NUM, LICENSE_STRING) 
  VALUES (?, ?, ?, ?, ?, ?, ?, ?)');

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
		my $fileGroup="${src_name}_${group_num}";
		#print $licFh "${fileGroup},$inconsis\n";

		my ($fileNum, $licNum, $familyNum, $gplNum, $bsdNum, $apacheNum, $licStr) =split(/#/, $inconsis);
		my @values=($fileGroup, $fileNum, $licNum, $familyNum, $gplNum, $bsdNum, $apacheNum, $licStr);
		$sth->execute(@values);
	
		my $metrics="$fileGroup,$fileNum,$licNum,$familyNum,$gplNum,$bsdNum,$apacheNum,\"$licStr\"";
		print $licFh "$metrics\n";
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

$dbh->commit;
$dbh->disconnect();

close $licFh;
close $licSrc;

close $log;
