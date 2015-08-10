#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use Getopt::Std;
use Cwd;


my $dir_root = "AnalysisData-Debian-new/";

chomp(my @subs = `find $dir_root -mindepth 1 -maxdepth 1 -type d`);

foreach my $sub (@subs) {

print "Processing [$sub]...\n";

my $src_root = "$sub/Source/";
my $stat_root = "$sub/Statistics/";
my $inconList = "${stat_root}LicenseChanged.csv";
my $inconListSorted = "${stat_root}LicenseChanged.sorted.csv";
my $inconListHash = "${stat_root}LicenseChanged.hash.csv";
my $hashTable = "${stat_root}hash_map.txt";


if (!-e $inconListSorted) {
  `cat $inconList | sort -n > $inconListSorted`;
}

my $lastProcessedGroup=-1;

if (-e $inconListHash) {
  chomp(my $lastLine=`tail -n 1 $inconListHash`);
  (my $hash, my $r) = split(/,/,$lastLine);
  if ($r) {
    $lastProcessedGroup = $r;
  }
}

print "lastProcessedGroup: $lastProcessedGroup\n";

my $r=`wc -l $inconListSorted`;
(my $totalGroups)=split(/ /, $r);

open(my $inconFH, "<$inconListSorted") or die$!;
open(my $hashFH, ">>$inconListHash");

my $count=1;
while(<$inconFH>) {

chomp;
(my $groupNum) = split(/,/);

if ($groupNum <= $lastProcessedGroup) {
print "Skip $groupNum\r";
$count++;
next;
}

print "Processing $groupNum [$count/$totalGroups]\n";

my $map="${src_root}$groupNum/mapping.txt";
chomp(my $line=`head -n 1 $map`);
(my $name, my $file)=split(/,/,$line);

#print "First line of map is : $line\nFile is: $file\n";

$line=`grep '$file' $hashTable`;
my $hash;
if ($line) {
($hash)=split(/,/,$line);
#print "hash is:[$hash]\n";
}
print $hashFH "$hash,$_\n";

$count++;
}


close($inconFH);
close($hashFH);
}
