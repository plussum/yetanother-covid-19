#!/usr/bin/perl
#	COVID-19 のデータをダウンロードして、CSVとグラフを生成する
#
#	beoutbreakprepared
#	https://github.com/beoutbreakprepared/nCoV2019
#
#
use strict;
use warnings;
use config;

my $DEBUG = 0;
my $download = 0;
my $gen = 1;

for(my $i = 0; $i <= $#ARGV; $i++){
	$_ = $ARGV[$i];
	$DEBUG = 1 if(/^-debug/);
	$download = 1 if(/-DL/i);
	$gen = "" if(/-NG/i);
	
}

if($gen){
	system("(cd ../COVID-19; git pull origin master)") if($download);
	system("./ccse.pl -all");

	my $gwflag = ($download) ? "-dl" : "";
	system("./getwho.pl $gwflag");

	system("./japan.pl $gwflag");
	system("./jprate.pl $gwflag");
	system("./jpft.pl $gwflag");
	system("./jpcomp.pl $gwflag");
	system("cp COV/jpcomp.html .");
}


my $WIN_PATH = "/mnt/f/OneDrive/cov";
my $INDEX_HTML = "$WIN_PATH/covid_index.html";
my $FRAME_HTML = "$WIN_PATH/covid_frame.html";
my $DIR = "/mnt/f/OneDrive/cov";
my @src_list = qw (jhccse who japan);
my @mode_list = qw (NC ND);
my @submode_list = qw (COUNT FT RT);
my @aggr_list = qw (DAY POP);

my $INDEX = << "_EOI_";
<html>
<head>
<title>INDEX COVID-19 </title>
</head>

<frameset cols="300,*">
    <frame src="covid_frame.html" name="index">
    <frame src="covid_frame.html" name="graph">
    </frameset>
</frameset>
</html> 
_EOI_

my $CSS = $config::CSS;

my $TBL_SIZE = 10;
my $class = "class=\"c\"";

open(INDEX, ">$INDEX_HTML") || die "cannot create file $INDEX_HTML";
print INDEX $INDEX;
close(INDEX);

open(FRAME, "> $FRAME_HTML") || die "Cannot create file $FRAME_HTML";
print FRAME "<HTML>\n";
print FRAME "<HEAD>\n";
print FRAME "<TITLE> COVID-19 INDEX </TITLE>\n";
print FRAME $CSS;
print FRAME "</HEAD>\n";
print FRAME "<BODY>\n";

print FRAME "<span class=\"c\"> ";
print FRAME "<H1>INDEX COVID-19</H1>\n";
print FRAME "<ul type=\"disc\">\n";
foreach my $src (@src_list){
	foreach my $sub (@submode_list){
		foreach my $aggr (@aggr_list){
			foreach my $mode (@mode_list){
				next if($aggr eq "POP" && ($sub ne "COUNT" || $src ne "jhccse"));
				my $relp = join("_", $src, $mode, $sub, $aggr) . ".html";

				print FRAME "<li><a href =\"HTML/$relp\" target=\"graph\">$relp</a></li>\n";
			}
		}
	}
	print FRAME "<br>\n";
}
print FRAME "</ul>\n";
print FRAME "</span>\n";
print FRAME "</BODY>\n";
print FRAME "</HTML>\n";
close(FRAME);

