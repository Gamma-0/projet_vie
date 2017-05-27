#!/bin/bash
export OMP_NUM_THREADS

PATH_PROG="prog"
PATH_EXP="experiences/"
PATH_RES="${PATH_EXP}result/"
PATH_R="${PATH_EXP}R/"

ITEMAX=10
ITE=$(seq $ITEMAX) # nombre de mesures
  
THREADS=$(seq 2 2 24) # nombre de threads

S=256 #256 1024 4096
PARAM="-n -s $S" # parametres commun à toutes les executions 

I="100 1000" # nombre d'itération
T="16 32" # nombre de tuiles


execute (){
	EXE="./$PATH_PROG $* $PARAM"
	OUTPUT="$PATH_RES$(echo $EXE | tr -d ' ./')_dyna"
	for nb in $ITE; do
		for OMP_NUM_THREADS in $THREADS; do
			echo -n "$OMP_NUM_THREADS " >> $OUTPUT ;
			$EXE 2>> $OUTPUT;
		done;
	done
}


filename (){
	EXE="./$PATH_PROG $* $PARAM"
	OUTPUT="$PATH_RES$(echo $EXE | tr -d ' ./')"
	echo $OUTPUT
}

getMedianSpeed (){
	EXE="./$PATH_PROG $* $PARAM"
	OUTPUT="$PATH_RES$(echo $EXE | tr -d ' ./')"
	sum=0
	for nb in $ITE; do \
		tmp=$( { $EXE; } 2>&1 > /dev/null );
		sum=$( awk "BEGIN{print $tmp + $sum}" );
	done
	awk "BEGIN {print $sum / $ITEMAX}"
}

if [ ! -d "$PATH_RES" ]
then
    mkdir $PATH_RES
fi
if [ ! -d "$PATH_R" ]
then
    mkdir $PATH_R
fi

rScriptArgs=( "" "" "" "" "" "" "" "" "" "" )

#0 sequential base
#1 sequential tiled
#2 sequential optimized
#3 OpenMP for base
#4 OpenMP for tiled
#5 OpenMP for optimized
#6 OpenMP task tiled
#7 OpenMP task optimized
#8 OpenCl base
#9 OpenCl optimized
#10 OpenCl + OpenMP

for i in $I; do
	sequentialTiledSpeed=$(getMedianSpeed -v 1 -i $i);

	rScriptArgs[1]="$(filename -v 1 -i $i)";
	
	for v in $(seq 4 4); do
		execute -v $v -i $i;
		rScriptArgs[$v]="$(filename -v $v -i $i)_dyna $(filename -v $v -i $i)";
	done;

	Rscript ${PATH_EXP}tracer-speedUp.R ${rScriptArgs[1]} ${rScriptArgs[4]}  $sequentialTiledSpeed "sequential_tiled_i${i}_s${S}_static_dynamic"
done

mv speedup_* ${PATH_R}




