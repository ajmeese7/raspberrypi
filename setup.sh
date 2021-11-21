#!/bin/bash

##################################
# THIS FILE MUST BE RAN AS ROOT! #
##################################

# remove wolfram and libre suite to free up space
sh ./remove-bloat.sh

# various helpful snippets
sh ./helpful.sh

# secure nginx setup
sh ./nginx.sh
