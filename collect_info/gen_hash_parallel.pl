#!/usr/bin/perl

#use Getopt::Std;
use Digest::SHA;
use File::Basename;
use DBI;
use strict;


my $stat_root = 'AnalysisData/Statistics/';
my $section = $ARGV[0];
my $start_from= $ARGV[1];

if (!$start_from) {
 $start_from = 1;
}

my $ext = 'java';

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

my $fn="${stat_root}file_list$section.txt";
my $rf="${stat_root}hash_table$section.txt";
my $lines = `wc -l < $fn`;

chomp($lines);

my $ccfx_path = '/usr/local/ccfx/ubuntu32/ccfx';

open(FILE, "<$fn") || die;
open(my $rh,">>$rf") || die;

my $count=1;
while(<FILE>) {

	if ($count<$start_from) {
		$count++;
		next;
	}

	chomp;
	my $filepath = $_;
	$filepath =~s/ /\\ /g; # Escape the spaces.

	my $token_file = "${filepath}${ccfx_suffix}";

#print "Token file:[$token_file]\n";

	my $process=100*$count/$lines; 
	my $r=sprintf("%.1f",$process);
	print "[${r}%] Done. [${count}/${lines}].";


	my $hash_value="";
	if (-e $token_file) {
		my $lines = `wc -l < $token_file`;
		if ($lines >= 20) {

			print "Processing...";

			open(my $fh, $token_file);
			my $sha1 = Digest::SHA->new;
			$sha1->addfile($fh);
			$hash_value = $sha1->hexdigest; # Get the hash of the file
			close $fh;
		}
	}

	print $rh "${hash_value},${filepath}\n";

	print "              \r";
	$count++;
}

close(FILE);
close($rh);

print "\nComplete.\n";
