#!/usr/bin/perl

#use Getopt::Std;
use Digest::SHA;
use Parallel::ForkManager;
use File::Basename;
use DBI;
use strict;


my $stat_root = $ARGV[0];
my $section = $ARGV[1];
my $ext = $ARGV[2];
my $start_from= $ARGV[3];

if (!$start_from) {
 $start_from = 1;
}

#my $ext = 'java';

# print "[$ext]\n";
my $ccfx_type = '';

if ($ext eq 'c' || $ext eq 'cpp')  { 
	$ccfx_type = 'cpp'; 
} elsif ($ext eq 'java') {
	$ccfx_type = 'java';
} else {
	die "Unkown source file extension [$ext].\n";
}

my $ccfx_suffix ='';

if ($ccfx_type eq 'cpp')  { 

	$ccfx_suffix = '.cpp.2_0_0_2.default.ccfxprep';

} elsif ($ccfx_type eq 'java') {

	$ccfx_suffix = '.java.2_0_0_0.default.ccfxprep';

} else {
}

my $fn="${stat_root}file_list$section.txt";
my $skipFn="${stat_root}ccfx_skip_$section.txt";
my $failFn="${stat_root}ccfx_fail_$section.txt";

my $lines = `wc -l < $fn`;
chomp($lines);

my @skipList;
chomp(@skipList=`cat '$skipFn'`) if (-e $skipFn);

my $ccfx_path = '/usr/local/ccfx/ubuntu32/ccfx';

open(FILE, "<$fn") or die "Can't open $fn!\n";

open(my $log, ">${stat_root}log_$section.txt");
#open(my $fails, ">${stat_root}ccfxfail_$section.txt");

print "Generating token for section $section...\n";

my $count=1;
my $skipPointer=0;
while(<FILE>) {

	if ($count<$start_from) {
		$count++;
		next;
	}

	chomp;
	my $filepath = $_;
	#$filepath =~s/ /\\ /g; # Escape the spaces.

	if ($filepath ~~ @skipList) {
		$count++;
		$skipPointer++;
		next;
	}

	my $token_file = "${filepath}${ccfx_suffix}";
	my $ccfxfails = "${filepath}.ccfxfails";

	my $process=100*$count/$lines; 
	my $r=sprintf("%.1f",$process);
	print "[${r}%] Done. [${count}/${lines}].";

	seek($log,0,0);
	print $log "[${r}%] Done. [${count}/${lines}].\n";

  unless (-e $token_file or -e $ccfxfails) {
    print " Processing...";

  my $pm = new Parallel::ForkManager(1);

  for (my $i = 0; $i < 3; $i++) {
    $pm->wait_all_children;

    if (-e $token_file or -e $ccfxfails) {
      # ccfx exited normally
      last;
    }
    # Forks and returns the pid for the child:
    my $pid = $pm->start and next; 

    eval {
      local $SIG{ALRM} = sub { die "timeout\n" };

      my $time=5;
      $time=60 if ($i==2);
      alarm $time;

      #print "$ccfx_path D ${ccfx_type} $filepath\n"; # Generate the prep file
      `$ccfx_path D ${ccfx_type} '$filepath'`; # Generate the prep file

      alarm 0;
    };

    if ($@ ne "timeout\n") {
      `touch '$ccfxfails'`;
    }

    $pm->finish; # Terminates the child process
  }

  $pm->wait_all_children;

  if (-e $token_file) {
    `perl -i -pe 's/^[^\t]+\t//' '${token_file}'`; # Remove leading line numbers of the token file
  } elsif (-e $ccfxfails) {
    `echo '$filepath' >> $skipFn`;
  } else {
    # time-outed
    `echo '$filepath' >> $failFn`;
  }

 }

	print "              \r";
	$count++;
}

close(FILE);
close($log);
#close($fails);

print "\nComplete.\n";
