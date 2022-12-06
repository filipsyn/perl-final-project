package Text;
use locale;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(log10);


sub log10 {

    # Subrutine to calculate decadic logarihm
    # Perl's standard log() function uses e as a base.
    # This code is taken from Perl Func documentation
    # https://perldoc.perl.org/perlfunc#log
    my $n = shift;
    return log($n) / log(10);
}

1;
