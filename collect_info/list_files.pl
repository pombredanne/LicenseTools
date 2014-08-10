#!/usr/bin/perl

use File::Basename;
use DBI;
use List::MoreUtils 'first_index';
use strict;


my $src_root = @ARGV[0];
my $stat_root = @ARGV[1];
# my $startPkgName = @ARGV[0];


my $database = "files.db";

if (-e $database) {
  exit 0;
}

my $driver   = "SQLite"; 
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, { AutoCommit => 0, RaiseError => 1 }) or die $DBI::errstr;


my $stmt = qq(CREATE TABLE IF NOT EXISTS FILE
       (PKGNAME       TEXT    NOT NULL,
       PATH       TEXT    NOT NULL,
       BASENAME       TEXT    NOT NULL,
       EXT       TEXT););
my $rv = $dbh->do($stmt);
if($rv < 0){
   print $DBI::errstr;
}

my $sth = $dbh->prepare('INSERT INTO FILE (PKGNAME, PATH, BASENAME, EXT) VALUES (?, ?, ?, ?)');


my @pkgs=`find $src_root -mindepth 1 -maxdepth 1 -type d`;


# if ($startPkgName) {
#  my $index = first_index{/$startPkgName$/} @pkgs;
#  if ($index > 0) {
#   splice @pkgs, 0, $index;
#  }
# }

my $pkgCount = @pkgs;
print "Package Number: $pkgCount\n";

my $count = 1;
foreach my $pkg (@pkgs) {

 my $startTime=time();
 
 chomp $pkg;
 my $pkg_name = basename($pkg);
 print "Parsing pkg [$count of $pkgCount]: $pkg_name ... "; 

 
# print "find $pkg -type f\n";

 my @files=`find $pkg -type f`;
# print "Files: @files \n";

 foreach my $file (@files) {
  
  (my $name,my $path,my $suffix) = fileparse($file,qr"\..[^.]*$");
  chomp $name;
  chomp $path;
  chomp $suffix;

  # print "Inserting ($pkg_name, $path, $name, $suffix)\n";
  my @values=($pkg_name, $path, $name, $suffix);
  $sth->execute(@values);
 }
 $dbh->commit;
 $count++;

 my $timePassed = time() - $startTime;
 print "[${timePassed}s used]\n";
}

$dbh->disconnect();


