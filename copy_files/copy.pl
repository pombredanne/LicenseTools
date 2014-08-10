#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);



#my %options=();
#getopts("");

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

my $srcList = "$rootFolder$srcFile.list.txt";
my $relationList = "$rootFolder$srcFile.map.txt";


if (!-e $srcList) {
  print "find $src_root -name \"$srcFile\" > $srcList\n";
  `find $src_root -name "$srcFile" > $srcList`;
  print "result generated!\n";
}

open my $listFh, "<$srcList";
open my $mapFh, ">$relationList";

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
  	$count=0;
  }
  
  my $newFullName = $srcFolder.$newName;

  copy($file, $newFullName);
 print $mapFh "$newName;$file\n";

	$prevPkg = $pkgName;
}

close $listFh or die$!;
close $$mapFh or die$!;
