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
my $hasNONE=0;
my $Lic1='';
my $Lic2=0;

my $prevLicense = '';
my $inconsis = 0;

my @row = $sth->fetchrow_array();
chomp $row[0];
$prevLicense = $row[0];

if ($row[0] eq "NONE") {
	$hasNONE = 1;
} else {
	$Lic1 = $row[0];
}

while(@row = $sth->fetchrow_array()) {
chomp $row[0];

	if ($row[0] eq "NONE") {
		$hasNONE = 1;
	} else {
		if ($prevLicense ne $row[0]) {

			if (!$Lic1) {
				$Lic1 = $row[0];
			} elsif ($row[0] ne $Lic1) {

				$Lic2 = $row[0];

				if ($hasNONE) {
					# Now have NONE, L1, L2.
					last;
				}
			}
		}
	}
	$prevLicense = $row[0];
}

if (($hasNONE && !$Lic1 && !$Lic2) || (!$hasNONE && $Lic1 && !$Lic2) ) {
	$inconsis = '';
} elsif (!$hasNONE && $Lic1 && $Lic2) {
	$inconsis = 'M';
} elsif ($hasNONE && $Lic1 && !$Lic2) {
	$inconsis = 'R';
} elsif ($hasNONE && $Lic1 && $Lic2) {
	$inconsis = 'A';
} else {
	$inconsis = 'UNKNOWN';
}

print $inconsis;

$sth->finish();
$dbh->disconnect();

