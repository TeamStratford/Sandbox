#!/usr/bin/perl
#
#   Packages and modules
#
use strict;
use warnings;
use version;   our $VERSION = qv('5.16.0');   # This is the version of Perl to be used
use Text::CSV  1.32;   # We will be using the CSV module (version 1.32 or higher)
use feature qw( unicode_strings );

my $COMMA = q{,};
my $csv = Text::CSV->new({ sep_char => $COMMA});

#For the purposes of the demo and time constraints, we hardcoded the filename to
#prevent the user from inputting invalid filenames.
#This functionality can be added by prompting the user for input and using the following:
#  while (!(-e $file_name))
#  {
#
#  }
my $file_name = "load.csv";

my @data;
my $row_counter = 1;
my $line_counter = 1;
open my $fileHandler, '<', $file_name
or die "Unable to open file: $file_name\n";

	@data = <$fileHandler>;
close $fileHandler
or die "Unable to close fileHandler\n";

my $coordinate_col = 0;
my $geo_col = 0;
my $violation_col = 0;
my $statistic_col;

my %geo_index;
my %geo_line_start;
my %geo_line_end;

my %violation_index;
my %violation_line_start;
my %violation_line_end;

my %statistic_index;
my %statistic_line_start;
my %statistic_line_end;

my @year;
my @geo;
my @vio;
my @sta;
my @vect;
my @coord;
my @val;
#####################init()#####################
# Description: Loads the crime data CSV to memory and loads the values 
#              of the columns into an associaive array if all save files
#              do not already exist (NOT YET, SOON....). 
#	       
#              The hash values are based off of the coordinate column of 
#              the CSV file for 'index' vars. Each column will also have
#              a hash to store each start and end line number.
#
# Usage:       init();
#
# Preconditions: Crime data CSV file exists and atleast one of the save files
#		 are not present.(NOT YET, SOON....)
#
# Postconditions: Coordinate values are assigned to each column by assiociating
#		  string values into a associative arrays. Start lines and end lines of 
#		  each combination are stored into separate associative arrays.
sub init 
{
open my $fp_save_geo, '>>', "save_geo_".$file_name or die "Cannot open save file";

open my $fp_save_violation, '>>', "save_violation_".$file_name or die "Cannot open save file";

open my $fp_save_statistic, '>>', "save_statistic_".$file_name or die "Cannot open save file";

my $previous_location = "canada";
my $previous_violation = "total, all violations";
my $previous_statistic = "actual incidents";

foreach my $line (@data)
{
	if($csv->parse( $line))
        {
		my @load_masterfields = $csv->fields();
                $year[$line_counter] = $load_masterfields[0];
                $geo[$line_counter] = $load_masterfields[1];
                $vio[$line_counter] = $load_masterfields[2];
		$sta[$line_counter] = $load_masterfields[3];
		$vect[$line_counter] = $load_masterfields[4];
		$coord[$line_counter] = $load_masterfields[5];
		$val[$line_counter] = $load_masterfields[6];
		$line_counter++;
		my $column_counter = 0;
		#This loop counts the number of columns and tracks values for the coordinates
		
		while (defined $load_masterfields[$column_counter + 1])
		{
			$data[$column_counter] = $load_masterfields[$column_counter];
			if($data[$column_counter] eq "Coordinate")
			{
				$coordinate_col = $column_counter;
			}
			if($data[$column_counter] eq "GEO")
			{
				$geo_col = $column_counter;
			}
			if($data[$column_counter] eq "VIOLATIONS")
			{
				$violation_col = $column_counter;
			}
			if($data[$column_counter] eq "STA")
			{
				$statistic_col = $column_counter;
			}
			$column_counter++;
		}


		for(0 .. $column_counter)
		{
			my $location = lc($data[$geo_col]);
			my $violation = lc($data[$violation_col]);
			my $statistic = lc($data[$statistic_col]);

			if(exists $geo_index{$location})
			{

				if(exists $violation_index{$location}{$violation})
				{
					if(exists $statistic_index{$location}{$violation}{$statistic})
					{

					}
					else
					{
						if($statistic ne "sta")
						{
							if(%statistic_index and $previous_statistic ne $statistic)
							{
								$statistic_line_end{$previous_location}{$previous_violation}{$previous_statistic} = $row_counter - 1;
								print $fp_save_statistic $statistic_line_end{$previous_location}{$previous_violation}{$previous_statistic}."\n";
							}

							my @tokens = split(/\./, $data[$coordinate_col]);
							$statistic_index{$location}{$violation}{$statistic} = $tokens[2];

							if($statistic eq "actual incidents" and $violation eq "total, all violations" and $location eq "canada")
							{
								print $fp_save_statistic '"'."location".'"'.",".'"'."violation".'"'.",".'"'."statistic".'"'.','.'"'."id".'"'.",".'"'."start_line".'"'.",".'"'."end_line",'"'."\n";
								$statistic_line_start{$location}{$violation}{$statistic} = $row_counter-5;
							}
							else
							{
								$statistic_line_start{$location}{$violation}{$statistic} = $row_counter;
							}
							print $fp_save_statistic '"'.$location.'"'.",";
							print $fp_save_statistic '"'.$violation.'"'.",";
							print $fp_save_statistic '"'.$statistic.'"'.",";
							print $fp_save_statistic $statistic_index{$location}{$violation}{$statistic}.",";
							print $fp_save_statistic $statistic_line_start{$location}{$violation}{$statistic}.",";
							$previous_statistic = $statistic;
						}	
					}
				}
				else
				{
					if($violation ne "violations")
					{
						if(%statistic_index and $previous_violation ne $violation)
						{
							$violation_line_end{$previous_location}{$previous_violation} = $row_counter - 1;
							print $fp_save_violation $violation_line_end{$previous_location}{$previous_violation}."\n";
						}

						my @tokens = split(/\./, $data[$coordinate_col]);
						$violation_index{$location}{$violation} = $tokens[1];

						if($violation eq "total, all violations" and $location eq "canada")
						{
							print $fp_save_violation '"'."location".'"'.",".'"'."violation".'"'.",".'"'."id".'"'.",".'"'."start_line".'"'.",".'"'."end_line",'"'."\n";
							$violation_line_start{$location}{$violation} = $row_counter-5;
						}
						else
						{
							$violation_line_start{$location}{$violation} = $row_counter;
						}
						print $fp_save_violation '"'.$location.'"'.",";
						print $fp_save_violation '"'.$violation.'"'.",";
						print $fp_save_violation $violation_index{$location}{$violation}.",";
						print $fp_save_violation $violation_line_start{$location}{$violation}.",";
						$previous_violation = $violation;
					}
				}	
			}
			else
			{
				if($location ne "geo")
				{

					if(%violation_index and $previous_location ne $location)
					{
		
						$geo_line_end{$previous_location} = $row_counter - 1;
						print $fp_save_geo $geo_line_end{$previous_location};
					}

					#Split coordinate from decimal values
					my @tokens = split(/\./, $data[$coordinate_col]);

					#Add ID to string location
					$geo_index{$location} = $tokens[0];
				
					#Assigns start line number (from the csv) to ID
					#
					#Note: There was a strange bug regarding Canada's output
					#      being offset by 5, therefore it was patched.
					#      This did not affect any other datapoints.
					if($data[$geo_col] eq "Canada")
					{
						print $fp_save_geo '"'."geo_loc".'"'.",".'"'."id".'"'.",".'"'."start_line".'"'.",".'"'."end_line",'"'."\n";
						$geo_line_start{$location} = $row_counter;
					}
					else
					{
						$geo_line_start{$location} = $row_counter;
						print $fp_save_geo "\n";
					}

					print "Loaded: ".$location."\n";

					print $fp_save_geo '"'.$location.'"'.",";
					print $fp_save_geo $geo_index{$location}.",";
					print $fp_save_geo $geo_line_start{$location}.",";
					$previous_location = $location;
				}
			}

		}
		$row_counter++;
	}
}
print $fp_save_geo $row_counter."\n";
print $fp_save_violation $row_counter."\n";
print $fp_save_statistic $row_counter."\n";
close $fp_save_geo;
close $fp_save_violation;
close $fp_save_statistic;
}

sub searchGeoVio
{
	my ($geo_name, $vio_name) = @_;
	my $geo_copy = lc($geo_name);
	my $vio_copy = lc($vio_name);
	if(exists $violation_index{$geo_copy}{$vio_copy})
	{

		readLines($violation_line_start{$geo_copy}{$vio_copy}, $violation_line_end{$geo_copy}{$vio_copy});
	}
	
}

sub searchGeoStat
{
	my ($geo_name, $stat_name) = @_;
	my $geo_copy = lc($geo_name);
	my $stat_copy = lc($stat_name);
	
	my @vio_keys = keys %violation_index;
	

	for my $primary_key (keys %violation_index)
	{
		my $child_key = $violation_index{$primary_key};
		for my $secondary_key (keys %$child_key)
		{
			if(exists $statistic_index{$geo_copy}{$secondary_key}{$stat_copy})
			{
				readLines($statistic_line_start{$geo_copy}{$secondary_key}{$stat_copy}, $statistic_line_end{$geo_copy}{$secondary_key}{$stat_copy});
			}
		}
	}
}

sub searchVioStat
{
	my ($vio_name, $stat_name) = @_;
	my $vio_copy = lc($vio_name);
	my $stat_copy = lc($stat_name);
	my @location_keys = %geo_index;
	
	while(@location_keys)
	{
		my $location_key = pop(@location_keys);
		if(exists $statistic_index{$location_key}{$vio_copy}{$stat_copy})
		{
			readLines($statistic_line_start{$location_key}{$vio_copy}{$stat_copy}, $statistic_line_end{$location_key}{$vio_copy}{$stat_copy});
		}
	}
}
sub searchGeoVioStat
{
	my ($geo_name, $vio_name, $stat_name) = @_;
	my $geo_copy = lc($geo_name);
	my $vio_copy = lc($vio_name);
	my $stat_copy = lc($stat_name);
	if(exists $statistic_index{$geo_copy}{$vio_copy}{$stat_copy})
	{

		readLines($statistic_line_start{$geo_copy}{$vio_copy}{$stat_copy}, $statistic_line_end{$geo_copy}{$vio_copy}{$stat_copy});
	}
	
}
sub searchGeo
{
	if(%geo_index)
	{
		my ($geo_location) = @_;
		my $loc_copy = lc($geo_location);
	
		if(exists $geo_index{$loc_copy})
		{
			readLines($geo_line_start{$loc_copy}, $geo_line_end{$loc_copy});
		}
	}
	else
	{
		warn "ERROR: geo_index not initialized\n";
	}

}
sub searchVio
{
	if(%violation_index)
	{
		my ($vio_name) = @_;
		my $vio_copy = lc($vio_name);
		my @loc_keys = keys %geo_index;
		while (@loc_keys)
		{
			my $loc_key = pop(@loc_keys);
			if(exists $violation_index{$loc_key}{$vio_copy})
			{
				readLines($violation_line_start{$loc_key}{$vio_copy}, $violation_line_end{$loc_key}{$vio_copy});
			}
		}
	}
	else
	{
		warn "ERROR: violation_index not initialized\n";
	}

}
sub searchStat
{
	if(%statistic_index)
	{
		my ($stat_name) = @_;
		my $stat_copy = lc($stat_name);

		#Snippet adapted from a post by kennethk
		#Reason: I didn't know how to get to the second level hashes
		#
		#URL: www.perlmonks.org/?node_id=824207
		#Retreived on: April 6th, 2017 5:13PM EST
		for my $primary_key (keys %violation_index)
		{
			my $child_key = $violation_index{$primary_key};
			for my $secondary_key (keys %$child_key)
			{
				if(exists $statistic_index{$primary_key}{$secondary_key}{$stat_copy})
				{
					readLines($statistic_line_start{$primary_key}{$secondary_key}{$stat_copy}, $statistic_line_end{$primary_key}{$secondary_key}{$stat_copy});
				}
			}
		}

	}
	else
	{
		warn "ERROR: statistic_index not initialized\n";
	}

}
sub readLines
{
	my ($minimum, $maximum) = @_;
	$minimum = $minimum +5;
	while ($minimum <= $maximum)
	{
                print $year[$minimum].",";
                print $geo[$minimum].",";
                print $vio[$minimum].",";
		print $sta[$minimum].",";
		print $vect[$minimum].",";
		print $coord[$minimum].",";
		print $val[$minimum]."\n";
		$minimum++;
	}
}
init();
#searchGeoVioStat("canada", "murder, first degree", "actual incidents");
searchVioStat("murder, first degree", "actual incidents");
#searchGeoStat("canada", "actual incidents");
#readLines(2,5);

