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
our %unique_words;
# TODO: Remake unique_word to be hash
# word => total occurances


# TODO: Add removing words with low occurance (use remove function for hash)

# Parsing command line arguments to corresponding variables.
GetOptions( "input-file|f=s" => \$input_file,
            "minimal-length|l=i" => \$minimal_length,
            "minimal-occurance|n=i" => \$minimal_occurance,
            "local-weight|w=s" => \$local_weight
) or die "Error in command line arguments\n";

# Checking valid if local_weight has eiher "tp" or "tf" value
die "Invalid local weight value provided.\n
Please provide either 'tp' (default) or 'tf' value\n" 
unless ($local_weight eq "tp" or $local_weight eq "tf");

# Opening input file
open F, "$input_file" or die "Can't open file $input_file\n";

# Processing input file
for my $line (<F>){
    chomp $line;
    my ($class, $text) = split("\t", $line);

    $text = Text::strip_text($text);    

    # List of words in whole line
    my @words = split ' ', $text;
    
    # Initialization of hash of words and occurances.
    my %line;

    # Checking if words in line have the minimal length
    for my $word (@words) {
        if (length($word) >= $minimal_length) {
            $line{$word}++;
            
            # Word is put into hash of unique words
            # word => number of occurances across all documents (lines)
            $unique_words{$word}++;
        }
    }

    if ($local_weight eq 'tp') {
        # In case of local weight set to "Term Presence"
        # Turn values into "1" - occured, "0" - didn't occur
        for my $word (keys %line) {
            $line{$word} = $line{$word} ** 0
            unless ($line{$word} == 0);
        }
    }

    # Adding document class
    $line{_class_} = $class;

    # Pushing line vector into array of documents
    push @documents, \%line;
}

# Remove words with occurance less than specified number of minimal occurances
for my $word (keys %unique_words) {
    delete $unique_words{$word} if ($unique_words{$word} < $minimal_occurance);
}

use Data::Dumper;

print Dumper(\@documents);
print Dumper(\%unique_words)