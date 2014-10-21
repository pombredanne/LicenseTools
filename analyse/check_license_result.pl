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
my $oneCount=0;
my $twoCount=0;

my $familiesCount=0;
my $gpl=0;
my $bsd=0;
my $apache=0;

my @otherFamilies=();

my $inconsis=0;
my $prevLic='';

while(@row = $sth->fetchrow_array()) {
	chomp $row[0];
	my $current = $row[0];

	if ($prevLic!='' && $prevLic != $current) {
		$inconsis = 1;
	}

	CountLicense($current);

	if (MyContain($current, 'GPL')) {
		$gpl++;
	} elsif (MyContain($current, 'BSD')) {
		$bsd++;
	} elsif (MyContain($current, 'Apache')) {
		$apache++;
	} else {
		if (! ($current ~~ @otherFamilies)) {
			push(@otherFamilies, $current);
			$familiesCount++;
		}
	}

	$prevLic = $current;
}

if ($gpl > 0) {
	$familiesCount++;
}
if ($bsd > 0) {
	$familiesCount++;
}
if ($apache > 0) {
	$familiesCount++;
}

if (!$inconsis) {
	print "$noneCount,$oneCount,$twoCount,$familiesCount,$gpl,$bsd,$apache";
}

$sth->finish();
$dbh->disconnect();

sub CountLicense {
	my($lic) = @_;

	if ($lic eq "NONE") {
		$noneCount++;
	} elsif(MyContain($lic, 'and')
		|| MyContain($lic, 'or') ) {

		$twoCount++;
	} else {
		$oneCount++;
	}
}

sub MyContain {
	my($str, $substr) = @_;

	return index($str, $substr) != -1;
}