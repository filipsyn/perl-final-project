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
our %Node;

# Array of hash references describing links between nodes
# Structure:
#   {
#       -initial_node,
#       -terminal_node,
#       -type,
#       -weight
#   }
our @Links;

# Array of reference to hash
# Used to store value of nodes throughout iterations of script.
# Each iteration is stored inside its own element (index 0 => initial activation, index 1 => first iteration, ...)
# Structure:
# [
# node_id => -value
# ]
#
our @Results;

# Beta parameter
# Used for calculating value sent to other nodes
our $Beta;

# Number of iterations that algorithm runs for
our $Iterations_Limit;

# Parameters a, b and c are used to calculate new values of nodes
our %Parameter = (a => 0, b => 0, c => 0);

our %Reciprocal_Link_For;

our %Link_Weights;

our $Threshold;

our %Initial_Activation;

our @Calibration_Nodes;

our %Calibration_Types = (
    none    => 'None',
    initial => 'ConservationOfInitialActivation',
    total   => 'ConservationOfTotalActivation'
);

# Decides what type of calibration is used to normalize node values
our $Calibration = $Calibration_Types{none};

our %Keywords = (
    -node_types         => 'nt',
    -link_types         => 'ltra',
    -node               => 'n',
    -link               => 'l',
    -initial_activation => 'ia',
    -link_weight        => 'lw',
    -beta               => 'Beta',
    -iterations_limit   => 'IterationsNo',
    -calibration        => 'Calibration',
    -a                  => 'a',
    -b                  => 'b',
    -c                  => 'c',
    -threshold          => 't'
);


# Subroutines declarations
##########################

# Find if link type passed in as a parameter is reciprocal type of link
# Returns "truthy" or "falsy" value
sub is_reciprocal {
    my $link_type = shift;

    for my $type (sort values %Reciprocal_Link_For) {
        return 1 if ($link_type eq $type);
    }

    return 0;
}

# Calculates outdegree for passed node id
# Also takes in counts reciprocal links into outdegree
sub outdegree {
    my $node = shift;
    my $count = 0;

    for my $link (@Links) {
        $count++ if ($$link{-initial_node} eq $node
            or (($$link{-terminal_node} eq $node) and (is_reciprocal($Reciprocal_Link_For{$$link{-type}}))));
    }

    return $count;
}

# Subroutine that sends activation signal from initial node to terminal node.
# Subroutine finds
# Arguments:
#   -initial_node: ID of initial node (string)
#   -terminal_node: ID of terminal node (string)
#   -weight: Weight of link (real number)
sub send_activation {
    my %args = @_;

    my $initial_value = $Node{$args{-initial_node}}->{-value};

    my $link_input = $initial_value * 1 / outdegree($args{-initial_node}) ** $Beta;
    my $link_output = $link_input * $args{-weight};

    $Node{$args{-initial_node}}->{-sent_total} += $link_input;
    $Node{$args{-terminal_node}}->{-received_total} += $link_output;
}

# Resets sum of sent and received activation values for node with node ID passed as a parameter
sub reset_totals {
    my $node_id = shift;

    $Node{$node_id}->{-sent_total} = 0;
    $Node{$node_id}->{-received_total} = 0;
}

sub init_calibration {
    return if ($Calibration eq $Calibration_Types{none});

    if ($Calibration eq $Calibration_Types{initial}) {
        for my $node_id (keys %Initial_Activation) {
            push @Calibration_Nodes, $node_id
        }
    }

    if ($Calibration eq $Calibration_Types{total}) {
        for my $node_id (keys %Node) {
            push @Calibration_Nodes, $node_id;
        }
    }
}

sub calibrate {
    return if ($Calibration eq $Calibration_Types{none});

    my $iteration = shift;
    my $ratio = sum_activation_in_nodes($iteration - 1, @Calibration_Nodes) / sum_activation_in_nodes($iteration, @Calibration_Nodes);

    for my $node_id (keys %Node) {
        $Results[$iteration]->{$node_id} *= $ratio;
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
        $sum += $Results[$iteration]->{$node} if ($Results[$iteration]->{$node});
    }

    return $sum;
}

sub print_table {
    # Construct table header
    my @header = sort keys %Node;
    unshift @header, "Iter.";
    print join("\t", @header), "\n";
    shift @header;

    for (my $iteration = 0; $iteration <= $Iterations_Limit; $iteration++) {
        print "$iteration\t";
        for my $node_id (@header) {
            # Checking if printed value is initialized, so the interpreter won't complain that we're trying to access
            # uninitialized value
            if (exists $Results[$iteration]->{$node_id}) {
                printf "%.5f\t", $Results[$iteration]->{$node_id};
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

    for my $node_id (keys %Node) {
        $Results[$iteration]->{$node_id} = 0 if ($Results[$iteration]->{$node_id} < $Threshold);
    }
}

sub parse_parameters {
    my $keyword = shift;
    my @parameters = @_;

    if ($keyword eq $Keywords{-link_types}) {
        $Reciprocal_Link_For{$parameters[0]} = $parameters[1];
        return;
    }

    if ($keyword eq $Keywords{-node}) {
        $Node{$parameters[0]} = {
            -type           => $parameters[1],
            -value          => 0,
            -sent_total     => 0,
            -received_total => 0,
        };
        return;
    }

    if ($keyword eq $Keywords{-link}) {
        unless (exists $Node{$parameters[0]} and exists $Node{$parameters[1]}) {
            die "Trying to use invalid node in link\n\tEither " . $parameters[0] . " or " . $parameters[1] . " node does not exist.\n";
        }

        unless (exists $Reciprocal_Link_For{$parameters[2]}) {
            die "Trying to parse link with incorrect link type " . $parameters[2] . "\n"
        };

        push @Links, {
            -initial_node  => $parameters[0],
            -terminal_node => $parameters[1],
            -type          => $parameters[2],
        };

        return;
    }

    if ($keyword eq $Keywords{-initial_activation}) {
        unless (exists $Node{$parameters[0]}) {
            die "trying to initialize node " . $parameters[0] . " which doesn't exist.\n";
        }

        $Initial_Activation{$parameters[0]} = $parameters[1];
        $Node{$parameters[0]}->{-value} = $parameters[1];
        $Results[0]{$parameters[0]} = $parameters[1];

        return;
    }

    if ($keyword eq $Keywords{-link_weight}) {
        $Link_Weights{$parameters[0]} = $parameters[1];
        return;
    }

    if ($keyword eq $Keywords{-beta}) {
        $Beta = $parameters[0];
        return;
    }

    if ($keyword eq $Keywords{-iterations_limit}) {
        $Iterations_Limit = $parameters[0];
        return;
    }

    if ($keyword eq $Keywords{-calibration}) {
        unless ($parameters[0] eq $Calibration_Types{none} or $parameters[0] eq $Calibration_Types{total} or $parameters[0] eq $Calibration_Types{initial}) {
            my $accepted = join ", ", values %Calibration_Types;
            die "Incorrect value of Calibration\n\tReceived value: " . $parameters[0] . "\n\tAccepted values: $accepted \n";
        }

        $Calibration = $parameters[0];
        return;
    }

    if ($keyword eq $Keywords{-a}) {
        $Parameter{a} = $parameters[0];
        return;
    }

    if ($keyword eq $Keywords{-b}) {
        $Parameter{b} = $parameters[0];
        return;
    }

    if ($keyword eq $Keywords{-c}) {
        $Parameter{c} = $parameters[0];
        return;
    }

    if ($keyword eq $Keywords{-threshold}) {
        $Threshold = $parameters[0];
        return;
    }

    if ($keyword eq $Keywords{-node_types}) {
        return;
    }

    die "$keyword is not recognized configuration keyword\n";
}


# Main logic
############

open F, "params.txt" or die "Can't open params.txt file\n";

# Processing input file with parameters
for my $line (<F>) {
    # Skip comments or empty lines
    next if ($line =~ /^#/ or $line =~ /^\s/);

    chomp $line;
    my @conf = split /\s+/, $line;

    parse_parameters(@conf);
}

init_calibration();

for (my $iteration = 1; $iteration <= $Iterations_Limit; $iteration++) {
    # Send activation signals between nodes
    for my $link (@Links) {
        my $initial_node = $$link{-initial_node};
        my $terminal_node = $$link{-terminal_node};
        my $initial_value = $Node{$initial_node}->{-value};
        my $weight = $Link_Weights{$$link{-type}};

        send_activation(-initial_node => $initial_node, -terminal_node => $terminal_node, -weight => $weight);

        # Check if this link type is reciprocal
        next unless (exists $Reciprocal_Link_For{$$link{-type}});

        # Find link weight corresponding to reciprocal link
        $weight = $Link_Weights{$Reciprocal_Link_For{$$link{-type}}};
        ($initial_node, $terminal_node) = ($terminal_node, $initial_node);
        $initial_value = $Node{$initial_node}->{-value};

        send_activation(-initial_node => $initial_node, -terminal_node => $terminal_node, -weight => $weight);
    }

    # Calculate new values of nodes
    for my $node_id (sort keys %Node) {
        my $new_value = $Parameter{a} * $Node{$node_id}->{-value} + $Parameter{b} * $Node{$node_id}->{-received_total} + $Parameter{c} * $Node{$node_id}->{-sent_total};

        $Node{$node_id}->{-value} = $new_value;
        $Results[$iteration]{$node_id} = $new_value;

        reset_totals($node_id);
    }

    calibrate($iteration);
    check_threshold($iteration);
}

print_table();
use Data::Dumper;
print Dumper(\%Reciprocal_Link_For);