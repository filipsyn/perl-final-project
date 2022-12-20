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

    #print "$args{-initial_node}($initial_value) sent $link_input to $args{-terminal_node} which received $link_output\n";
}

# Resets sum of sent and received activation values for node with node ID passed as a parameter
sub reset_totals {
    my $node_id = shift;

    $nodes{$node_id}->{-sent_total} = 0;
    $nodes{$node_id}->{-received_total} = 0;
}

for my $node_id (sort keys %nodes) {
    print "$node_id\t";
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

print "\n";

sub calibrate {

}

sub calibration_total_conservation {

}

sub sum_activation_in_iteration {
    my $iteration_number = shift;
    my $sum = 0;

    for my $node_id (sort keys %nodes) {
        #print "$node_id -> $results[$iteration_number]->{$node_id}\n";
        $sum += $results[$iteration_number]->{$node_id} if (exists $results[$iteration_number]->{$node_id});
    }

    return $sum;
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
        print "$node -> results[$iteration]->{$node}\n" if ($results[$iteration]->{$node});
    }

    print "Iteration $iteration sum $sum\n";
    return $sum;
}

for (my $iteration = 1; $iteration <= $iterations_limit; $iteration++) {
    #print "\nIteration: $iteration of $iterations_limit\n\n";

    # Calculates signal values for each link
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
        #print "Node ID:\t$node_id\n";
        # Calculate new value of node
        my $new_value = $param{a} * $nodes{$node_id}->{-value} + $param{b} * $nodes{$node_id}->{-received_total} + $param{c} * $nodes{$node_id}->{-sent_total};
        #print "Node: $node_id(New value: $new_value)\nA: $param{a}\nInitial value: $nodes{$node_id}->{-value}\nB: $param{b}\nReceived total: $nodes{$node_id}->{-received_total}\nC: $param{c}\nSent total:$nodes{$node_id}->{-sent_total}\n\n\n\n";
        #print "$node_id value $nodes{$node_id}->{-value} -> $new_value\n";

        $nodes{$node_id}->{-value} = $new_value;

        $results[$iteration]{$node_id} = $new_value;
        reset_totals($node_id);
        #print "$node_id -> $nodes{$node_id}->{-value}\n"

        print sprintf("%.5f", $nodes{$node_id}->{-value}), "\t";
    }
    #TODO: Calibrate values of nodes according to set parameter
    #TODO: Check if values are over threshold
    print "\n";
}

use Data::Dumper;
#print Dumper(\%nodes);
#print Dumper(\@links);
#print Dumper(\%reciprocal_links);
#print Dumper(\%link_weights);
#print Dumper(\%initial_activation);
print Dumper(\@results);

#print sum_activation_in_iteration(3);
