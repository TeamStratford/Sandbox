#!/usr/bin/perl
#
#   Packages and modules
#
use strict;
use warnings;
use version;   our $VERSION = qv('5.16.0');   # This is the version of Perl to be used
use Text::CSV  1.32;   # We will be using the CSV module (version 1.32 or higher)

my $EMPTY = q{};
my $SPACE = q{ };
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
		open my $fp_save, '>>', "save_".$file_name
		or die "Cannot open save file";

		for(0 .. $column_counter)
		{
			if(exists $geo_index{$data[$geo_col]})
			{

			}
			else
			{
				if($data[$geo_col] ne "GEO")
				{
					if(%geo_index and $previous_location ne $data[$geo_col])
					{
						$geo_line_end{$data[$previous_location]} = $row_counter - 1;
						print $fp_save $geo_line_end{$data[$previous_location]};
					}

					#Split coordinate from decimal values
					my @tokens = split(/\./, $data[$coordinate_col]);

					#Add ID to string location
					$geo_index{$data[$geo_col]} = $tokens[0];
				
					#Assigns start line number (from the csv) to ID
					#
					#Note: There was a strange bug regarding Canada's output
					#      being offset by 5, therefore it was patched.
					#      This did not affect any other datapoints.
					if($data[$geo_col] eq "Canada")
					{
						print $fp_save '"'."geo_loc".'"'.",".'"'."id".'"'.",".'"'."start_line".'"'.",".'"'."end_line",'"'."\n";
						$geo_line_start{$data[$geo_col]} = $row_counter-5;
					}
					else
					{
						$geo_line_start{$data[$geo_col]} = $row_counter;
						print $fp_save "\n";
					}
					print "Loaded: ".$data[$geo_col]."\n";

					print $fp_save '"'.$data[$geo_col].'"'.",";
					print $fp_save $geo_index{$data[$geo_col]}.",";
					print $fp_save $geo_line_start{$data[$geo_col]}.",";
					$previous_location = $geo_col;
				}
			}

		}
		close $fp_save;
		$row_counter++;
	}
	
}
