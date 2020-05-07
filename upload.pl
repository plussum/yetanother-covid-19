#!/usr/bin/perl
#
#
#
#
use strict;
use warnings;

use config;

chdir $config::WIN_PATH;

&do("git add .");
&do("git commit -m 'update'");
&do("git push origin master");

sub	do
{
	my ($cmd) = @_;

	print $cmd . "\n";
	system($cmd);
}
