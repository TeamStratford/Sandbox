#!/usr/bin/perl
use strict;
use warnings;
use version;   our $VERSION = qv('5.16.0'); 
use Text::CSV;
 
my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";
my $highest = 0;
my $highestyear = 0;
my $compare;
my $line;
 
my $recordcount = 0;

open(my $data, '<', $file) or die "Could not open '$file' $!\n";
 
while ($line = <$data>) {
  chomp $line;
  my @fields = split ",", $line;
  if($fields[2] > $highest){
  	$highest = $fields[2];
  	$highestyear = $fields[1];
  }

  $recordcount++;
}
print "$highestyear\n";