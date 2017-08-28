#!/usr/bin/perl
#
#   Packages and modules
#
#use strict;
use warnings;
use version;
use Encode;
use utf8;
use Getopt::Std;
our $VERSION = qv('5.16.0'); # This is the version of Perl to be used
use Text::CSV  1.32;   # We will be using the CSV module (version 1.32 or higher)
use POSIX;
use Statistics::R;
$|++;
# to parse each line
#
#   userInput.pl
#      Author(s): Team Ottawa
#      Project: Group Project
#      Date of Last Update: March 29, 2017

#
#      Variables to be used
#
my $EMPTY = q{};
my $SPACE = q{ };
my $crimefile = $EMPTY;
my $addCity = "";
my @records;
my @year;
my @city;
my @violation;
my @statistic;
my @vector;
my @coordinate;
my @value;
my $COMMA = q{,};
my $csv = Text::CSV->new({ sep_char =>$COMMA });
my $searchAgain = "";
my @searchResults;
my @statList;
my $R = Statistics::R->new();

#
#    The program takes one argument as the name of the crime CSV file
#    to open. Error is given if input does not match the required
#    number of arguments.
#
my $fail = 0;
if ($#ARGV != 0 ) {
    $fail = 1;
}
elsif (substr($ARGV[0],length($ARGV[0])-4,length($ARGV[0])-1) eq ".csv") {
	$crimefile = $ARGV[0];
}
else {
	$fail = 1;
}

if ($fail) {
	print "Usage: userInput.pl <crimefile.csv>\n" or
    die "Print failure\n";
    exit;
}

open (my $fh, '<:encoding(CP1252)', $crimefile)
   or die "Unable to open file: $crimefile\n";

print "Reading file $crimefile ... \n";

@records = <$fh>;
close $fh or
die "Unable to close: $crimefile\n";

print $#records+1 . " records in file\n";

print "\nParsing file. Please wait...\n";
my $loadBarDivider = ceil(($#records+1)/100)+1;
my $loadBar = '_' x ceil(($#records+1)/$loadBarDivider);
print $loadBar . "\n";

####### Parse file ######
#### Replace accented characters with regular ones ########

my $recordCount = 0;
my $searchStr = '\x{E9}';
my $searchStr2 = '\x{E8}';
my $replaceStr = 'e';

foreach my $crime_record ( @records ) {
    Encode::from_to($crime_record, "CP1252", "utf8");
	$crime_record = decode_utf8( $crime_record );

    if ($crime_record =~ m/$searchStr/) {
        $crime_record =~ s/$searchStr/$replaceStr/;
    }

    if ($crime_record =~ m/$searchStr2/) {
        $crime_record =~ s/$searchStr2/$replaceStr/;
    }

    if ( $csv->parse($crime_record) ) {
		$recordCount++;
       	my @master_fields = $csv->fields();
        $year[$recordCount] = $master_fields[0];
        $city[$recordCount]     = $master_fields[1];
        $violation[$recordCount] = $master_fields[2];
        $statistic[$recordCount] = $master_fields[3];
        $vector[$recordCount] = $master_fields[4];
        $coordinate[$recordCount] = $master_fields[5];
        $value[$recordCount] = $master_fields[6];
        if ((not (grep { $_ eq $statistic[$recordCount]} @statList)) and $recordCount > 1) {
			push @statList, $statistic[$recordCount];
		}
    } else {
        warn "Line/record could not be parsed: $records[$recordCount]\n";
    }

    if ($recordCount % $loadBarDivider == 0) {
		print '>';
	}
}

print "\n$recordCount records parsed\n";
my $runFlag = 0;
while ($runFlag == 0) {

	my $operation = 0;

	print "What do you want to do?\n";
	print "(1) Find all statistics about a particular violation in one or more locations.\n";
	print "(2) Track a statistic for any violation in a single location over multiple years.\n";
	print "(3) Exit.\n";

	print "Enter Choice: ";
	$operation = <STDIN>;
	chomp $operation;

	if ($operation == 3) {
		print "Exiting ... \n";
		exit;
	}

	my $flag = 0;
	my $locationStr = "";
	my @cityPos;
	my @cityStr;
	my $n = 1;
	my $addFlag = 0;
	my $addAnother = "";
	my $runAgain = "";
	my @addedLocs;
	
	###### Search Location #########
	while ($flag < 1) {
		print "\n";
		
		while ($locationStr eq "") {
			print "Search for a location: ";
			$locationStr = <STDIN>;
			chomp $locationStr;
		}
		
		print "\n";

		for my $k (2..$recordCount) {
			if ((not (grep { $_ eq $city[$k]} @searchResults)) and $city[$k] =~ m/$locationStr/i) {
				print "LOCATION MATCH: ".$city[$k]."\n";
           
				while ( ($addCity ne "Yes") and ($addCity ne "No") and ($addCity ne "Q") ) {
					my $prompt;
					if ($operation == 2) {
					$prompt = "Select Location?";
					}
					else {
					$prompt = "Add Location?";
					}
					print "$prompt (Yes/No/Q: go to search): ";
					$addCity = <STDIN>;
					chomp $addCity;
							
					if ($addCity eq "Yes") {
						if (not (grep { $_ eq $city[$k]} @addedLocs)) {
							$cityPos[$n] = $k;
							$cityStr[$n] = $city[$k];
							$n = $n + 1;
							$cityPos[$n] = 0;
							push @addedLocs, $city[$k];
						}			
					}
							
					if ($addCity eq "No") {
						next;
					}
				}
				push @searchResults, $city[$k];
				
				if ($addCity eq "Q") {
					$addCity = "";
					last;
				}
				
				$addCity = "";
				
				if (@cityPos and $operation == 2) {
					last;
				}
            }
		}

		if (not @searchResults) {
			print "No matches found\n";
		}

		if (@cityPos and $operation != 2) {
			print "\n";
			while ( ($searchAgain ne "Yes") and ($searchAgain ne "No") ) {
				print "Look for another location? (Yes/No): ";
				$searchAgain = <STDIN>;
				chomp $searchAgain;
				if ($searchAgain eq "Yes") {
					$flag = 0;
				}
				if ($searchAgain eq "No") {
					$flag = 1;
				}
			}
		}

		if (@cityPos and $operation == 2) {
			$flag = 1;
		}

		$searchAgain = "";
		@searchResults = ();
		$locationStr = "";
	}

	####### Search for violation ############
	my $violationSelector = 0;
	while ($violationSelector ne "1" && $violationSelector ne "2") {
		print "\nAre you looking for data on (1) all violations or (2) a specific violation? ";
		$violationSelector = <STDIN>;
		chomp $violationSelector;
	}

	my $violationSearch = "";
	$flag = 0;
	@searchResults = ();
    
    my @violationMatches;
    my $z = 1;

	# User types in a query, then regex searches for any matching crime.
	# The loop only needs to go through the first 53000 records, as all crimes
	# are accounted for in the first 53000 records.
	if ($violationSelector eq "2") {
		while ($flag < 1) {
			print "\n";
			while ($violationSearch eq "") {
				print "Search for a violation: ";
				$violationSearch = <STDIN>;
				chomp $violationSearch;
			}
			print "\n";

			for my $k (2..52999) {
				if ((not (grep { $_ eq $violation[$k]} @searchResults)) and $violation[$k] =~ m/$violationSearch/i) {
                    $violationMatches[$z] = $k;
                    print "($z) CRIME MATCH: ".$violation[$k]."\n";
                    $z = $z + 1;
					push @searchResults, $violation[$k];
				}
			}

			if (not @searchResults) {
				print "No matches found\n";
			}
			
			print "\n";
            
            if (@searchResults) {
				while ( ($searchAgain ne "Yes") and ($searchAgain ne "No") ) {
					print "Look for a different violation? (Yes/No): ";
					$searchAgain = <STDIN>;
					chomp $searchAgain;
					if ($searchAgain eq "Yes") {
						$flag = 0;
					}
					if ($searchAgain eq "No") {
						$flag = 1;
					}
				}
            }
            
			
			$searchAgain = "";
			@searchResults = ();
			$violationSearch = "";
		}

		my $violationIndex = 0;
		while ($violationIndex < 1 or $violationIndex > $z) {
			print "\nSelect a violation number: ";
			$violationIndex = <STDIN>;
			chomp $violationIndex;
		}
		$violationIndex = $violationMatches[$violationIndex];
		$violationSearch = $violation[$violationIndex];

	}
	else {
		$violationSearch = $violation[2];
	}

	######## Choose Year ############
	my $startYear = 0;
	my $endYear = 0;
	
	my $yearStr = 0;

	if ($operation == 1) {
	while (($yearStr < 1998) || ($yearStr > 2015)) {
		print "1998-2015 only. Which year are you looking for?: ";
		$yearStr = <STDIN>;
		chomp $yearStr;
	}
	}
	else {
		print "\nWhich years are you looking for?\n";
		while ($startYear < $year[$cityPos[1]] || $startYear > 2014) {
			print "Select the starting year ($year[$cityPos[1]]-2014): ";
			$startYear = <STDIN>;
			chomp $startYear;
		}
		while ($endYear <= $startYear || $endYear > 2015) {
			print "Select the ending year ($startYear-2015): ";
			$endYear = <STDIN>;
			chomp $endYear;
		}
		
	}
	
	############## Choose stat (operartion 2) #############
	my $chosenStat = 0;
	if ($operation == 2) {
		print "\nPick a Statistic: \n";
			for my $i (0..$#statList) {
				print "(" . ($i+1) . ") $statList[$i]\n";
			}
			print "\n";
			while ($chosenStat < 1 or $chosenStat > $#statList+1) {
				print "Enter Choice: ";
				$chosenStat = <STDIN>;
				chomp $chosenStat;
			}
			$chosenStat--;
	}

	print "\nStatistics for violation: $violationSearch\n\n";
	
	my $dataExists = 0;	
	####### OUTPUT STAGE #########
	for my $j (1..$#cityPos-1) {
		my $title = "Location [$j]: $cityStr[$j]";
		my $bar = '-' x ceil((75-(length $title))/2);
		print $bar . $title . $bar. "\n";
        	
		my $matchFound = 0;
		for my $index ($cityPos[$j]..$recordCount) {
			if (not ($city[$index] eq $cityStr[$j])) {
				last;
			}
			
			if ($operation == 1) {
				if ($violation[$index] eq $violationSearch and $year[$index] == $yearStr) {
					printf "%-75s | %s\n", $statistic[$index], $value[$index];
					$matchFound = 1;
					$dataExists = 1;
				}
			}
			else {
				if ($violation[$index] eq $violationSearch and $year[$index] <= $endYear and $year[$index] >= $startYear and $statistic[$index] eq $statList[$chosenStat]) {
					printf "($year[$index]) %-75s | %s\n", $statistic[$index], $value[$index];
					$matchFound = 1;
					$dataExists = 1;
				}
			}
			
			$index++;
		}
		if ($matchFound == 0) {
			print "No data for this year.";
		}
		print "\n";
	}
	
	######## PROCESS OUTPUT FURTHER OR NO? #########
	if ($dataExists == 1) {
		my $choice = 0;
		print "What do you want to do with this output?\n";
		print "(1) Create a plot for given data\n";
		print "(2) Nothing\n";
		while ($choice < 1 || $choice > 2) {
			print "Enter choice: ";
			$choice = <STDIN>;
			chomp $choice;
		}
		
		print "\n";
		
		my $statChoice = 0;
		if ($choice == 1) {
			if ($operation == 1) {
				print "Pick a Statistic: \n";
				for my $i (0..$#statList) {
					print "(" . ($i+1) . ") $statList[$i]\n";
				}
				while ($statChoice < 1 or $statChoice > $#statList+1) {
					print "Enter Choice: ";
					$statChoice = <STDIN>;
					chomp $statChoice;
				}
				$statChoice--;
				print "\n";
			}
			
			
			my $filename = $operation == 1 ? "barPlot.csv" : "linePlot.csv";
			my $pdfFilename = $operation == 1 ? "barPlot.pdf" : "linePlot.pdf";
			my $city;
			open(my $fh, '>', $filename) or die "Could not write to file\n";
			my $header = $operation == 1 ? "Location,Statistic\n" : "Year,Statistic\n";
			print $fh $header;
			if ($operation == 1) {
				for my $i (1..$#cityPos-1) {
					for my $j ($cityPos[$i]..$recordCount) {	
						if ($violation[$j] eq $violationSearch and $year[$j] == $yearStr and $statistic[$j] eq $statList[$statChoice]) {
							$city = $cityStr[$i];
							if ($city =~ m/$COMMA/) {
								$city =~ s/$COMMA/$EMPTY/;
							}
							print $fh "$city,$value[$j]\n";
							last;
						}
					}
				}
			}
			else {
				$city = $cityStr[1];
				if ($city =~ m/$COMMA/) {
					$city =~ s/$COMMA/$EMPTY/;
				}
				for my $j ($cityPos[1]..$recordCount) {
					if ($city ne $city[$j]) {
						last;
					}	
					if ($violation[$j] eq $violationSearch and $year[$j] >= $startYear and $year[$j] <= $endYear and $statistic[$j] eq $statList[$chosenStat] and $value[$j] ne "..")  {
						print $fh "$year[$j],$value[$j]\n";
					}
				}
			}
			$R->run(qq`pdf("$pdfFilename" , paper="letter")`);
			$R->run(qq`data <- read.csv("$filename")`);
			if ($operation == 1) {
				$R->run(qq`xx <- barplot(names.arg=data\$Location, height=data\$Statistic, ylab="$statList[$statChoice]", cex.axis=0.75, xlab="Location")`);
				$R->run(qq`text(x = xx, y = data\$Statistic, label = data\$Statistic, pos = 1, cex = 0.75, col = "blue")`);
				$R->run(qq`box()`);
				$R->run(qq`title(main="Statistics for $violationSearch", font.main=4)`);
			}
			else {
				$R->run(qq`plot(data\$Statistic, ylab="$statList[$chosenStat]", type="o", xaxt="n", xlab="Year", cex.axis=0.75)`);
				$R->run(qq`axis(1, at=1:length(data\$Year), labels=data\$Year, cex.axis=0.75)`);
				$R->run(qq`box()`);
				$R->run(qq`title(main="$statList[$chosenStat] for $violationSearch in $cityStr[1]", font.main=4)`);
			}
			$R->run(q`dev.off()`);
			$R->stop();
			print "Plot saved as $pdfFilename\n\n";
		}

		######## Run again or quit ############
		while ( ($runAgain ne "Again") and ($runAgain ne "Quit") ) {
			print "Quit Program, or run again? (Quit/Again): ";
			$runAgain = <STDIN>;
			chomp $runAgain;
			if ($runAgain eq "Quit") {
				$runFlag = 1;
				print "Quitting ... \n";
				exit;
			}
			if ($runAgain eq "Again") {
				$runFlag = 0;
			}
		}
	}
}


#
#   End of Script
#
