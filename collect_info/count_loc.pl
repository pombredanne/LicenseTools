#!/usr/bin/perl

#use Getopt::Std;
use File::Basename;
use DBI;
use strict;


my $_ext = $ARGV[0];
my $stat_root = @ARGV[1];

my @exts= split(/,/, $_ext);

my $database = "${stat_root}files.db";

my $driver   = "SQLite"; 
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;

foreach my $ext (@exts) 
{
	$ext =~ s/^\s+//;
	# print "[$ext]\n";

	my $stmt="";
	if ($ext) {

		if (substr($ext, 0, 1) ne ".") {
			$ext = ".$ext";
		}

		$stmt = qq(SELECT PATH, BASENAME, EXT  from FILE WHERE EXT = '$ext' ;);
	} else {
		$stmt = qq(SELECT PATH, BASENAME, EXT from FILE;);
	}
	# print "$stmt\n";

	my $sth = $dbh->prepare( $stmt );
	my $rv = $sth->execute() or die $DBI::errstr;
	if($rv < 0){
	   print $DBI::errstr;
	}

	my $filename = "${stat_root}line_of_code${ext}.txt";
	open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";

	my $file_list="";
	while(my @row = $sth->fetchrow_array()) {

		#print "$row[0]$row[1]$row[2]\n";
		$file_list .= "$row[0]$row[1]$row[2]\n";
	}

	print $fh "$file_list";
	close $fh;
}


$dbh->disconnect();
