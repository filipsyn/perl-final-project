use strict;

# Declaration of global structures
##################################

# Nodes hash
# Structure:
#   id => {
#       -type,
#       -value
#   }
our %nodes;

# Array of links hash
# Structure:
#   {
#       -initial_node,
#       -terminal_node,
#       -type,
#       -weight
#   }
our @links;

# Beta parameter
# Used for calculating value sent to other nodes
our $beta;

# Number of iterations that algorithm runs for
our $iterations_limit;

# Decides what type of calibration is used to normalize node values
our $calibration_type;

# Parameters hash
# Parameters a, b and c are used to calculate new values of nodes
our %param = ( a => 0, b => 0, c => 0 );

# Main logic
############

open F, "params.txt" or die "Can't open params.txt file\n";

# Processing input file with parameters
for my $line (<F>) {

    # Skip comments or empty lines
    next if ( $line =~ /^#/ or $line =~ /^\s/ );

    # Split line values into array
    # Some values are separated by multiple tabs.
    my @conf = split /\t+/, $line;


    $beta = @conf[1] if (@conf[0] eq "Beta");
    $iterations_limit = @conf[1] if (@conf[0] eq "IterationsNo");
    $calibration_type = @conf[1] if (@conf[0] eq "Calibration");
    


    # print join ",", @conf;    # Debug printing
}

chomp $calibration_type;
die "Incorrect type of calibration.\n
Accepted values are: 'ConservationOfTotalActivation', 'None', 'ConservationOfInitialActivation'\n
Current value is '$calibration_type"
unless ($calibration_type eq 'ConservationOfTotalActivation' or
        $calibration_type eq 'None' or
        $calibration_type eq 'ConservationOfInitialActivation');

