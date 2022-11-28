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

