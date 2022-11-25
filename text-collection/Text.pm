package Text;

use Exporter;
@ISA = qw (Exporter);
@EXPORT = qw (strip_text);


sub strip_text {
    # Stripes HTML tags and non-letter characters from text.
    # Returns cleaned text in uppercase, to standardize the text.

    # Takes "dirty" text as only argument
    my $text = shift;

    # Striping out HTML tags
    $text =~ s/(<([^>]+)>)//g;

    # Removing any non-letter character
    $text =~ s/[^[:alpha:][:space:]]//g;

    return uc $text;
}

1;