#!/usr/bin/perl
use strict;
use warnings;
use version;   our $VERSION = qv('5.16.0'); 
use Text::CSV;
 
my $file = "output.csv" or die "Need to get CSV file on the command line\n";
my $highest = 0;
my $highestyear = 0;
my $highestloc;
my $lowest = 100;
my $lowestyear = 0;
my $lowestloc;
my $compare;
my $line;
my $line_counter = 0;
my $fp;
my $total = 0;
my $average = 0;

my @data = {};
my @year;
my @geo;
my @vio;
my @sta;
my @value;

my $COMMA = q{,};
my $csv = Text::CSV->new({ sep_char => $COMMA});
 
my $recordcount = 0;

open($fp, '<', $file) or die "Could not open '$file' $!\n";
 	@data = <$fp>; 
 close $fp or 
 die "unable to close\n";

foreach my $line (@data)
{
	if($csv->parse( $line))
	{
		my @load_masterfields = $csv->fields();
		$line_counter++;
	        $year[$line_counter] = $load_masterfields[0];
	        $geo[$line_counter] = $load_masterfields[1];
	        $vio[$line_counter] = $load_masterfields[2];
		    $sta[$line_counter] = $load_masterfields[3];
		    $value[$line_counter] = $load_masterfields[4];
		    if ($value[$line_counter] > $highest){
		    	$highest = $value[$line_counter];
				$highestyear = $year[$line_counter];
				$highestloc = $geo[$line_counter];
			}
			if ($value[$line_counter] < $lowest){
		    	$lowest = $value[$line_counter];
				$lowestyear = $year[$line_counter];
				$lowestloc = $geo[$line_counter];

			}

			$total = $value[$line_counter] + $total;

	}else {

		print"ERROR";
	}
}

print "FINALS\n";
print "$line_counter\n";
print "$highestyear\n";
print "$lowestyear\n";
print "$total\n";

$average = $total / $line_counter;

print "$average\n";

print "$highestloc\n";
print "$lowestloc\n";
