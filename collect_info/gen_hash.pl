#!/usr/bin/perl

#use Getopt::Std;
use File::Basename;
use DBI;
use strict;


my $stat_root = $ARGV[0];
my $ext = $ARGV[1];


# print "[$ext]\n";
my $ccfx_type = '';

if ($ext eq 'c' || $ext eq 'cpp')  { 
	$ccfx_type = 'cpp'; 
} elsif ($ext eq 'java') {
	$ccfx_type = 'java';
} else {
	die "Unkown source file extension [$ext].\n";
}

my $ccfx_suffix ='';

if ($ccfx_type eq 'cpp')  { 

	$ccfx_suffix = '.cpp.2_0_0_2.default.ccfxprep';

} elsif ($ccfx_type eq 'java') {

	$ccfx_suffix = '.java.2_0_0_0.default.ccfxprep';

} else {
}

my $ccfx_path = '/usr/local/ccfx/ubuntu32/ccfx';

my $database = "${stat_root}files.db";

my $driver   = "SQLite"; 
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, { AutoCommit => 0, RaiseError => 1 }) or die $DBI::errstr;



my $stmt = qq(SELECT PATH, HASH from FILE;);

my $sth = $dbh->prepare( $stmt );
my $rv = $sth->execute() or die $DBI::errstr;
if($rv < 0){
   print $DBI::errstr;
}


while(my @row = $sth->fetchrow_array()) {

 my $filepath = $row[0];
 my $hash = $row[1];

 if (!$hash) {

	`$ccfx_path D ${ccfx_type} $filepath`; # Generate the prep file
	my $token_file = "${filepath}${ccfx_suffix}";
	`perl -i -pe 's/^[^\t]+\t//' ${token_file}`; # Remove leading line numbers of the token file

	my $fh;
	unless (open $fh, $token_file) {
		warn "$0: open $token_file: $!";
		next;
	}

	my $sha1 = Digest::SHA1->new;
	$sha1->addfile($fh);
	my $hash_value = $sha1->hexdigest; # Get the hash of the file
	print $hash_value, "  $filepath\n";

	$dbh->do('UPDATE FILE SET HASH = ? WHERE PATH = ?', undef, $hash_value, $filepath);


	close $fh;
 }
 
}

$dbh->commit();

$dbh->disconnect();
