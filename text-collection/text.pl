use Getopt::Long;
use strict;

# Default values for arguments
our $input_file = "input.txt";
our $minimal_length = 1;
our $minimal_occurance = 1;
our $local_weight = "tp";

# Parsing command line arguments to corresponding variables.
GetOptions( "input-file|f=s" => \$input_file,
            "minimal-length|l=i" => \$minimal_length,
            "minimal-occurance|n=i" => \$minimal_occurance,
            "local-weight|w=s" => \$local_weight
) or die "Error in command line arguments\n";

# Checking valid if local_weight has eiher "tp" or "tf" value
die "Invalid local weight value provided.\nPlease provide either 'tp' (default) or 'tf' value\n" unless ($local_weight eq "tp" or $local_weight eq "tf");

# Opening input file
open F, "$input_file" or die "Can't open file $input_file\n";

for my $line (<F>){
    chomp $line;
    my ($class, $text) = split("\t", $line);

    # Striping out HTML tags
    $text =~ s/(<([^>]+)>)//g;

    # Removing any non-letter character
    $text =~ s/[^[:alpha:][:space:]]//g;

    # Making text uppercase
    $text = uc $text;


    print "Trida $class, Text: $text\n";
}
