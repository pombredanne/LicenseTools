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
my $licenseChange = "${stat_root}LicenseChanged.csv";

if (!-d $stat_root) {
	# print "make_path($stat_root);\n";
	make_path($stat_root);
}

if (!-d $copied_src) {
	make_path($copied_src);
}
 
open my $licFh, ">$licenseChange";

print "Listing files of folder: $src_root\n";
print `collect_info/list_files.pl $src_root $stat_root`;

print "Counting files with these extensions: ${exts}\n";
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

		# print "copy_files/get_uniq.pl ${copied_src} ${src_name}\n";
		print `copy_files/get_uniq.pl ${copied_src} ${src_name}`;

		my @folders = `find ${copied_src}${src_name} -type d -name 'src_uniq_*'`;

		my ($ext) = $src_name =~ /(\.[^.]+)$/;

		foreach my $folder (@folders) {

			chomp $folder;
			# print "find $folder -name '*$ext' | xargs NinkaWrapper.pl -s -o $folder --";
			`find $folder -name '*$ext' | xargs NinkaWrapper.pl -s -o $folder -- 2>/dev/null`;

			# print "analyse/check_license_result.pl -d $folder\n";
			my $hasDiff = `analyse/check_license_result.pl -d $folder`;

			if ($hasDiff) {
				# print "hasdiff: $hasDiff\n";
				print $licFh "$src_name,$folder\n";
			}
		}

		$count++;
	}

	close($fh);
}

close $licFh;

sub GetCfg
{
	my $line = <$cfg>;
	chomp $line;
	return $line;
}