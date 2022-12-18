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
        $count++ if ($$link{-initial_node} eq $node);
    }

    return $count;
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
}

chomp $calibration_type;
die "Incorrect type of calibration.\n
Accepted values are: 'ConservationOfTotalActivation', 'None', 'ConservationOfInitialActivation'\n
Current value is '$calibration_type"
    unless ($calibration_type eq 'ConservationOfTotalActivation'
        or $calibration_type eq 'None'
        or $calibration_type eq 'ConservationOfInitialActivation');


# Assign additional details about links like type of reciprocal link and link weights
for my $link (@links) {
    my $reciprocal_type = $reciprocal_links{$$link{-type}};

    $$link{-reciprocal_type} = $reciprocal_type;
    $$link{-weight} = $link_weights{$$link{-type}};
    $$link{-reciprocal_weight} = $link_weights{$reciprocal_type};
}

# Assign initial activation values to corresponding nodes
while (my ($node, $value) = each %initial_activation) {
    $nodes{$node}->{-value} = $value;
}

# Subroutine that sends activation signal from initial node to terminal node.
# Subroutine finds
# Arguments:
#   -initial_node: ID of initial node (string)
#   -terminal_node: ID of terminal node (string)
#   -weight: Weight of link (real number)
sub send_activation {
    my %args = @_;

    # Jump out of function when outdegree of initial node is 0, because signal sent to this link would be 0.
    # Sending 0 value doesnt make sense, because it wont matter when taking totals of sent and received signal values.
    # Also when sending activation signal from node where outdegree is 0 (this makes sense when considering reciprocal
    # relations), zero division would be occurring.
    return if (outdegree($args{-initial_node}) == 0);

    my $initial_value = $nodes{$args{-initial_node}}->{-value};

    my $link_input = $initial_value * 1 / outdegree($args{-initial_node}) ** $beta;
    $nodes{$args{-initial_node}}->{-sent_total} += $link_input;

    my $link_output = $link_input * $args{-weight};
    $nodes{$args{-terminal_node}}->{-received_total} += $link_output;

    print "$args{-initial_node}($initial_value) sent $link_input to $args{-terminal_node} which received $link_output\n";
}

for (my $iteration = 0; $iteration <= $iterations_limit; $iteration++) {
    print "\nIteration: $iteration of $iterations_limit\n\n";
    # Calculates signal values for each link
    for my $link (@links) {
        my $initial_node = $$link{-initial_node};
        my $terminal_node = $$link{-terminal_node};
        my $initial_value = $nodes{$initial_node}->{-value};
        my $weight = $$link{-weight};

        send_activation(-initial_node => $initial_node, -terminal_node => $terminal_node, -weight => $weight);

        # Check if this link type is reciprocal
        next unless (exists $reciprocal_links{$$link{-type}});

        # Find link weight corresponding to reciprocal link
        $weight = $link_weights{$reciprocal_links{$$link{-type}}};

        # Switch initial and terminal nodes
        ($initial_node, $terminal_node) = ($terminal_node, $initial_node);
        $initial_value = $nodes{$initial_node}->{-value};

        print "Reciprocal: ";
        send_activation(-initial_node => $initial_node, -terminal_node => $terminal_node, -weight => $weight);
    }


    # Iterate through all nodes

    # Calculate sum of all signal values sent by the node

    # Calculate sum of all signal values received by this node

    # Calculate new value of node

    # TODO: Calibrate values of nodes according to set parameter

    # Print values of nodes after iteration

}

use Data::Dumper;
print Dumper(\%nodes);
#print Dumper(\@links);
#print Dumper(\%reciprocal_links);
#print Dumper(\%link_weights);
#print Dumper(\%initial_activation);
