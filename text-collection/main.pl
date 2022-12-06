use strict;
use warnings;
use Getopt::Long;

# Default values for arguments
our $input_file = "input.txt";
our $minimal_length = 1;
our $minimal_occurance = 1;
our $local_weight = "tp";

our @documents = ();
our %unique_words;


# Stripes HTML tags and non-letter characters from text. Also uppercases the term to have standardized form of the terms.
# Argument:
#   - "dirty" text
# Returns:
#   - "cleaned" uppercase text
sub clean_term {
    my $text = shift;

    # Striping out HTML tags
    $text =~ s/<([^>]+)>//g;

    # Removing any non-letter character
    $text =~ s/[^[:alpha:][:space:]]/ /g;

    return uc $text;
}


# Subrutine to calculate decadic logarihm
# Perl's standard log() function uses e as a base.
# This code is taken from Perl Func documentation
# https://perldoc.perl.org/perlfunc#log
sub log10 {
    my $n = shift;
    return log($n) / log(10);
}


# Returns number of documents in which searched term occures
# Arguments:
#   - term which is searched across the documents
sub term_occurance_in_documents {
    my $term = uc shift;
    my $count = 0;
    for my $doc (@documents) {
        $count++ if (exists $doc->{$term});
    }

    return $count;
}

# Prints output in form of table
sub print_table {
    # Create table header
    # Header is made out of words that pass the criteria specified by command-line arguments and _class_ column
    my @header = sort keys %unique_words;
    push @header, '_class_';
    print join("\t", @header), "\n";

    # Printing table with values
    for my $doc (@documents) {
        for my $column (@header) {

            # Print class as is and continue to next iteration
            if ($column eq '_class_') {
                print "$doc->{$column}";
                next;
            }

            my $out;

            # If value of this term is not zero, format it so it has up to 5 decimal places.
            # This step ensures correct formatting of table.
            if (exists $doc->{$column}) {
                $out = sprintf('%.5f', $doc->{$column});
            }
            else {
                $out = 0;
            }

            print "$out\t";
        }
        print "\n";
    }

}


# Calculates Inverse Document Frequency factor for term passed as argument.
sub calculate_idf_for_term {
    my $term = shift;
    return log10(scalar(@documents) / term_occurance_in_documents($term));
}

# Sums weight of all terms in document vector, that is passed
# Arguments:
#   - pointer to hash
# Returns:
#   - Sum of all values in passed hash
sub sum_all_weights_in_document {
    my $sum = 0;

    # Retrieving pointer to hash passed as an argument and dereferencing it
    my $arg = shift;
    my %document = %{$arg};

    for my $key (keys %document) {
        $sum += $document{$key} unless ($key eq '_class_');
    }

    return $sum;
}


# Calculates normalization factor for each term in document
# Arguments
#   -weight: Weight of specific term
#   -sum: Sum of all weight in document
# Returns:
#   - Normalization factor for passed values
sub get_normalization_factor {
    my %args = @_;

    die "Incorrect arguments\n-weight and -sum expected\n" unless (exists($args{-weight}) and exists($args{-sum}));

    return $args{-weight} / $args{-sum};
}

# Parsing command line arguments to corresponding variables.
GetOptions(
    "input-file|f=s"        => \$input_file,
    "minimal-length|l=i"    => \$minimal_length,
    "minimal-occurance|n=i" => \$minimal_occurance,
    "local-weight|w=s"      => \$local_weight
) or die "Error in command line arguments\n";

# Checking valid if local_weight has eiher "tp" or "tf" value
die "Invalid local weight value provided.\nPlease provide either 'tp' (default) or 'tf' value\n" unless ($local_weight eq "tp" or $local_weight eq "tf");

open F, "$input_file" or die "Can't open file $input_file\n";

# Processing input file
for my $line (<F>) {
    chomp $line;
    my ($class, $text) = split("\t", $line);

    $text = clean_term($text);

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
    delete $unique_words{$word}
        if ($unique_words{$word} < $minimal_occurance);
}

# Calculate corresponding values for each term in each document.
# Applies global weight and normalization factor.
for my $doc (@documents) {
    my $line_sum = sum_all_weights_in_document($doc);

    while (my ($term, $value) = each %{$doc}) {
        next if ($term eq '_class_');
        $doc->{$term} = $value * calculate_idf_for_term($term) * get_normalization_factor(-weight => $value, -sum => $line_sum);
    }
}

print_table();