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



my $file_name = "load.csv";
my @data;
my $row_counter = 1;

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

open my $fp_save_geo, '>>', "save_geo_".$file_name or die "Cannot open save file";

open my $fp_save_violation, '>>', "save_violation_".$file_name or die "Cannot open save file";

open my $fp_save_statistic, '>>', "save_statistic_".$file_name or die "Cannot open save file";

foreach my $line (@data)
{
	if($csv->parse( $line))
        {
		my @load_masterfields = $csv->fields();


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



		my $previous_location = 0;
		my $previous_violation = 0;
		my $previous_statistic = 0;

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
								$statistic_line_end{$data[$previous_statistic]} = $row_counter - 1;
								print $fp_save_statistic $statistic_line_end{$data[$previous_statistic]}."\n";
							}

							my @tokens = split(/\./, $data[$coordinate_col]);
							$statistic_index{$location}{$violation}{$statistic} = $tokens[2];

							if($statistic eq "actual incidents" and $violation eq "total, all violations" and $location eq "canada")
							{
								print $fp_save_statistic '"'."location".'"'.",".'"'."violation".'"'.",".'"'."statistic".'"'.','.'"'."id".'"'.",".'"'."start_line".'"'.",".'"'."end_line",'"'."\n";
								$statistic_line_start{$statistic} = $row_counter-5;
							}
							else
							{
								$statistic_line_start{$statistic} = $row_counter;
							}
							print $fp_save_statistic '"'.$location.'"'.",";
							print $fp_save_statistic '"'.$violation.'"'.",";
							print $fp_save_statistic '"'.$statistic.'"'.",";
							print $fp_save_statistic $statistic_index{$location}{$violation}{$statistic}.",";
							print $fp_save_statistic $statistic_line_start{$statistic}.",";
							$previous_statistic = $statistic_col;
						}	
					}
				}
				else
				{
					if($violation ne "violations")
					{
						if(%statistic_index and $previous_violation ne $violation)
						{
							$violation_line_end{$data[$previous_violation]} = $row_counter - 1;
							print $fp_save_violation $violation_line_end{$data[$previous_violation]}."\n";
						}

						my @tokens = split(/\./, $data[$coordinate_col]);
						$violation_index{$location}{$violation} = $tokens[1];

						if($violation eq "total, all violations" and $location eq "canada")
						{
							print $fp_save_violation '"'."location".'"'.",".'"'."violation".'"'.",".'"'."id".'"'.",".'"'."start_line".'"'.",".'"'."end_line",'"'."\n";
							$violation_line_start{$violation} = $row_counter-5;
						}
						else
						{
							$violation_line_start{$violation} = $row_counter;
						}
						print $fp_save_violation '"'.$location.'"'.",";
						print $fp_save_violation '"'.$violation.'"'.",";
						print $fp_save_violation $violation_index{$location}{$violation}.",";
						print $fp_save_violation $violation_line_start{$violation}.",";
						$previous_violation = $violation_col;
					}
				}	
			}
			else
			{
				if($location ne "geo")
				{

					if(%violation_index and $previous_location ne $location)
					{
						$geo_line_end{$data[$previous_location]} = $row_counter - 1;
						print $fp_save_geo $geo_line_end{$data[$previous_location]};
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
						$geo_line_start{$location} = $row_counter-5;
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
					$previous_location = $geo_col;
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
