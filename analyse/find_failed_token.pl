#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use Getopt::Std;
use Cwd;
use Parallel::ForkManager;

my $MAX_PROCESSES = 6;
my $pm = new Parallel::ForkManager($MAX_PROCESSES);

my $dir_root = "AnalysisData/";

chomp(my @subs = `find $dir_root -mindepth 1 -maxdepth 1 -type d`);

foreach my $sub (@subs) {

	print "Processing [$sub]...\n";
	
	my $ext = $sub;
	$ext =~ s/.*\///;

	my $ccfx_suffix ='';
	if ($ext eq 'cpp' || $ext eq 'c')  {
		$ccfx_suffix = '.cpp.2_0_0_2.default.ccfxprep';
	} elsif ($ext eq 'java') {
		$ccfx_suffix = '.java.2_0_0_0.default.ccfxprep';
	} 

#	print "Ext: $ext, $ccfx_suffix\n";

	my $src_root = "$sub/Source/";
	my $stat_root = "$sub/Statistics/";
	my $hashTable = "${stat_root}hash_map.txt";
	my $bugList = "${stat_root}token_failed_list.txt";
	my $log = "${stat_root}log.txt";

	chomp(my $total=`wc -l < '$hashTable'`);
	open(my $fh, "<$hashTable");
	my $count=0;
	while (<$fh>) {
		chomp;
		my ($hash, $file) = split(/,/);
		my $token_file = "${file}$ccfx_suffix";

		$count++;
		print "Processing [$count/$total]\n";
		`echo 'Processing [$count/$total]' > '$log'`;

		my $pid = $pm->start and next;

		if (-e $token_file) {
			open(FILE, "<$token_file");
			my $line=<FILE>;
			close(FILE);

			my @arr=split(/\t/,$line);
			my $num=@arr;
			if ($num == 3) {
				`echo '$file' >> $bugList`;
			}
		}
		$pm->finish;
	}

	close($fh);
}

$pm->wait_all_children;
