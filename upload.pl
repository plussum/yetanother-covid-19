#!/usr/bin/perl
#
#
#
#
use strict;
use warnings;

use config;

# system("./upload $config::WIN_PATH master");
#system("./upload $config::WIN_PATH develop");

system("./upload $config::CODE_PATH develop");

system("./uploadweb");

