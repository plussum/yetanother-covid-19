#!/usr/bin/perl
#
#
#
#
use strict;
use warnings;

use config;

my $CODE = 0;
my $WEB = 0;
for(@ARGV){
	$CODE = 1 if(/-code/);
	$WEB = 1 if(/-web/);
}
if($CODE == 0 && $WEB == 0){
	$CODE = 1;
	$WEB = 1;
}

# system("./upload $config::WIN_PATH master");
#system("./upload $config::WIN_PATH develop");

system("./upload $config::CODE_PATH develop");

system("./uploadweb");

