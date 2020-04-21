#!/usr/bin/perl
#
#

my @v = ();
my $max = 1120;
my $digit = int(log($max)/log(10));

$v[0] = ($max / 10**$digit);
$v[1] = (int($v[0]*10+0.99999)/10);
$v[2] = $v[1] * 10**$digit;

$v[3] = (int(($max / 10**$digit)*10 + 0.9999)/10) * 10**$digit;

print join(", ", $max, $digit, @v ) , "\n";
