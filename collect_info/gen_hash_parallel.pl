#!/usr/bin/perl

#use Getopt::Std;
use Digest::SHA;
use File::Basename;
use DBI;
use strict;



my $stat_root = $ARGV[0];
my $section = $ARGV[1];
my $ext = $ARGV[2];
my $start_from= $ARGV[3];


if (!$start_from) {
 $start_from = 1;
}

#my $ext = 'java';

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

open(my $log, ">${stat_root}log_$section.txt");

my $fn="${stat_root}file_list$section.txt";
my $rf="${stat_root}hash_table$section.txt";
my $old_rf="${stat_root}hash_table$section.txt.bk";
chomp(my $lines = `wc -l < $fn`);

my $rlines=0;
chomp($rlines = `wc -l < $rf`) if (-e $rf);

if ($rlines<$lines) {

$start_from=$rlines+1;

open(FILE, "<$fn") || die "Can't open $fn\n";
open(my $rh,">>$rf") || die;


print "Generating hash values for section $section...\n";

my $count=1;
while(<FILE>) {

	if ($count<$start_from) {
		$count++;
		next;
	}

	chomp;
	my $filepath = $_;
	#$filepath =~s/ /\\ /g; # Escape the spaces.

	PrintLog($count,$lines);

	(my $hash_value, my $lc) = CalcHash();

	print $rh "${hash_value},${filepath},$lc\n";

	print "              \r";
	$count++;
}

close(FILE);
close($rh);

} else {

rename $rf, $old_rf;

open(FILE, "<$old_rf") || die "Can't open $old_rf\n";
open(my $rh,">$rf") || die;


print "Updating hash values for section $section...\n";

my $count=1;
while(<FILE>) {

	chomp;
	(my $hash_value, my $filepath, my $lc) = split(/,/);
	#$filepath =~s/ /\\ /g; # Escape the spaces.

	PrintLog($count,$rlines);

	($hash_value, $lc) = CalcHash($hash_value, $lc);

	print $rh "${hash_value},${filepath},$lc\n";

	print "              \r";
	$count++;
}

close(FILE);
close($rh);

}

close($log);
print "\nComplete.\n";

sub PrintLog {

	(my $count, my $lines) = split(@_);
	my $process=100*$count/$lines; 
	my $r=sprintf("%.1f",$process);
	print "[${r}%] Done. [${count}/${lines}].";

	seek($log,0,0);
	print $log "[${r}%] Done. [${count}/${lines}].\n";
}

sub CalcHash {

	(my $hash_value, my $lc) = split(@_);
	
	my $token_file = "${filepath}${ccfx_suffix}";
	if (-e $token_file) {
		print "Processing...";

		$lc = `wc -l < '$token_file'` if (!$lc);

		if (!$hash_value) {
			open(my $fh, $token_file);
			my $sha1 = Digest::SHA->new;
			$sha1->addfile($fh);
			$hash_value = $sha1->hexdigest; # Get the hash of the file
			close $fh;
		}
	}

	return ($hash_value,$lc);
}
