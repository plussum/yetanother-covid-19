#
#	John Hopkings CCSEとWHOの共通グラフ生成パラメータ
#
#
#
package params;
use Exporter;
@ISA = (Exporter);
@EXOIORT = qw(params);

use strict;
use warnings;

my $EXCLUSION = "Others,China,US";
my $NONE_EXC = "Others";
my $EXC_POP = "San Marino,Holy See";
my $EXC_FT = "";

our @PARAMS_COUNT = (
    {ext => "#KIND# all with US(#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => "Others", target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# TOP5+Japan(#LD#) #SRC#", start_day => 0, lank =>[0, 4] , exclusion => "Others", target => "", label_skip => 3, graph => "lines", add_target => "Japan"},
	{ext => "#KIND# TOP5+Japan(wo US)(#LD#) #SRC#", start_day => 0, lank =>[0, 4] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", add_target => "Japan"},

    {ext => "#KIND# Japan (#LD#) #SRC#", start_day => 0,  lank =>[0, 4] , exclusion => "Others", target => "Japan", label_skip => 3, graph => "lines"},
    {ext => "#KIND# Japan 3weeks (#LD#) #SRC#", start_day => -21,  lank =>[0, 4] , exclusion => "Others", target => "Japan", label_skip => 1, graph => "lines"},
    {ext => "#KIND# Japan 0301 (#LD#) #SRC# rl-avr", start_day => "03/01",  lank =>[0, 4] , exclusion => "Others", target => "Japan", label_skip => 2, graph => "lines",
		avr_date => 7},

    {ext => "#KIND# TOP20-122 (#LD#) #SRC#", start_day => 0, lank =>[0, 19] , exclusion => $EXCLUSION, target => "", label_skip => 3, graph => "lines", term_ysize => 600},

    {ext => "#KIND# 01-05 from 0301 (#LD#) #SRC#",   start_day => "03/01", lank =>[0,  4] , exclusion => $NONE_EXC, target => "", label_skip => 3, graph => "lines"},
    {ext => "#KIND# 06-10 from 0301 (#LD#) #SRC#",   start_day => "03/01", lank =>[5,  9] , exclusion => $NONE_EXC, target => "", label_skip => 3, graph => "lines"},
    {ext => "#KIND# 11-20 from 0301 (#LD#) #SRC#",   start_day => "03/01", lank =>[10, 19] , exclusion => $NONE_EXC, target => "", label_skip => 3, graph => "lines"},
    {ext => "#KIND# 21-30 from 0301 (#LD#) #SRC#",   start_day => "03/01", lank =>[20, 29] , exclusion => $NONE_EXC, target => "", label_skip => 3, graph => "lines"},
    {ext => "#KIND# 31-40 from 0301 (#LD#) #SRC#",   start_day => "03/01", lank =>[30, 39] , exclusion => $NONE_EXC, target => "", label_skip => 3, graph => "lines"},
    {ext => "#KIND# 41-50 from 0301 (#LD#) #SRC#",   start_day => "03/01", lank =>[40, 49] , exclusion => $NONE_EXC, target => "", label_skip => 3, graph => "lines"},

    {ext => "#KIND# 3weeks 01-05 (#LD#) #SRC#", start_day => -21, lank =>[0, 4] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 06-10 (#LD#) #SRC#", start_day => -21, lank =>[5, 9] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 11-20 (#LD#) #SRC#", start_day => -21, lank =>[10,19] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 21-30 (#LD#) #SRC#", start_day => -21, lank =>[20,29] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 31-40 (#LD#) #SRC#", start_day => -21, lank =>[30,39] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"}, {ext => "#KIND# 3weeks 41-50 (#LD#) #SRC#", start_day => -21, lank =>[40,49] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 51-60 (#LD#) #SRC#", start_day => -21, lank =>[50,59] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 61-70 (#LD#) #SRC#", start_day => -21, lank =>[60,69] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},
    {ext => "#KIND# 3weeks 71-80 (#LD#) #SRC#", start_day => -21, lank =>[70,79] , exclusion => $NONE_EXC, target => "", label_skip => 1, graph => "lines"},

	{ext => "#KIND# all-211 ALL logscale (#LD#) #SRC#", start_day => 0, lank =>[0, 19] , exclusion => "Others", target => "", additional_target => "Japan",
		label_skip => 3, graph => "lines", logscale => "y", avr_date => 7, add_target => "Japan"},
	{ext => "#KIND# TOP10 -211 ALL logscale (#LD#) #SRC#", start_day => 0, lank =>[10, 19] , exclusion => "Others", target => "", additional_target => "Japan",
		label_skip => 3, graph => "lines", logscale => "y", avr_date => 5, add_target => "Japan"},
	{ext => "#KIND# TOP5 -211 ALL logscale (#LD#) #SRC#", start_day => 0, lank =>[0, 4] , exclusion => "Others", target => "", additional_target => "Japan",
		label_skip => 3, graph => "lines", logscale => "y", avr_date => 5, add_target => "Japan"},

#    {ext => "#KIND# Taiwan (#LD#) #SRC#", start_day => 0,  lank =>[0, 999] , exclusion => $EXCLUSION, target => "Taiwan", label_skip => 3, graph => "lines"},
#    {ext => "#KIND# China (#LD#) #SRC#", start_day => 0,  lank =>[0, 19] , exclusion => $EXCLUSION, target => "China", label_skip => 3, graph => "lines"},

    {ext => "#KIND# Gernam 0301 (#LD#) #SRC#", start_day => "03/01", lank =>[0, 9999] , exclusion => $NONE_EXC, 
		target => "German", label_skip => 2, graph => "lines"},
    {ext => "#KIND# UK 0301 (#LD#) #SRC#", start_day => "03/01", lank =>[0, 9999] , exclusion => $NONE_EXC, 
		target => "UK,United Kingdom", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Sweden  (#LD#) #SRC#", start_day => 0,  lank =>[0, 999] , exclusion => $EXCLUSION, 
		target => "Sweden", label_skip => 3, graph => "lines"},
    {ext => "#KIND# Sweden and other (#LD#) #SRC#", start_day => "03/01",  lank =>[0, 999] , exclusion => $EXCLUSION, term_ysize => 600,
		target => "Sweden,US,United Kingdom,UK,Italy,France,Spain,Belgium,Germany,Netherlands,Switzerland", label_skip => 3, graph => "lines"},

    {ext => "#KIND# Finland 0301 (#LD#) #SRC#", start_day => "03/01", lank =>[0, 9999] , exclusion => $NONE_EXC, 
		target => "Finland", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Slovakia 0301 (#LD#) #SRC#", start_day => "03/01", lank =>[0, 9999] , exclusion => $NONE_EXC, 
		target => "Slovakia", label_skip => 2, graph => "lines"},
    {ext => "#KIND# ASIA 0301 (#LD#) #SRC#", start_day => "03/01", lank =>[0, 9999] , exclusion => $NONE_EXC, 
		target => "Japan,Taiwan,Malaysia,Philip,India,Korea,Singapore,Indonesia ", label_skip => 2, graph => "lines"},

    {ext => "#KIND# Japan, Korea, China 0301 (#LD#) #SRC#", start_day => "03/01", lank =>[0, 9999] , exclusion => $NONE_EXC, 
		target => "Japan,Korea,China", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan, Korea, China 3weeks (#LD#) #SRC#", start_day => -21, lank =>[0, 9999] , exclusion => $NONE_EXC, 
		target => "Japan,Korea,China", label_skip => 2, graph => "lines"},

    {ext => "#KIND# Focusing cuntry 0301 (#LD#) #SRC#", start_day => "03/01", lank =>[0, 9999] , exclusion => $NONE_EXC, 
		target => "India,Peru,Chile,Mexico,Pakistan,Qatar,Bangladesh,South Africa", label_skip => 2, graph => "lines"},

    {ext => "#KIND# Japan 0301 (#LD#) #SRC#", start_day => "03/01", lank =>[0, 9999] , exclusion => $NONE_EXC, target => "Japan", label_skip => 2, graph => "lines"},
);

our	@PARMS_FT = (
	{ext => "#KIND# Japan and others #FT_TD#", start_day => 0, lank =>[0, 999] , exclusion => $EXC_FT, add_target => "",
		target => "Japan,Korea,US,Spain,Italy,France,Germany,United Kingdom,Iran,Turkey,Belgium,Switzeland,Russia,Brazil",
		label_skip => 2, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
	{ext => "#KIND# Japan and TOP10 #FT_TD#", start_day => 0, lank =>[0, 9] , exclusion => $EXC_FT, add_target => "",
		target => "", add_target => "Japan", label_skip => 2, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},

	{ext => "#KIND# TOP5 #FT_TD#", start_day => 0, lank =>[0, 5] , exclusion => $EXC_FT, target => "", 
		label_skip => 2, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
	{ext => "#KIND# TOP10 #FT_TD#", start_day => 0, lank =>[0, 10] , exclusion => $EXC_FT, target => "", 
		label_skip => 7, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
	{ext => "#KIND# 10-20 #FT_TD#", start_day => 0, lank =>[10, 19] , exclusion => $EXC_FT, target => "",
		label_skip => 7, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
	{ext => "#KIND# Japn Koria #FT_TD#", start_day => 0, lank =>[0, 99] , exclusion => $EXC_FT, target => "Japan,Korea",
			label_skip => 2, graph => "lines", series => 1, logscale => "y", term_ysize => 600, ft => 1},
);

our	@PARMS_RT = (
	{ext => "#KIND# Japan 01/23 #RT_TD#", start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan", 
		label_skip => 2, graph => "lines"},
	{ext => "#KIND# Japan 03/01 #RT_TD#", start_day => "03/01", lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan", 
		label_skip => 2, graph => "lines"},
	{ext => "#KIND# Japan 3weeks #RT_TD#",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan",
		 label_skip => 1, graph => "lines",  ymin => 0},
	{ext => "#KIND# Germany 0301 #RT_TD#",   start_day => 0, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Germany",
		 label_skip => 2, graph => "lines", },
	{ext => "#KIND# Germany 3weeks #RT_TD#",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Germany",
		 label_skip => 1, graph => "lines", },
	{ext => "#KIND# Forcus area 01 3weeks #RT_TD#",   start_day => -21, lank =>[0, 99] , exclusion => $EXCLUSION, target => "Germany,US,Italy,Spain,France",
		 label_skip => 1, graph => "lines", },
	{ext => "#KIND# Focusing area from 0301 #RT_TD#",   start_day => 39, lank =>[0, 99] , exclusion => $EXCLUSION, 
		target => "Russia,Canada,Ecuador,Brazil,India", label_skip => 3, graph => "lines", ymax => 10, },
	{ext => "#KIND# TOP 01-05 from 0301 #RT_TD#",   start_day => 39, lank =>[0, 4] , exclusion => $EXCLUSION, target => "", 
		label_skip => 3, graph => "lines", ymax => 10, },
	{ext => "#KIND# TOP 06-10 from 0301 #RT_TD#",   start_day => 39, lank =>[5, 9] , exclusion => $EXCLUSION, target => "", 
		label_skip => 3, graph => "lines", ymax => 10, },
	{ext => "#KIND# TOP 10 3w #RT_TD#",   start_day => -21, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", 
		label_skip => 1, graph => "lines", ymax => "", },
	{ext => "#KIND# TOP 10 2w #RT_TD#",   start_day => -14, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", 
		label_skip => 1, graph => "lines", ymax => "", },
	{ext => "#KIND# TOP 10 1w #RT_TD#",   start_day => -7, lank =>[0, 9] , exclusion => $EXCLUSION, target => "", 
		label_skip => 1, graph => "lines", ymax => "", },

	{ext => "#KIND# Japan  #RT_TD#",   start_day => "03/01", lank =>[0, 99] , exclusion => $EXCLUSION, target => "Japan", 
		label_skip => 2, graph => "lines", },
);

our	@PARAMS_POP = (
	{ext => "#KIND# 01-05 -218 ($EXC_POP) (#LD#)", start_day => 27, lank =>[0, 4] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# 06-10 -218 ($EXC_POP) (#LD#)", start_day => 27, lank =>[5, 9] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# 11-15 -218 ($EXC_POP) (#LD#)", start_day => 27, lank =>[10, 14] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# 16-20 -218 ($EXC_POP) (#LD#)", start_day => 27, lank =>[15, 19] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# 01-05 from 0301 ($EXC_POP) (#LD#)", start_day => 38, lank =>[0,  4] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# 06-10 from 0301 ($EXC_POP) (#LD#)", start_day => 38, lank =>[5,  9] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# 10-15 from 0301 ($EXC_POP) (#LD#)", start_day => 38, lank =>[10, 14] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# 16-20 from 0301 ($EXC_POP) (#LD#)", start_day => 38, lank =>[15, 19] , exclusion => $EXC_POP, target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# 3weeks 01-05 ($EXC_POP) (#LD#)", start_day => -21, lank =>[0, 4] , exclusion => $EXC_POP, target => "", graph => "lines"},
	{ext => "#KIND# 3weeks 06-10 ($EXC_POP) (#LD#)", start_day => -21, lank =>[5, 9] , exclusion => $EXC_POP, target => "", graph => "lines"},
	{ext => "#KIND# 3weeks 11-15 ($EXC_POP) (#LD#)", start_day => -21, lank =>[10,14] , exclusion => $EXC_POP, target => "", graph => "lines"},
	{ext => "#KIND# 3weeks 16-20 ($EXC_POP) (#LD#)", start_day => -21, lank =>[15,19] , exclusion => $EXC_POP, target => "", graph => "lines"},

	{ext => "#KIND# TOP20-218 (#LD#)", start_day => 27, lank =>[0, 19] , exclusion => "", target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# 01-10 from 0301 (#LD#)",   start_day => 38, lank =>[0,  9] , exclusion => "", target => "", label_skip => 3, graph => "lines"},
	{ext => "#KIND# 3weeks 01-05 (#LD#)", start_day => -21, lank =>[0, 4] , exclusion => "", target => "", graph => "lines"},

	{ext => "#KIND# Japan-122 (#LD#)", start_day => 0, lank =>[0, 9999] , exclusion => $EXC_POP, target => "Japan", label_skip => 3, graph => "bars"},
#	{ext => "#KIND# Japan 2weeks $TD", start_day => -21, lank =>[0, 9999] , exclusion => $EXC_POP, target => "Japan", label_skip => 1, graph => "bars"},
	{ext => "#KIND# US (#LD#)", start_day => 39,  lank =>[0, 100] , exclusion => "Others", target => "US", label_skip => 2, graph => "lines"},
	{ext => "#KIND# China (#LD#)", start_day => 0,  lank =>[0, 100] , exclusion => "Others", target => "China", label_skip => 2, graph => "lines"},
	{ext => "#KIND# China (#LD#) 05/01", start_day => "05/01",  lank =>[0, 100] , exclusion => "Others", target => "China", label_skip => 2, graph => "lines"},
);

our @ACCD_PARAMS = (
	{ext => "#KIND# CCM TOP5+Japan(#LD#) #SRC#", start_day => 0, lank =>[0, 4] , exclusion => "Others", target => "", 
		label_skip => 3, graph => "lines", add_target => "Japan"},
	{ext => "#KIND# CCM TOP5+Japan(#LD#) #SRC# logscale", start_day => 0, lank =>[0, 4] , exclusion => "Others", target => "", 
		label_skip => 3, graph => "lines", add_target => "Japan", logscale => "y"},

	{ext => "#KIND# CCM Japan(#LD#) #SRC#", start_day => 0, lank =>[0, 4] , exclusion => "Others", target => "Japan", 
		label_skip => 3, graph => "lines"}, 
	{ext => "#KIND# CCM Japan(#LD#) #SRC# logscale", start_day => 0, lank =>[0, 4] , exclusion => "Others", target => "Japan", 
		label_skip => 3, graph => "lines", logscale => "y"}, 
);

my $EXEC_KV = "";
our @PARAMS_KV = (
	{ext => "#KIND# KV Japan/US(#LD#) #SRC#", start_day => 0,  lank =>[0, 999], exclusion => $EXEC_KV, 
		target => "US,Japan,Korea", label_skip => 3, graph => "lines"},
	{ext => "#KIND# KV Japan/US KV (#LD#) 04/01 #SRC#", start_day => "04/01",  lank =>[0, 999], exclusion => $EXEC_KV, 
		target => "US,Japan,Korea", label_skip => 2, graph => "lines"},
	{ext => "#KIND# KV JAPAN/US (#LD#) 3w #SRC# ", start_day => -21,  lank =>[0, 999], exclusion => $EXEC_KV, 
		target => "US,Japan,Korea", label_skip => 1, graph => "lines"},
	{ext => "#KIND# KV ALL (#LD#) 04/01 #SRC#", start_day => "04/01",  lank =>[0, 9], exclusion => $EXEC_KV, 
		target => "", label_skip => 2, graph => "lines"},
	{ext => "#KIND# KV 3w (#LD#) 04/01 #SRC#", start_day => -21,  lank =>[0, 9], exclusion => $EXEC_KV, 
		target => "", label_skip => 2, graph => "lines"},
    {ext => "#KIND# Japan and focse reasion 3/1(#LD#) #SRC#", start_day => "03/01",  lank =>[0, 999] , exclusion => $EXCLUSION, term_ysize => 300,
		target => "Japan,Sweden,US,United Kingdom,UK,Italy,France,Spain,Belgium,Germany,Netherlands,Switzerland", label_skip => 3, graph => "lines"},
    {ext => "#KIND# Japan and focse reasion 4/1 (#LD#) #SRC#", start_day => "04/01",  lank =>[0, 999] , exclusion => $EXCLUSION, term_ysize => 300,
		target => "Japan,Sweden,US,United Kingdom,UK,Italy,France,Spain,Belgium,Germany,Netherlands,Switzerland", label_skip => 3, graph => "lines"},
    {ext => "#KIND# Japan and focse reasion 3w(#LD#) #SRC#", start_day => -21,  lank =>[0, 999] , exclusion => $EXCLUSION, term_ysize => 300,
		target => "Japan,Sweden,US,United Kingdom,UK,Italy,France,Spain,Belgium,Germany,Netherlands,Switzerland", label_skip => 3, graph => "lines"},
);

1;
