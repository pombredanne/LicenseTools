#!/usr/bin/perl

#use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);


$debian_root="/home/t-kanda/HDQL16/src_debian-750/";

#my %options=();
#getopts("");

$srcFile = $ARGV[0];

$rootFolder = $srcFile."/";
$srcFolder = $rootFolder."src/";

if (!-d $srcFolder) {
 print "$srcFolder not exist!\n";
 make_path($srcFolder);
}

($name,$path,$suffix) = fileparse($srcFile,qr/\.[^.]*/);

$srcList = $rootFolder.$srcFile.".list.txt";
$relationList = $rootFolder.$srcFile.".map.txt";


if (!-e $srcList) {
print "find $debian_root -name \"$srcFile\" > $srcList\n";
`find $debian_root -name "$srcFile" > $srcList`;
print "result generated!\n";
}

open $listFh, "<$srcList";
#open $mapFh, ">$relationList";

@files=<$listFh>;

$count=0;
$prevPkg="";
foreach $file (@files) {
  chomp $file;  
  
  $pkgName = $file;
  $pkgName =~ s/$debian_root//;
  $index = index($pkgName, '/');
  $pkgName = substr($pkgName, 0, $index);
  
  if ($pkgName eq $prevPkg) {
	$newName = "${name}_${pkgName}_$count$suffix";
	$count++;
  } else {
	$newName = "${name}_$pkgName$suffix";
	$count=0;
  }
  
  $newFullName = $srcFolder.$newName;

  copy($file, $newFullName);
#  print $mapFh "$newName;$file\n";

	$prevPkg = $pkgName;
}

close $listFh or die$!;
#close $$mapFh;
