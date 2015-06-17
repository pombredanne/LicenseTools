#!/usr/bin/perl

use File::Basename;
use DBI;
use List::MoreUtils 'first_index';
use strict;


my $src_root = @ARGV[0];
my $stat_root = @ARGV[1];
my $ext = @ARGV[2];
# my $startPkgName = @ARGV[0];


my $database = "${stat_root}files.db";

if (-e $database) {
  exit 0;
}

my $driver   = "SQLite"; 
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, { AutoCommit => 0, RaiseError => 1 }) or die $DBI::errstr;


my $stmt = qq(CREATE TABLE IF NOT EXISTS FILE
       (PATH       TEXT    NOT NULL,
       HASH       TEXT););
my $rv = $dbh->do($stmt);
if($rv < 0){
   print $DBI::errstr;
}

my $sth = $dbh->prepare('INSERT INTO FILE (PATH) VALUES (?)');


print "Making .$ext file list...\n";

my @files=`find $src_root -name '*.$ext' -type f`;

 my $startTime=time();
foreach my $file (@files) {

  chomp $file;

  # print "Inserting ($file)\n";
  my @values=($file);
  $sth->execute(@values);

}
 $dbh->commit;

 my $timePassed = time() - $startTime;
 print "[${timePassed}s used]\n";

$dbh->disconnect();


