#!/usr/bin/perl

use strict;
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

my $dir = $ARGV[0];
my $src_name = $ARGV[1];

my $threshold = $ARGV[2];
if (!$threshold) { 
	$threshold = 2;
}
#$dir = 'getopt.c/src/';

if(!$dir && !$src_name) {
	die "Directory need!";
}

my ($ext) = $src_name =~ /(\.[^.]+)$/;
$ext =~ s/\.//;
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


$dir = "${dir}${src_name}/src/";

if (substr($dir,-1) eq "/") {
	chop $dir;
}
my $dir_slash=$dir."/";

my $prepared=`find ${dir_slash}*${ccfx_suffix} 2>/dev/null`;


if (!$prepared) {
	print "Preparing...\n";
	`ccfx D ${ccfx_type} ${dir_slash}*.$ext`;
	`perl -i.back -pe 's/^[^\t]+\t//' ${dir_slash}*${ccfx_suffix}`;
}

my $exec = "sha1sum ${dir_slash}*${ccfx_suffix} | cut -d ' ' -f 1 | sort | uniq -c | sort -n";

my @rankings;
if ($test) {
	print `$exec`;
	exit 0;
} else {
	@rankings = `${exec}r`;
}


my @topHash;
my $count = 0;
foreach my $sha (@rankings) {
	$sha =~ s/^\s+|\s+$//g;
	
	#print "$sha\n";
	
	(my $number, my $hash) = split(/ /, $sha);
	
	if ($number >= $threshold) {
		push(@topHash, $hash);
	} else {
		last;
	}
	$count++;
}

print "$count group(s) of identical files found for [$src_name]. ";

my @files=`sha1sum ${dir_slash}*${ccfx_suffix} | sort`;

my $prevHash='';
$count=0;
foreach my $item (@files) {

	(my $hash, my $file)=split(/ /,$item); # extract hash value and file name
	
	my $idx = firstidx { $_ eq $hash } @topHash;
	
	if ($idx >= 0) {
	
		my $newpath = "${dir}_uniq_${idx}/";
		if (!-d $newpath) {
			mkdir $newpath;
		}
		
		chomp $file;
		$file =~ s/\*//; # remove the leading '*'
		$file =~ s/${ccfx_suffix}//; # get the original source file
	
		copy($file, $newpath);
		# print '.';
		$count++;
	}
}

print "$count files copied.\n";