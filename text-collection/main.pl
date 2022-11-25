use strict;
use Getopt::Long;
use lib '.';
use Text;

# Default values for arguments
our $input_file = "input.txt";
our $minimal_length = 1;
our $minimal_occurance = 1;
our $local_weight = "tp";

our @documents = ();
our @word_in_file = ();

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

    $text = Text::strip_text($text);    

    print "Trida $class, Text: $text\n";

    # List of words in whole line
    my @words = split ' ', $text;
    
    # Initialization of hash of words and occurances.
    my %line;

    for my $word (@words) {
        $line{$word}++ if (length($word) >= $minimal_length);
    }

    if ($local_weight eq 'tp') {
        # In case of local weight set to "Term Presence"
        # Turn values into "1" - occured, "0" - didn't occur
        for my $word (keys %line) {
            $line{$word} = $line{$word} ** 0 unless ($line{$word} == 0);
        }
    }
   

    # Adding document class
    $line{__class__} = $class;
   

    push @documents, \%line;
}

use Data::Dumper;
print Dumper(\@documents);
