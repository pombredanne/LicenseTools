#!/usr/bin/perl

use Parallel::ForkManager;
use strict;

my $MAX_PROCESSES = 6;

my $stat_root = $ARGV[0];
my $srcUniqList=$ARGV[1];


my $pm = new Parallel::ForkManager($MAX_PROCESSES);


if (!-e $srcUniqList) {
    die "Src Uniq list not found: $srcUniqList!\n";
}


chomp(my $group_count = `wc -l < '$srcUniqList'`);

open(my $fh, "<$srcUniqList");
open(my $log, ">${stat_root}log.txt");

my $count=0;

while(<$fh>) {
    chomp;
    my $folder = $_ . "/";

    $count++;
    seek($log,0,0);
    print $log "License detection: [$count/$group_count].\n";

    # Forks and returns the pid for the child:
    my $pid = $pm->start and next;


    my $list = "${folder}list.txt";

    if (-e $list) {

#        print "`cat $list | xargs NinkaWrapper.pl -s -x -o $folder -- 2>/dev/null`\n";
#           `cat $list | xargs NinkaWrapper.pl -s -x -o $folder -- 2>/dev/null`;

        chomp(my @lines=`cat '$list'`);
        my $arg= join("' '", @lines);
        $arg="'$arg'";

         `NinkaWrapper.pl -s -x -o $folder $arg -- 2>/dev/null`;

    } else {
        print STDERR "File not found: $list.\n";
    }

    $pm->finish; # Terminates the child process
}

$pm->wait_all_children;

close($fh);
close($log);

