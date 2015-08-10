#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use Getopt::Std;
use Cwd;


my $stat_root = "AnalysisData-Java/Statistics/";
my $inconList = "${stat_root}LicenseChanged.sorted.csv";
my $licHistory = "${stat_root}LicenseHistory.csv";
my $src_root = "AnalysisData-Java/Source/";
my $dest_root = "/opt/wuyuhao/java-prj/";

my $lastProcessedGroup=-1;
my $origPath = cwd;

if (-e $licHistory) {
  chomp(my $lastLine=`tail -n 1 $licHistory`);
  (my $r) = split(/,/,$lastLine);
  if ($r) {
    $lastProcessedGroup = $r;
  }
}

print "lastProcessedGroup: $lastProcessedGroup\n";

my $r=`wc -l $inconList`;
(my $totalGroups)=split(/ /, $r);

open(my $inconFH, "<$inconList") or die$!;
open(my $historyFH, ">>$licHistory");

my $group_count=1;
while(<$inconFH>) {
  chomp;
  (my $group) = split(/,/);

  if($group<$lastProcessedGroup) {
    print "Skip group $group...\r";
    $group_count++;
    next;
  }

  chdir($origPath);

  print "[$group_count/$totalGroups] Analyse group ($group) ...\n";

  my $map="${src_root}${group}/mapping.txt";

  my $wc=`wc -l $map`;
  (my $totalFiles)=split(/ /, $wc);

  open(my $mapFH, "<$map") or die $!;
  my $file_count=1;
  while(<$mapFH>) {
    chomp;
    (my $numberedName, my $file)=split(/,/);

    print "Generating versions for [$numberedName] ($file_count/$totalFiles)...\n";

    (my $name, my $path, my $suffix) = fileparse($file,qr/\.[^.]*/);
    my $basename="$name$suffix";

    my $dest="${dest_root}${group}/$numberedName/";

    if (!-d $dest) {
      make_path($dest);
    }

    my $historyFile="${dest}LicenseList.txt";

    if (-e $historyFile) {
      print "Seems already processed. Skip.\n";
      $file_count++;
      next;
    }

    #change dir
    chdir($path);
    my @commits=`git log --pretty=format:'%ci,%H'`;
    my $noc=@commits;

    my @toProcess;
    if ($noc>10){
      my $mid=$noc/2;
      my $low=$mid/2;
      my $high=$mid+$low;

      push(@toProcess,$commits[0]);
      push(@toProcess,$commits[$low]);
      push(@toProcess,$commits[$mid]);
      push(@toProcess,$commits[$high]);
      push(@toProcess,$commits[$noc-1]);
    } else {
      @toProcess=@commits;
    }

    my $filesGenerated=0;
    my $processCount=1;
    foreach my $commit (@toProcess) {
      chomp($commit);
      (my $date, my $hash)=split(/,/,$commit);
      $date =~ s/\ [\+-]\d+//g;
      $date =~ s/[\ :]/-/g;


      my $newName="${date}_${hash}_$basename";
      my $fileOfCommit="${dest}$newName";

      if (-e $fileOfCommit) {
        print "Skip $date ($processCount/$noc)...\r";
        $processCount++;
        next;
      }

      print "Generating $date ($processCount/$noc)...\r";

      #print "git show $hash:./$basename > $fileOfCommit\n";
      my $contents=`git show $hash:./$basename 2>/dev/null`;

      if ($contents) {
        open(FILE, ">$fileOfCommit");
        print FILE $contents;
        close(FILE);
        $filesGenerated++;
      }

      $processCount++;
    } # end of outputing all the commits


    print "Commits generated [$filesGenerated/$noc].        \n";

    # check whether license changed thru the history

    print "Check license for each version...\n";
    #print "find $dest -name '*$basename' | xargs NinkaWrapper-new.pl -t -o $dest -- 2>/dev/null\n";
    chomp(my @licenses=`find $dest -name '*$basename' -type f | xargs NinkaWrapper-new.pl -t -o $dest -- 2>/dev/null`);
    my $num=@licenses;

    my $chain="";

    if ($num>1) {
      my $prev=$licenses[0];
      foreach my $lic (@licenses) {
        if ($prev ne $lic) {
          # license change detected!
          if ($chain) {
            $chain.="$lic;";
          } else {
            $chain="$prev;$lic;";
          }
          $prev=$lic;
        }
      }
    }

    my $changeFlag=0;
    if ($chain) {
      print "Change detected: $group,$numberedName,\"$chain\"\n";
      $changeFlag=1;
    } else {
      print "OK.\n";
    }

    print $historyFH "$group,$changeFlag,$numberedName,\"$chain\"\n";

    $file_count++;
  } # end of all files inside one group
  close($mapFH);

  $group_count++;
} # end of all groups

close($inconFH);
close($historyFH);

