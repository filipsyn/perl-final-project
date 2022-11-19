use Getopt::Long;
use strict;

# Default values for arguments
our $input_file = "input.txt";
our $minimal_length = 1;
our $minimal_occurance = 1;
our $local_weight = "tp";

# Parsing command line arguments to corresponding variables.
GetOptions( "input|i=s" => \$input_file,
            "minimal-length|l=i" => \$minimal_length,
            "minimal-occurance|n=i" => \$minimal_occurance,
            "local-weight|w=s" => \$local_weight
) or die "Error in command line arguments\n";

# Checking valid if local_weight has eiher "tp" or "tf" value
die "Invalid local weight value provided.\nPlease provide either 'tp' (default) or 'tf' value\n" unless ($local_weight eq "tp" or $local_weight eq "tf");

print "$input_file $minimal_length $minimal_occurance $local_weight\n";

print "Hello world", "\n";
