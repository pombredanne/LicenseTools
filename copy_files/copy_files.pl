#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use DBI;



my $dest_root = $ARGV[0];
my $stat_root = $ARGV[1];
my $ext = $ARGV[1];

my $rootFolder = "${dest_root}/";
if (!-d $rootFolder) {
 # print "$rootFolder not exist!\n";
 make_path($rootFolder);
}

my $database = "${stat_root}files.db";

my $driver   = "SQLite"; 
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;



my $stmt = qq(select HASH, count(*) from FILE group by HASH order by count(*) desc;);

my $sth = $dbh->prepare( $stmt );
my $rv = $sth->execute() or die $DBI::errstr;
if($rv < 0){
   print $DBI::errstr;
}

my @hash_list;

while(my @row = $sth->fetchrow_array()) {

 my $hash_value = $row[0];
 my $count = $row[1];

 if ($count > 1) {
 	push @hash_list, $hash_value;
 }
}

my $group_count=1;
foreach my $hash (@hash_list) {

	my $stmt = qq(select PATH from FILE where HASH = $hash;);

	my $sth = $dbh->prepare( $stmt );
	my $rv = $sth->execute() or die $DBI::errstr;
	if($rv < 0){
	   print $DBI::errstr;
	}

	# Make dir for group
	my $groupFolder = "${rootFolder}${group_count}/";
	if (!-d $groupFolder) {
	 # print "$groupFolder not exist!\n";
	 make_path($groupFolder);
	}

	# Create a mapping file
	my $mapping_list = "${groupFolder}$mapping.txt";
	open my $mapFh, ">$mapping_list";

	my $file_count=1;
	while(my @row = $sth->fetchrow_array()) {
 		my $fileName = $row[0];
		# Copy files

		(my $name, my $path, my $suffix) = fileparse($fileName,qr/\.[^.]*/);
		my $newName = "${file_count}_${name}${suffix}";

		print $mapFh, "$newName,$fileName";

		my $newFullName = $groupFolder.$newName;
		copy($fileName, $newFullName);

		$file_count++;
	}

	close $mapFh;
	$group_count++;
}



$dbh->disconnect();
