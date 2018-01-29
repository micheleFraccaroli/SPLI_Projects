#!/bin/bash
gnuplot -persist <<EOF
set terminal png size 900,680 enhanced font 'Verdana,10'
set output 'out_HTB.png'
set style data lp
set xlabel "time (seconds)"
set ylabel "Rate (KB/s)"
set yrange [0:120000]
plot '$1' using 1:3 title "A:1",'$1' using 1:7 title "A:2",'$1' using 1:11 title "B",  '$1' using 1:(\$3+\$7) title "total A", '$1' using 1:(\$3+\$7+\$11) title "total"

EOF