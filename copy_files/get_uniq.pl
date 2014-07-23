#!/usr/bin/perl

use File::Basename;
use File::Copy;
use List::MoreUtils qw(firstidx);
use Getopt::Std;
use DBI;

my %opts = ();
if (!getopts ("t",\%opts) or scalar(@ARGV) == 0) {
print STDERR "
Usage $0 -t <path> threshold

  -t test output.
\n";

    exit 1;
}

my $test = exists $opts{t};

$dir = $ARGV[0];
$threshold = $ARGV[1];
if (!$threshold) { 
	$threshold = 0;
}
#$dir = 'getopt.c/src/';

if(!$dir) {
	die "Directory need!";
}

if (substr($dir,-1) eq "/") {
	chop $dir;
}
$dir_slash=$dir."/";

$prepared=`find ${dir_slash}*.ccfxprep`;

if (!$prepared) {
	print "Preparing...\n";
	`ccfx D cpp ${dir_slash}*.c`;
	`perl -i.back -pe 's/^[^\t]+\t//' ${dir_slash}*c.cpp.2_0_0_2.default.ccfxprep`;
}

$exec = "sha1sum ${dir_slash}*.ccfxprep | cut -d ' ' -f 1 | sort | uniq -c | sort -n";

if ($test) {
	print `$exec`;
	exit 0;
} else {
	@rankings = `${exec}r`;
}


@topHash;
$count = 0;
foreach $sha (@rankings) {
	$sha =~ s/^\s+|\s+$//g;
	
	#print "$sha\n";
	
	($number, $hash) = split(/ /, $sha);
	
	if ($number >= $threshold) {
		push(@topHash, $hash);
	} else {
		last;
	}
	$count++;
}

print "$count group(s) of identical files found.\n";

@files=`sha1sum ${dir_slash}*.ccfxprep|sort`;

$prevHash='';
$count=0;
foreach $item (@files) {

	($hash,$file)=split(/ /,$item); # extract hash value and file name
	
	$idx = firstidx { $_ eq $hash } @topHash;
	
	if ($idx >= 0) {
	
		$newpath = "${dir}_uniq_${idx}/";
		if (!-d $newpath) {
			mkdir $newpath;
		}
		
		chomp $file;
		$file =~ s/\*//; # remove the leading '*'
		$file =~ s/.cpp.2_0_0_2.default.ccfxprep//; # get the original source file
	
		copy($file, $newpath);
		print '.';
		$count++;
	}
}

print "\n\n$count files copied.";