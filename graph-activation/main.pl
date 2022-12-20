use strict;
use warnings;

# Declaration of global structures
##################################

# Nodes hash of hash reference
# Structure:
#   id => {
#       -type,
#       -value,
#       -sent_total
#       -received_total
#   }
our %nodes;

# Array of hash references describing links between nodes
# Structure:
#   {
#       -initial_node,
#       -terminal_node,
#       -type,
#       -weight
#   }
our @links;

# Array of reference to hash
# Used to store value of nodes throughout iterations of script.
# Each iteration is stored inside its own element (index 0 => initial activation, index 1 => first iteration, ...)
# Structure:
# [
# node_id => -value
# ]
#
our @results;

# Beta parameter
# Used for calculating value sent to other nodes
our $beta;

# Number of iterations that algorithm runs for
our $iterations_limit;

# Decides what type of calibration is used to normalize node values
our $calibration_type;

# Parameters hash
# Parameters a, b and c are used to calculate new values of nodes
our %param = (a => 0, b => 0, c => 0);

our %reciprocal_links;

our %link_weights;

our $threshold;

our %initial_activation;

our @calibration_nodes;

# Subroutines declarations
##########################


# Calculates outdegree for passed node id
sub outdegree {
    my $node = shift;
    my $count = 0;

    for my $link (@links) {
        $count++ if ($$link{-initial_node} eq $node
            or (($$link{-terminal_node} eq $node) and (is_reciprocal($reciprocal_links{$$link{-type}}))));
    }

    return $count;
}

# Find if link type passed in as a parameter is reciprocal type of link
# Returns "truthy" or "falsy" value
sub is_reciprocal {
    my $link_type = shift;

    for my $type (sort values %reciprocal_links) {
        return 1 if ($link_type eq $type);
    }

    return 0;
}

# Subroutine that sends activation signal from initial node to terminal node.
# Subroutine finds
# Arguments:
#   -initial_node: ID of initial node (string)
#   -terminal_node: ID of terminal node (string)
#   -weight: Weight of link (real number)
sub send_activation {
    my %args = @_;

    my $initial_value = $nodes{$args{-initial_node}}->{-value};

    my $link_input = $initial_value * 1 / outdegree($args{-initial_node}) ** $beta;
    my $link_output = $link_input * $args{-weight};

    $nodes{$args{-initial_node}}->{-sent_total} += $link_input;
    $nodes{$args{-terminal_node}}->{-received_total} += $link_output;
}

# Resets sum of sent and received activation values for node with node ID passed as a parameter
sub reset_totals {
    my $node_id = shift;

    $nodes{$node_id}->{-sent_total} = 0;
    $nodes{$node_id}->{-received_total} = 0;
}

sub calibrate {
    my $iteration = shift;
    return if ($calibration_type eq 'None');
    my $ratio = sum_activation_in_nodes($iteration - 1, @calibration_nodes) / sum_activation_in_nodes($iteration, @calibration_nodes);

    for my $node_id (keys %nodes) {
        $results[$iteration]->{$node_id} *= $ratio;
    }
}


# Subroutine to calculate sum of values of specified nodes in specified iteration
# Parameters:
#   - iteration: First argument - specifies iteration in which are activation values searched
#   - nodes: Rest of arguments - IDs of nodes which values should be summed
sub sum_activation_in_nodes {
    my $iteration = shift;
    my @nodes = @_;
    my $sum = 0;

    for my $node (@nodes) {
        $sum += $results[$iteration]->{$node} if ($results[$iteration]->{$node});
    }

    return $sum;
}

sub print_table {
    # Construct table header
    my @header = sort keys %nodes;
    unshift @header, "Iter.";
    print join("\t", @header), "\n";
    shift @header;

    for (my $iteration = 0; $iteration <= $iterations_limit; $iteration++) {
        print "$iteration\t";
        for my $node_id (@header) {
            # Checking if printed value is initialized, so the interpreter won't complain that we're trying to access
            # uninitialized value
            if (exists $results[$iteration]->{$node_id}) {
                printf "%.5f\t", $results[$iteration]->{$node_id};
            }
            else {
                printf "%.5f\t", 0;
            }
        }
        print "\n";
    }
}

sub check_threshold {
    my $iteration = shift;

    for my $node_id (keys %nodes) {
        $results[$iteration]->{$node_id} = 0 if ($results[$iteration]->{$node_id} < $threshold);
    }
}

# Main logic
############

open F, "params.txt" or die "Can't open params.txt file\n";

# Processing input file with parameters
for my $line (<F>) {

    # Skip comments or empty lines
    next if ($line =~ /^#/ or $line =~ /^\s/);

    # Split line values into array
    # Some values are separated by multiple tabs.
    chomp $line;
    my @conf = split /\s+/, $line;

    # Parsing configuration to prepared data structures
    $beta = $conf[1] if ($conf[0] eq "Beta");
    $iterations_limit = $conf[1] if ($conf[0] eq "IterationsNo");
    $calibration_type = $conf[1] if ($conf[0] eq "Calibration");
    $nodes{ $conf[1] } = { -type => $conf[2], -value => 0, -sent_total => 0, -received_total => 0 }
        if ($conf[0] eq 'n');
    push @links, { -initial_node => $conf[1], -terminal_node => $conf[2], -type => $conf[3] }
        if ($conf[0] eq 'l');

    $reciprocal_links{$conf[1]} = $conf[2] if ($conf[0] eq 'ltra');
    $link_weights{$conf[1]} = $conf[2] if ($conf[0] eq 'lw');
    $threshold = $conf[1] if ($conf[0] eq 't');
    $initial_activation{$conf[1]} = $conf[2] if ($conf[0] eq 'ia');
    $param{a} = $conf[1] if ($conf[0] eq 'a');
    $param{b} = $conf[1] if ($conf[0] eq 'b');
    $param{c} = $conf[1] if ($conf[0] eq 'c');
}

chomp $calibration_type;
die "Incorrect type of calibration.\n
Accepted values are: 'ConservationOfTotalActivation', 'None', 'ConservationOfInitialActivation'\n
Current value is '$calibration_type"
    unless ($calibration_type eq 'ConservationOfTotalActivation'
        or $calibration_type eq 'None'
        or $calibration_type eq 'ConservationOfInitialActivation');

# Assign initial activation values to corresponding nodes
while (my ($node, $value) = each %initial_activation) {
    $nodes{$node}->{-value} = $value;
    $results[0]{$node} = $value;
}

# Assign ID of nodes upon which will be calibration values calculated
if ($calibration_type eq 'ConservationOfInitialActivation') {
    for my $node_id (keys %initial_activation) {
        push @calibration_nodes, $node_id
    }
}

if ($calibration_type eq 'ConservationOfTotalActivation') {
    for my $node_id (keys %nodes) {
        push @calibration_nodes, $node_id;
    }
}

for (my $iteration = 1; $iteration <= $iterations_limit; $iteration++) {

    for my $link (@links) {
        my $initial_node = $$link{-initial_node};
        my $terminal_node = $$link{-terminal_node};
        my $initial_value = $nodes{$initial_node}->{-value};
        my $weight = $link_weights{$$link{-type}};

        send_activation(-initial_node => $initial_node, -terminal_node => $terminal_node, -weight => $weight);

        # Check if this link type is reciprocal
        next unless (exists $reciprocal_links{$$link{-type}});

        # Find link weight corresponding to reciprocal link
        $weight = $link_weights{$reciprocal_links{$$link{-type}}};
        ($initial_node, $terminal_node) = ($terminal_node, $initial_node);
        $initial_value = $nodes{$initial_node}->{-value};

        send_activation(-initial_node => $initial_node, -terminal_node => $terminal_node, -weight => $weight);
    }

    for my $node_id (sort keys %nodes) {
        my $new_value = $param{a} * $nodes{$node_id}->{-value} + $param{b} * $nodes{$node_id}->{-received_total} + $param{c} * $nodes{$node_id}->{-sent_total};

        $nodes{$node_id}->{-value} = $new_value;

        $results[$iteration]{$node_id} = $new_value;
        reset_totals($node_id);
    }

    calibrate($iteration);
    check_threshold($iteration);
}

use Data::Dumper;
print_table();