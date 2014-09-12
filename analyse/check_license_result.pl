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

my $prevLicense = '';
my $hasDiff = 0;

my @row = $sth->fetchrow_array();
$prevLicense = $row[0];

while(@row = $sth->fetchrow_array()) {

	if ($prevLicense ne $row[0]) {
		$hasDiff = 1;
		last;
	}
	$prevLicense = $row[0];
}

$sth->finish();

$dbh->disconnect();
					  
print $hasDiff;



