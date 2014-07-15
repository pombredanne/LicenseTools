#!/usr/bin/perl

#use Getopt::Std;
use File::Basename;
use DBI;
use strict;


my $ext = $ARGV[0];

my $driver   = "SQLite"; 
my $database = "files.db";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;

my $stmt="";
if ($ext) {
$stmt = qq(SELECT BASENAME, EXT, COUNT(*)  from FILE WHERE EXT = '$ext' GROUP BY BASENAME,EXT ORDER BY COUNT(*) DESC;);
} else {
$stmt = qq(SELECT BASENAME, EXT, COUNT(*)  from FILE GROUP BY BASENAME,EXT ORDER BY COUNT(*) DESC;);
}
#print $stmt;
my $sth = $dbh->prepare( $stmt );
my $rv = $sth->execute() or die $DBI::errstr;
if($rv < 0){
   print $DBI::errstr;
}

my $filename = "stats".$ext.".txt";
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";


while(my @row = $sth->fetchrow_array()) {
 
 print $fh $row[0] .";" . $row[1] .";" . $row[2] .";\n";
}

close $fh;

$dbh->disconnect();
