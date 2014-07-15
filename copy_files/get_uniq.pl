#!/usr/bin/perl

use File::Basename;
use File::Copy;
use DBI;


$dir = $ARGV[0];
#$dir = 'getopt.c/src/';

if(!$dir) {
	die "Directory need!";
}

if (substr($dir,-1) eq "/") {
	chop $dir;
}

$newpath=$dir."_uniq/";
mkdir $newpath;

$dir=$dir."/";

#@sha=`sha1sum ${dir}*.c | cut -d ' ' -f 1 | sort | uniq -u`;
@files=`sha1sum ${dir}*.c|sort`;

$prevHash='';
$count=0;
foreach $item (@files) {
	($hash,$file)=split(/ /,$item);
	chomp $file;
	$file =~ s/\*//;
	
	$filename=basename($file);
	
	#print "$hash, $file\n";
	
	if ($hash != $prevHash) {
		#`cp $file $newpath$filename`;
		copy($file, $newpath);
		#print "cp $file $newpath$filename\n";
		print '.';
		$count++;
	}
	$prevHash=$hash;
}

print "\n\n$count files copied.";