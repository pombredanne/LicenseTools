#!/usr/bin/perl

use Parallel::ForkManager;
use strict;

my $MAX_PROCESSES = 6;

my $stat_root = $ARGV[0];
#my $copied_src = $ARGV[0];
my $ext = $ARGV[1];


my $pm = new Parallel::ForkManager($MAX_PROCESSES);

opendir(DIR, $stat_root);
my @files = grep(/file_list.*\.txt/,readdir(DIR));
closedir(DIR);

my $count = @files;
print "[$count] list(s) to gen hash.\n";

for (my $i = 0; $i < $count; $i++) {

    # Forks and returns the pid for the child:
    my $pid = $pm->start and next; 

    my $section = $i;
    #print "./gen_token_parallel.pl $stat_root $section $ext \n";
    print `collect_info/gen_hash_parallel.pl $stat_root $section $ext `;

    $pm->finish; # Terminates the child process
}

$pm->wait_all_children;

