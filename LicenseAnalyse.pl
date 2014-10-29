#!/usr/bin/perl

use strict;
use File::Path qw(make_path);
use Time::Seconds;
use Time::Piece;

# Read configs
open my $cfg, "<config.txt" or die "config.txt file needed.";
open my $log, ">log.txt";

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


my $oldTime;
my $newTime;
my $timeDiff;


$oldTime = localtime;

print "Listing files of folder: $src_root\n";
#print `collect_info/list_files.pl $src_root $stat_root`;

$newTime = localtime;
$timeDiff = $newTime - $oldTime;
print $log "Listing used: ". $timeDiff->seconds ." sec(s)\n";



$oldTime = localtime;
print "Counting files with these extensions: ${exts}\n";
#`collect_info/count.pl '$exts' $stat_root`;

$newTime = localtime;
$timeDiff = $newTime - $oldTime;
print $log "Counting used: ". $timeDiff->seconds ." sec(s)\n";


my $copyTime=0;
my $groupTime=0;
my $licenseDetectionTime=0;
my $changeDetectionTime=0;

my @stat_files = `find $stat_root -type f -name 'statistics.*.txt'`;

foreach my $file (@stat_files) {

	open(my $fh, "<$file");

	while (<$fh>) {

		(my $src_name, my $num) = split(/;/, $_);
		chomp $num;

		if ($num < $threshold) {
			last;
		}

		my $illegal = index($src_name, '$');
		$illegal += index($src_name, ' ');
		if ((-d $copied_src.$src_name) ||($illegal != -2)){
			print "Escaping [$src_name]\n";
			next;
		}


		if (($src_name eq 'ArrayUtil.java') || 
		($src_name eq 'DemoImpls.java') ||
		($src_name eq 'glew.c') ||
		($src_name eq 'glew.cpp') ||
		($src_name eq 'soapC.cpp') ||
		($src_name eq 'ogl_wrap.cpp') ||
		($src_name eq 'grid_wrap.cpp') ||
		($src_name eq 'aui_wrap.cpp') ||
		($src_name eq '_windows_wrap.cpp') ||
		($src_name eq '_misc_wrap.cpp') ||
		($src_name eq '_gdi_wrap.cpp') ||
		($src_name eq '_core_wrap.cpp') ||
		($src_name eq '_controls_wrap.cpp') ||
		($src_name eq 'glapi_gentable.c') ||
		($src_name eq 'mapscript_wrap.c') ||
		($src_name eq 'sqlite3.c') ) {
			next;
		}

		$oldTime = localtime;
		print "Copying files: [$src_name]\n";
		#print "copy_files/copy.pl $src_name $src_root $copied_src\n";
		print `copy_files/copy.pl '$src_name' $stat_root $copied_src`;
		$newTime = localtime;
		$timeDiff = $newTime - $oldTime;
		$copyTime += $timeDiff->seconds;
		
(my $sec,my $min,my $hour,my $mday) = localtime(time);
print "[$mday $hour:$min:$sec]";

		$oldTime = localtime;
		print "Grouping...\n";
		# print "copy_files/get_uniq.pl ${copied_src} ${src_name}\n";
		print `copy_files/get_uniq.pl ${copied_src} ${src_name}`;
		$newTime = localtime;
		$timeDiff = $newTime - $oldTime;
		$groupTime += $timeDiff->seconds;

		my @folders = `find '${copied_src}${src_name}' -type d -name 'src_uniq_*'`;

		my ($ext) = $src_name =~ /(\.[^.]+)$/;

		foreach my $folder (@folders) {

			chomp $folder;

			$oldTime = localtime;
			 print "License detection: [$folder]";
			`find $folder -name '*$ext' | xargs NinkaWrapper.pl -s -x -o $folder -- 2>/dev/null`;
			$newTime = localtime;
			$timeDiff = $newTime - $oldTime;
			$licenseDetectionTime += $timeDiff->seconds;

			$oldTime = localtime;
#			 print "analyse/check_license_result.pl -d $folder\n";
			my $inconsis = `analyse/check_license_result.pl -d $folder`;
			$newTime = localtime;
			$timeDiff = $newTime - $oldTime;
			$changeDetectionTime += $timeDiff->seconds;

			if ($inconsis) {
				print " <-----Inconsistent!";
				print $licFh "$src_name,$folder,$inconsis\n";
			}
			else {
				print " OK.";
			}
			print "\n";
		}
		print "\n";
		print $log "Copying:[$copyTime] Grouping:[$groupTime] Ninka:[$licenseDetectionTime] Incon:[$changeDetectionTime]\n";
		
	}

	close($fh);
}

close $licFh;

#print $log "Copying:[$copyTime] Grouping:[$groupTime] Ninka:[$licenseDetectionTime] Incon:[$changeDetectionTime]\n";

close $log;

sub GetCfg
{
	my $line = <$cfg>;
	chomp $line;
	return $line;
}

