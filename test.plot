set datafile separator '	'
set xtics rotate by -90
set xdata time
set timefmt '%m/%d'
set format x '%m/%d'

set mxtics 2
set mytics 2
set grid xtics ytics mxtics mytics
set key below
# second ax
#
set title '#02 tko_ NEW CASES-COUNT-DAY Japan TOP20 (12/19)  rl-avr 7  src:TOYO KEIZAI ONLINE' font "IPAexゴシック,12" enhanced
set xlabel ''
set ylabel ''
#
set xtics 604800
#set xrange ['03/12':'12/19']
set xrange ['03/12':'12/19']
set yrange [0:]
set y2range [0:]
set terminal pngcairo size 1000, 300 font "IPAexゴシック,8" enhanced
#LOGSCALE#
#LOGSCALE2#
#FILLSTYLE#
set y2tics
set output '/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7.png'
#set arrow from '12/12',0 to '12/12',600 nohead lw 1 dt (3,7) lc rgb "red"
plot '/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:2 with lines title '01:東京都' linewidth 2 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:3 with lines title '02:大阪府' linewidth 2 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:4 with lines title '03:北海道' linewidth 2 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:5 with lines title '04:神奈川県' linewidth 2 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:6 with lines title '05:愛知県' linewidth 2 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:7 with lines title '06:埼玉県' linewidth 2 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:8 with lines title '07:兵庫県' linewidth 2 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:9 with lines title '08:千葉県' linewidth 1 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:10 with lines title '09:沖縄県' linewidth 1 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:11 with lines title '10:福岡県' linewidth 1 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:12 with lines title '11:静岡県' linewidth 1 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:13 with lines title '12:京都府' linewidth 1 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:14 with lines title '13:広島県' linewidth 1 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:15 with lines title '14:茨城県' linewidth 1 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:16 with lines title '15:宮城県' linewidth 1 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:17 with lines title '16:群馬県' linewidth 1 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:18 with lines title '17:岐阜県' linewidth 1 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:19 with lines title '18:奈良県' linewidth 1 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:20 with lines title '19:長野県' linewidth 1 ,'/mnt/c/cov/plussum.github.io/PNG/02_tko_NEW_CASES_COUNT_DAY_Japan_TOP20_rl_avr_7-plot.csv.txt' using 1:21 with lines title '20:熊本県' linewidth 1 

show variables GPVAL_Y_MIN
show variables GPVAL_Y_MAX

#set arrow from '12/12',GPVAL_Y_MIN to '12/12',GPVAL_Y_MAX nohead lw 1 dt (3,7) lc rgb "red"
set arrow from '12/12',0 to '12/12',600 nohead lw 1 dt (3,7) lc rgb "red"

replot
exit;
