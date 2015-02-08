#!/usr/bin/perl

use strict;
use File::Path qw(make_path);
use Time::Seconds;
use Time::Piece;
use Getopt::Long;
use DBI;

# Const define
my $data_root = "AnalysisData/";
my $stat_root = "${data_root}Statistics/";
my $copied_src = "${data_root}Source/";
my $resultFile = "${stat_root}LicenseCount.csv";
my $family_folder_list = "${stat_root}FamilyFolderList.txt";


if (!-d $stat_root) {
	# print "make_path($stat_root);\n";
	make_path($stat_root);
}

if (!-d $copied_src) {
	die "Source file don't exsit!\n";
}
my $dbPath='';
if (substr($dbPath,-1) ne "/") {
	$dbPath = $dbPath.'/';
}


open my $resultFh, ">$resultFile";

my @folders;

if (!-e $family_folder_list) {
	@folders = `find ${copied_src} -type d -name 'src_uniq_*'`;
	open(my $fh, '>', $family_folder_list);
	foreach my $folder (@folders) {
		print $fh $folder;
	}
	close $fh;
	
} else {
	open(my $fh, '<', $family_folder_list);
	@folders=<$fh>;
	close $fh;
}

my %licTab;

foreach my $folder (@folders) {

	chomp $folder;

	$folder =~ /$copied_src(.*?)\/src_uniq_/;
	my $src_name = $1;

    print "Count licenses for: [$folder]";
    CountLicense($folder);
#    PrintL();

	print "\n";
}

while ((my $lic, my $count) = each(%licTab)) {
	print $resultFh "\"$lic\",$count\n";
}


close $resultFh;


sub PrintL {
	while ((my $lic, my $count) = each(%licTab)) {
		print "\"$lic\",$count\n";
	}
}


sub CountLicense {
	my($dbPath) = @_;

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


	while(my @row = $sth->fetchrow_array()) {
		chomp $row[0];
		my $current = $row[0];

		my $num = scalar keys %licTab;
		if ($num==0) {
			$licTab{$current}=0;
		}

		my $count = $licTab{$current};
		$licTab{$current} = $count+1;

		#print "$current,$licTab{$current}\n";
	}

	$sth->finish();
	$dbh->disconnect();

}

