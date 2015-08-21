#!/usr/bin/perl

use strict;

print `bug_fixing/find_failed_token.pl`;

print `bug_fixing/revise_hash_maps.pl`;

print `bug_fixing/preprocess_hash_map.pl`;

print `bug_fixing/re-group.pl`;
