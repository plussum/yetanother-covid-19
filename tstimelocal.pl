#!/usr/bin/perl
#
#

use strict;
use warnings;

use Data::Dumper;
use Time::Local 'timelocal';

my $tm = &ymd2tm(2001, 4, 7, 0, 0, 0);
print &ut2d($tm, "/"), "\n";
print &ut2d(time, "/"), "\n";




#
#
#
sub ymd2tm
{
    my ($y, $m, $d, $h, $mn, $s) = @_;

	#$y -= 1900 if($y > 1900);
	my $tm = timelocal($s, $mn, $h, $d, $m - 1, $y);
	print "ymd2tm: " . join("/", $y, $m, $d, $h, $mn, $s);
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
 	print " --> " . join("/", $year + 1900, $mon+1, $mday) . "\n";
    return $tm;
}

sub ut2t
{
    my ($tm, $dlm) = @_;

    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
    my $s = sprintf("%02d%s%02d%s%02d", $hour, $dlm, $min, $dlm, $sec);
    return $s;
}

sub ut2d
{
    my ($tm, $dlm) = @_;

    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($tm);
    my $s = sprintf("%04d%s%02d%s%02d", $year + 1900, $dlm, $mon+1, $dlm, $mday);
    return $s;
}
