#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use Getopt::Std;



my %opts = ();
if (!getopts ("o",\%opts) or scalar(@ARGV) == 0) {
print STDERR "
Usage $0 -o <SrcFileName> <ProjectRoot> <OutputFolder>

  -o output the package list.
\n";

    exit 1;
}

my $needOutput = exists $opts{o};

my $srcFile = $ARGV[0];
my $src_root = @ARGV[1];
my $dest_root = @ARGV[2];

my $rootFolder = "${dest_root}${srcFile}/";
my $srcFolder = "${rootFolder}src/";

if (!-d $srcFolder) {
 # print "$srcFolder not exist!\n";
 make_path($srcFolder);
}

(my $name, my $path, my $suffix) = fileparse($srcFile,qr/\.[^.]*/);

my $srcList = "${rootFolder}$srcFile.list.txt";
my $relationList = "${rootFolder}$srcFile.map.txt";
my $pkgList = "${rootFolder}PackageList.csv";


if (!-e $srcList) {
  print "find $src_root -name \"$srcFile\" > $srcList\n";
  `find $src_root -name "$srcFile" > $srcList`;
  print "result generated!\n";
}

open my $listFh, "<$srcList";
open my $mapFh, ">$relationList";
open my $pkgFh, ">$pkgList";

my @files=<$listFh>;

my $count=0;
my $prevPkg="";
foreach my $file (@files) {
  chomp $file;  
  
  my $pkgName = $file;
  $pkgName =~ s/$src_root//;
  my $index = index($pkgName, '/');
  $pkgName = substr($pkgName, 0, $index);
  
  my $newName = "";
  if ($pkgName eq $prevPkg) {
  	$newName = "${name}_${pkgName}_$count$suffix";
  	$count++;
  } else {
  	$newName = "${name}_$pkgName$suffix";
    print $pkgFh "$pkgName,\n";
  	$count=0;
  }
  
  my $newFullName = $srcFolder.$newName;

  copy($file, $newFullName);
 print $mapFh "$newName;$file\n";

	$prevPkg = $pkgName;
}

close $listFh or die$!;
close $$mapFh or die$!;
close $$pkgFh or die$!;
