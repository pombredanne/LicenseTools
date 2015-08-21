#!/usr/bin/perl

use strict;
use Getopt::Std;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use Getopt::Std;
use Cwd;
use Parallel::ForkManager;
use Digest::SHA;

my $MAX_PROCESSES = 6;
my $pm = new Parallel::ForkManager($MAX_PROCESSES);

my $dir_root = "AnalysisData/";

chomp(my @subs = `find $dir_root -mindepth 1 -maxdepth 1 -type d`);

foreach my $sub (@subs) {

	print "Processing [$sub]...\n";
	
	my $ext = $sub;
	$ext =~ s/.*\///; # extract the extension.

	my $ccfx_suffix ='';
	if ($ext eq 'cpp' || $ext eq 'c')  {
		$ccfx_suffix = '.cpp.2_0_0_2.default.ccfxprep';
	} elsif ($ext eq 'java') {
		$ccfx_suffix = '.java.2_0_0_0.default.ccfxprep';
	} 

#	print "Ext: $ext, $ccfx_suffix\n";

	my $src_root = "$sub/Source/";
	my $stat_root = "$sub/Statistics/";
	my $hashTable = "${stat_root}hash_map.txt";
	my $hashTableRevised = "${stat_root}hash_map.revised.txt";
	my $bugList = "${stat_root}token_failed_list.txt";
	my $correctTable = "${stat_root}corrected_hash_table.txt";
	my $log = "${stat_root}log.txt";

	if (!-e $bugList) {
		print "Bug list doesn't exist: $bugList.\n";
		next;
	}

	chomp(my @bugFiles=`cat '$bugList'`);
	if (!@bugFiles) {
		print "Bug list is empty!\n";
		next;
	}

	

	if (!-e $correctTable) {

		print "Generating correct hash table...\n";
	
		my $count=1;
		my $total=@bugFiles;
#		open(my $rFh, ">$correctTable");
		foreach my $file (@bugFiles) {

			print "Processing [$count/$total]...\r";
			$count++;

			my $pid = $pm->start and next;
			
			my $token_file = "${file}$ccfx_suffix";
			
			open(FILE, "<$token_file");
			chomp(my $line=<FILE>);
			close(FILE);

			my @arr=split(/\t/,$line);
			my $num=@arr;
			if ($num == 3) {

			`perl -i -pe 's/^[^\t]+\t//' '${token_file}'`; # Remove leading line numbers of the token file
			}
			
			my ($hash) = CalcHash($token_file);
			#print $rFh "$hash,$file\n";
			`echo '$hash,$file' >> '$correctTable'`;
			
			$pm->finish;

		}
#		close($rFh);
	}

	$pm->wait_all_children;

	# Make a hash table for look up
	my %table;
	open(FILE, "<$correctTable");
	chomp(my @lines=<FILE>);
	close(FILE);

	foreach my $line (@lines) {
		my ($hash,$file)=split(/,/, $line);
		$table{$file}=$hash;
	}

	print "Revising hash table: $hashTable\n";

	chomp(my $total=`wc -l < '$hashTable'`);
	open(my $fh, "<$hashTable");
	my $count=0;
	while (<$fh>) {
		chomp;
		my ($hash, $file) = split(/,/);

		$count++;

		print "Processing [$count/$total]\r";
#		`echo 'Processing [$count/$total]' > '$log'`;

		my $pid = $pm->start and next;

		my $v=$table{$file};
		if ($v) {
			my $line=$_;
			$line =~ s/.+?,/$v,/;
			`echo '$line' >> '$hashTableRevised'`;
			
		}else{
			`echo '$_' >> '$hashTableRevised'`;
		}
		
		$pm->finish;
	}

	close($fh);
}

$pm->wait_all_children;

print "\nDone\n";

sub CalcHash {

        my ($token_file) = @_;

	my $hash_value;
        if (-e $token_file) {

		open(my $fh, $token_file);
		my $sha1 = Digest::SHA->new;
		$sha1->addfile($fh);
		$hash_value = $sha1->hexdigest; # Get the hash of the file
		close $fh;
	}

        return ($hash_value);
}

