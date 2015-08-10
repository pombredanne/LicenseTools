#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use Digest::SHA;
use Getopt::Std;
use Cwd;


my $dir_root = "AnalysisData-Debian-old/";

my $src_root = "$dir_root/Source/";
my $stat_root = "$dir_root/Statistics/";
my $inconList = "${stat_root}LicenseChanged.csv";
my $inconListHash = "${stat_root}LicenseChanged.hash.csv";


my $r=`wc -l $inconList`;
(my $totalGroups)=split(/ /, $r);

open(my $inconFH, "<$inconList") or die$!;
open(my $hashFH, ">$inconListHash");

my $count=1;
while(<$inconFH>) {

chomp;
(my $baseName, my $dir) = split(/,/);

(my $name,my $path,my $ext) = fileparse($baseName,qr"\..[^.]*$");
$dir=~s/AnalysisData\//$dir_root/;
$dir.="/";

print "[$count/$totalGroups] Processing $dir\n";

my @srcs=`find $dir -name "$name*$ext"`;
chomp(my $src=$srcs[0]);

$src=~s/.*uniq.*\///;

#print "src file: $src\n";

$dir=~s/_uniq.*//;

my @tokens=`find $dir -name "$src*.ccfxprep"`;
chomp(my $token_file=$tokens[0]);

#print "token file: $token_file\n";
my $hash;
if (open my $fh, $token_file) {

	my $sha1 = Digest::SHA->new;
	$sha1->addfile($fh);
	$hash = $sha1->hexdigest; # Get the hash of the file	

	close $fh;
}


#print "$hash,$_\n";
print $hashFH "$hash,$_\n";
$count++;
}


close($inconFH);
close($hashFH);
