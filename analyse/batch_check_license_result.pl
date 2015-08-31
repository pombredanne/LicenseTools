#!/usr/bin/perl

use strict;

my $licenseChange=$ARGV[0];
my $srcUniqList=$ARGV[1];

open my $licFh, ">$licenseChange";

chomp(my @folders = `cat '$srcUniqList'`);

chomp @folders;
my $total=@folders;
my $count=0;

foreach my $folder (@folders) {

        $folder =~ /.*\/(.*?)$/;
        my $group_name = $1;

        my $process = 100*$count/$total;
        my $r = sprintf("%.1f",$process);
        print "[$r%] Done. Check inconsistency for: [$count/$total]";

        my $inconsis = `analyse/check_license_result.pl -d '$folder'`;

        if ($inconsis) {
                print " <-----Inconsis:[$inconsis]";
                print $licFh "$group_name,$folder,$inconsis\n";
        }
        else {
                print " OK.";
        }
        print "\n";
        $count++;
}
close $licFh;

