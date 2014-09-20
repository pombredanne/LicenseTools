#!/usr/bin/perl

#use Getopt::Std;
use File::Basename;
use DBI;
use strict;


my $file = $ARGV[0];
my $stat_root = $ARGV[1];
my $filelist = $ARGV[2];

(my $name,my $path,my $ext) = fileparse($file,qr"\..[^.]*$");

#print "[$file][$name][$ext][$filelist]\n";

my $database = "${stat_root}files.db";

my $driver   = "SQLite"; 
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;


my $stmt = qq(SELECT PKGNAME, PATH from FILE WHERE BASENAME = '$name' AND EXT = '$ext';);
# print "$stmt\n";

my $sth = $dbh->prepare( $stmt );
my $rv = $sth->execute() or die $DBI::errstr;
if($rv < 0){
   print $DBI::errstr;
}

open(my $fh, '>', $filelist) or die "Can't open for write: $filelist!\n";

while(my @row = $sth->fetchrow_array()) {
 
 #print "$row[0]$row[1];$row[2]\n";
 print $fh "$row[0];$row[1]$file\n";
}

print "Result list generated!\n";

close $fh;


$dbh->disconnect();
