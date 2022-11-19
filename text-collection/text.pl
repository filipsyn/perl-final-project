use Getopt::Long;

# Default values for arguments
$input_file = "input.txt";
$minimal_length = 1;
$minimal_occurance = 1;
$local_weight = "tp";

# Parsing command line arguments to corresponding variables.
GetOptions( "input|i=s" => \$input_file,
            "minimal-length|l=i" => \$minimal_length,
            "minimal-occurance|n=i" => \$minimal_occurance,
            "local-weight|w=s" => \$local_weight
) or die "Error in command line arguments\n";

print "$input_file $minimal_length $minimal_occurance $local_weight\n";

print "Hello world", "\n";
