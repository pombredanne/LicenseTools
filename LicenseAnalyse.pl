#!/usr/bin/perl

use strict;
use File::Path qw(make_path);

# Read configs
open my $cfg, "<config.txt" or die "config.txt file needed.";
my $src_root = GetCfg();
my $exts = GetCfg();
my $threshold = GetCfg();
close $cfg;

my @exts= split(/,/, $exts);

# Const define
my $data_root = "AnalysisData/";
my $stat_root = "${data_root}Statistics/";
my $copied_src = "${data_root}Source/";

if (!-d $stat_root) {
	# print "make_path($stat_root);\n";
	make_path($stat_root);
}

if (!-d $copied_src) {
	make_path($copied_src);
}
 

print "Listing files of folder: $src_root\n";
`collect_info/list_files.pl $src_root $stat_root`;

print "Count files with these extensions: ${exts}\n";
`collect_info/count.pl '$exts' $stat_root`;

my @stat_files = `find $stat_root -type f -name 'statistics.*.txt'`;

foreach my $file (@stat_files) {

	open(my $fh, "<$file");

	my $count = 0;
	while (<$fh>) {

		if ($count >= $threshold) {
			last;
		}
		(my $src_name, my $num) = split(/;/, $_);

		#print "copy_files/copy.pl $src_name $src_root $copied_src\n";
		print `copy_files/copy.pl $src_name $src_root $copied_src`;

		print "copy_files/get_uniq.pl ${copied_src} ${src_name}\n";
		print `copy_files/get_uniq.pl ${copied_src} ${src_name}`;

		$count++;
	}

	close($fh);
}

sub GetCfg
{
	my $line = <$cfg>;
	chomp $line;
	return $line;
}