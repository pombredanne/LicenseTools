#!/usr/bin/perl

use Parallel::ForkManager;
use strict;

my $MAX_PROCESSES = 6;

#my $stat_root = $ARGV[0];
my $copied_src = $ARGV[0];
my $ext = $ARGV[1];

my $dest_dir = $copied_src;

my $pm = new Parallel::ForkManager($MAX_PROCESSES);

my $group_count = `ls $dest_dir | wc -l`;
my $last_item = $group_count-1;

for (my $i = 0; $i < $group_count; $i++) {

    # Forks and returns the pid for the child:
    my $pid = $pm->start and next; 

    my $process = 100*$i/$last_item;
    my $r = sprintf("%.1f",$process);
    print "[$r%] Done. [$i/$last_item].\r";

    my $folder = "${dest_dir}$i/";

    if (-d $folder) {

#	    print "find $folder -name '*$ext' | xargs NinkaWrapper.pl -s -x -o $folder -- 2>/dev/null\n";
	    `find $folder -name '*$ext' | xargs NinkaWrapper.pl -s -x -o $folder -- 2>/dev/null`;
    }

    $pm->finish; # Terminates the child process
}

$pm->wait_all_children;

