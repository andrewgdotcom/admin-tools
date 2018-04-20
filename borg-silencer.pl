#!/usr/bin/perl

# A stream editor to remove spurious warnings from borg output

use strict;
use warnings;

my @transcript=(
"Remote: Borg 0.29.0: exception in RPC call:",
"Remote: Traceback ",
"Remote:   File ",
"Remote: TypeError: ",
"Remote: Platform: ",
"Remote: Python: CPython ",
"Remote: ",
"Please note:",
"If you see a TypeError complaining about the number of positional arguments",
"given to open",
"This TypeError is a cosmetic side effect of the compatibility code borg",
"clients >= 1.0.7 have to support older borg servers.",
"This problem will go away as soon as the server has been upgraded to 1.0.7+.",
);

my $index=0;
while(<>) {
  chop;
  while($index<13 && m/^${transcript[$index]}/) {
    $_=<>;
    $index++;
  }
  $index=0;
  print "$_\n";

}
