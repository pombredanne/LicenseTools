#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use Getopt::Std;
use Cwd;
use Parallel::ForkManager;

my $MAX_PROCESSES = 6;
my $pm = new Parallel::ForkManager($MAX_PROCESSES);

my $dir_root = "AnalysisData/";
my $threshold=20;

chomp(my @subs = `find $dir_root -mindepth 1 -maxdepth 1 -type d`);

foreach my $sub (@subs) {

        print "Processing [$sub]...\n";

        my $src_root = "$sub/Source/";
        my $stat_root = "$sub/Statistics/";
        my $log = "${stat_root}log.txt";

        my $hashFile="${stat_root}hash_map.revised.txt";
        my $filteredFile="${stat_root}hash_map.filtered.$threshold.revised.txt";
        my $sortedFile="${stat_root}hash_map.sorted.revised.txt";
        my $rankFile="${stat_root}hash_rank.revised.txt";

        if (!-e $filteredFile) {

                print "Filter tables...\n";

                open(FILE,"<$hashFile") or die "Can't open: $hashFile\n";
                open(my $rfh, ">$filteredFile") or die "Can't open for write: $filteredFile\n";
                while(<FILE>){
                        chomp;
                        my($hash,$file,$lc)=split(/,/);
                        if ($lc>$threshold) {
                                print $rfh "$_\n";
                        }
                }
                close(FILE);
                close($rfh);
        }

        if (!-e $sortedFile) {
          print "Sort table...\n";
          `grep -Ev '^,' $filteredFile | sort > $sortedFile`; # Sort the hash table
        }

        my @topHash;

        if (!-e $rankFile) {

                print "Make rank file...\n";

                chomp(my @rankings = `cat  $sortedFile | cut -d ',' -f 1 | sort | uniq -c | sort -nr`);


                my $count = 0;
                foreach my $sha (@rankings) {

                        $sha =~ s/^\s+|\s+$//g;

                #       print "[$sha]\n";

                        (my $number, my $hash) = split(/ /, $sha);

                        if ($number >= 2) {
                                push(@topHash, $hash);
                        } else {
                                last;
                        }
                        $count++;
                }

                @topHash=sort @topHash;

                open(my $fh, ">$rankFile");
                print $fh join("\n",@topHash),"\n";
                close($fh);
        }
}

print "\nDone.\n";

