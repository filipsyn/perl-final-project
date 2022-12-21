use strict;
use warnings;
use Getopt::Long;

#################################
# GLOBAL VARIABLES DECLARATIONS #
#################################

our $Input_File = "input.txt";
our $Minimal_Length = 1;
our $Minimal_Occurrence = 1;
our $Local_Weight = "tp";

our @Documents = ();
our %Term_Occurrence_Of;

###########################
# SUBROUTINE DECLARATIONS #
###########################

# Stripes HTML tags and non-letter characters from text. Also turns the term uppercase to have standardized form of the terms.
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


# Subroutine to calculate decimal logarithm
# Perl's standard log() function uses e as a base.
# This code is taken from Perl Func documentation
# https://perldoc.perl.org/perlfunc#log
sub log10 {
    my $n = shift;
    return log($n) / log(10);
}


# Returns number of documents in which searched term occurs
# Arguments:
#   - term which is searched across the documents
sub term_occurrence_in_documents {
    my $term = uc shift;
    my $count = 0;
    for my $doc (@Documents) {
        $count++ if (exists $doc->{$term});
    }

    return $count;
}

# Prints output in form of table
sub print_table {
    # Create table header
    # Header is made out of words that pass the criteria specified by command-line arguments and _class_ column
    my @header = sort keys %Term_Occurrence_Of;
    push @header, '_class_';
    print join("\t", @header), "\n";

    for my $doc (@Documents) {
        for my $term (@header) {
            # Print class as is and continue to next iteration
            if ($term eq '_class_') {
                print "$doc->{$term}";
                next;
            }

            my $output = (exists $doc->{$term}) ? $doc->{$term} : 0;
            printf "%.5f\t", $output;
        }
        print "\n";
    }
}


# Calculates Inverse Document Frequency factor for term passed as argument.
sub calculate_idf_for_term {
    my $term = shift;
    return log10(scalar(@Documents) / term_occurrence_in_documents($term));
}

# Sums weight of all terms in document vector, that is passed
# Arguments:
#   - pointer to hash
# Returns:
#   - Sum of all values in passed hash
sub sum_all_weights_in_document {
    my $sum = 0;

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
sub calculate_normalization_factor {
    my %args = @_;

    die "Incorrect arguments\n-weight and -sum expected\n" unless (exists($args{-weight}) and exists($args{-sum}));

    return $args{-weight} / $args{-sum};
}


##############
# MAIN LOGIC #
##############

# Parsing command line arguments to corresponding variables.
GetOptions(
    "input-file|f=s"        => \$Input_File,
    "minimal-length|l=i"    => \$Minimal_Length,
    "minimal-occurrence|n=i" => \$Minimal_Occurrence,
    "local-weight|w=s"      => \$Local_Weight
) or die "Error in command line arguments\n";

# Checking valid if local_weight has either "tp" or "tf" value
die "Invalid local weight value provided.\nPlease provide either 'tp' (default) or 'tf' value\n"
    unless ($Local_Weight eq "tp" or $Local_Weight eq "tf");

open F, "$Input_File" or die "Can't open file $Input_File\n";

# Processing input file
for my $line (<F>) {
    chomp $line;
    my ($class, $text) = split("\t", $line);

    $text = clean_term($text);

    # List of words in whole line
    my @words = split /\s+/, $text;

    # Initialization of hash of words and occurrences.
    my %line;

    # Checking if words in line have the minimal length
    for my $word (@words) {
        if (length($word) >= $Minimal_Length) {
            $line{$word}++;

            # Word is put into hash of unique words
            # word => number of occurrences across all documents (lines)
            $Term_Occurrence_Of{$word}++;
        }
    }

    if ($Local_Weight eq 'tp') {
        # In case of local weight set to "Term Presence"
        # Turn values into "1" - occurred, "0" - didn't occur
        for my $word (keys %line) {
            $line{$word} = $line{$word} ** 0
                unless ($line{$word} == 0);
        }
    }

    # Adding document class
    $line{_class_} = $class;

    # Pushing line vector into array of documents
    push @Documents, \%line;
}

# Remove words with occurrence less than specified number of minimal occurrences
for my $word (keys %Term_Occurrence_Of) {
    delete $Term_Occurrence_Of{$word}
        if ($Term_Occurrence_Of{$word} < $Minimal_Occurrence);
}

# Calculate corresponding values for each term in each document.
# Applies global weight and normalization factor.
for my $doc (@Documents) {
    my $line_sum = sum_all_weights_in_document($doc);

    while (my ($term, $value) = each %{$doc}) {
        next if ($term eq '_class_');
        $doc->{$term} = $value * calculate_idf_for_term($term) * calculate_normalization_factor(-weight => $value, -sum => $line_sum);
    }
}

print_table();