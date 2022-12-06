package Text;
use locale;

use Exporter;
@ISA    = qw (Exporter);
@EXPORT = qw (strip_text in_array log10);

sub strip_text {

    # Stripes HTML tags and non-letter characters from text.
    # Returns cleaned text in uppercase, to standardize the text.

    # Takes "dirty" text as only argument
    my $text = shift;

    # Striping out HTML tags
    $text =~ s/<([^>]+)>//g;

    # Removing any non-letter character
    $text =~ s/[^[:alpha:][:space:]]/ /g;

    return uc $text;
}


sub log10 {

    # Subrutine to calculate decadic logarihm
    # Perl's standard log() function uses e as a base.
    # This code is taken from Perl Func documentation
    # https://perldoc.perl.org/perlfunc#log
    my $n = shift;
    return log($n) / log(10);
}

1;
