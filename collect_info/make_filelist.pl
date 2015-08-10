#!/usr/bin/perl

#use Getopt::Std;
use Digest::SHA;
use File::Basename;
use DBI;
use strict;


#my $stat_root = 'AnalysisData/Statistics/';
my $src_root = @ARGV[0];
my $stat_root = @ARGV[1];
my $ext = @ARGV[2];


if (-e "${stat_root}file_list0.txt") {
	exit 0;
}

my $cores=6;

my @files=`find $src_root -name '*.$ext' -type f`;
chomp @files;

my @fhs;
for (my $i = 0; $i < $cores; $i++) {
	local *FILE;
	open(FILE, ">${stat_root}file_list${i}.txt") || die;
	push(@fhs, *FILE);
}



my $count=0;
foreach my $filepath (@files) {

 my $block=$count % $cores;

 my $fh = $fhs[$block];
 print $fh "$filepath\n";
 print "Processing file: $count\r";
 $count++;
}

foreach my $file (@fhs) {
 close $file;
}


print "\nFinished!\n";
