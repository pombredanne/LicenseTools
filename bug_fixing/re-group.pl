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

chomp(my @subs = `find $dir_root -mindepth 1 -maxdepth 1 -type d`);

foreach my $sub (@subs) {

    print "Processing [$sub]...\n";

    my $src_root = "$sub/Source/";
    my $stat_root = "$sub/Statistics/";
    my $log = "${stat_root}log.txt";

    my $sortedFile="${stat_root}hash_map.sorted.txt";
    my $rankFile="${stat_root}hash_rank.txt";

    my $sortedFileRevised="${stat_root}hash_map.sorted.revised.txt";
    my $rankFileRevised="${stat_root}hash_rank.revised.txt";
    my $correctTable = "${stat_root}corrected_hash_table.txt";
    my $fixing_list_new = "${stat_root}fixing_list_of_groups_new.txt";
    my $fixing_list_update = "${stat_root}fixing_list_of_groups_update.txt";


    #　Step 1: new comers.

    chomp(my $startIndex=`ls $src_root | wc -l`);

    chomp(my @oldHashes = `cat '$rankFile'`);
    chomp(my @newHashes = `cat '$rankFileRevised'`);

    my %in_old = map {$_ => 1} @oldHashes;
    my @new_extra = grep {not $in_old{$_}} @newHashes;

    my $total=@new_extra;
    my $groupIndex=$startIndex;
    my $count=1;

    print "Resolving new comers, [$total] groups found...\n";

    foreach my $hash (@new_extra) {

    	print "[$count/$total]...\r";

        $groupIndex=$count + $startIndex -1;

        `echo '$groupIndex,$hash' >> '$fixing_list_new'`;

        my $groupFolder = "${src_root}${groupIndex}/";
        my $fileList = "${groupFolder}list.txt";

        # Make dir for group
        if (!-d $groupFolder) {
         make_path($groupFolder);
        }

        if (!-e $fileList) {
        `grep '$hash' '$sortedFileRevised' | cut -d ',' -f 2 > '$fileList'`;
        }
       
        $count++;            
    }

    #　Step 2: those already have a group
    chomp(my @correctedHashes = `cut -d ',' -f 1 '$correctTable' | sort | uniq`);

    my %in_extra = map {$_ => 1} @new_extra;
    my @those_already_have_group = grep {$in_old{$_}} @correctedHashes;

    my $total = @those_already_have_group;
    my $count=1;

    print "Resolving missing files, [$total] files found...\n";

    foreach my $hash (@those_already_have_group) {

    	print "[$count/$total]...\r";

#	print "grep -n '$hash' $rankFile\n";

        chomp(my $line = `grep -n '$hash' '$rankFile'`);
        my ($groupIndex) = split(/:/,$line);
        $groupIndex--;

#	print "$line--->$groupIndex\n";

        my $groupFolder="$src_root${groupIndex}/";
        my $fileList = "${groupFolder}list.txt";
        my $fileListBk = "${groupFolder}list.txt.bk";

        # Update the file list of this group
	if (-e $fileList) {
        rename $fileList, $fileListBk;
	}

        `grep '$hash' '$sortedFileRevised' | cut -d ',' -f 2 > '$fileList'`;

        `echo '$groupIndex,$hash' >> '$fixing_list_update'`;

        $count++;
    }

}

print "\nDone.\n";


