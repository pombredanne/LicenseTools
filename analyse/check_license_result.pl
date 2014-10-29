#!/usr/bin/perl

use strict;
use Spreadsheet::WriteExcel;
use Getopt::Long;
use DBI;

my $dbPath='';
if (!GetOptions('dbpath:s' => \$dbPath)) {
print STDERR "NinkaWrapper version 1.1

Usage $0 -d <dbPath>

  -d The database path of the result file.

\n";

    exit 1;	
}

if (substr($dbPath,-1) ne "/") {
	$dbPath = $dbPath.'/';
}

my $driver   = "SQLite";
my $database = "${dbPath}result.db";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, { AutoCommit => 0,  RaiseError => 1 })
					  or die $DBI::errstr;
					  

my $sth = $dbh->prepare('SELECT LICENSE FROM LICENSE');
my $rv = $sth->execute() or die $DBI::errstr;
if($rv < 0){
   print $DBI::errstr;
}

my $noneCount=0;
my $unknownCount=0;
my $diffLicCount=0;
my $familiesCount=0;
my $gpl=0;
my $bsd=0;
my $apache=0;

my @gplF=();
my @bsdF=();
my @apacheF=();
my @licType=();
my @otherFamilies=();

my $inconsis=0;
my $prevLic='';

my $licStr='';

my $fileCount=0;

while(my @row = $sth->fetchrow_array()) {
	chomp $row[0];
	my $current = $row[0];

	if ($prevLic ne '' && $prevLic ne $current) {
		$inconsis = 1;
	}

	if ($current eq 'NONE') {
		$noneCount++;
	} elsif ($current eq 'UNKNOWN') {
		$unknownCount++;
	} elsif (MyContain($current, 'GPL')) {
		if (! ($current ~~ @gplF)) {
			push(@gplF, $current);
			$gpl++;
		}
	} elsif (MyContain($current, 'BSD')) {
		if (! ($current ~~ @bsdF)) {
			push(@bsdF, $current);
			$bsd++;
		}
	} elsif (MyContain($current, 'Apache')) {
		if (! ($current ~~ @apacheF)) {
			push(@apacheF, $current);
			$apache++;
		}
	} else {
		if (! ($current ~~ @otherFamilies)) {
			push(@otherFamilies, $current);
			$familiesCount++;
		}
	}

	$prevLic = $current;
	$licStr = $licStr . $current . ';';
	$fileCount++;
}

$diffLicCount=$gpl+$bsd+$apache+$familiesCount;

if ($gpl > 0) {
	$familiesCount++;
}
if ($bsd > 0) {
	$familiesCount++;
}
if ($apache > 0) {
	$familiesCount++;
}

my $DEL='#';

if ($inconsis) {
	print "$fileCount$DEL
	$diffLicCount$DEL
	$$noneCount$DEL
	$$unknownCount$DEL
	$familiesCount$DEL
	$gpl$DEL
	$bsd$DEL
	$apache$DEL
	$licStr";
}

$sth->finish();
$dbh->disconnect();


sub MyContain {
	my($str, $substr) = @_;

	return index($str, $substr) != -1;
}
