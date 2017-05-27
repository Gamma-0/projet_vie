#!/bin/bash
export OMP_NUM_THREADS

PATH_PROG="prog"
PATH_EXP="experiences/"
PATH_RES="${PATH_EXP}result/"
PATH_R="${PATH_EXP}R/"

ITEMAX=10
ITE=$(seq $ITEMAX) # nombre de mesures
  
THREADS=$(seq 2 2 24) # nombre de threads

S=1024 #256 1024 4096
PARAM="-n -s $S -ft" # parametres commun à toutes les executions 

I="1000" # nombre d'itération
T="16 32" # nombre de tuiles


execute (){
	EXE="./$PATH_PROG $* $PARAM"
	OUTPUT="$PATH_RES$(echo $EXE | tr -d ' ./')"
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
	sequentialBaseSpeed=$(getMedianSpeed -v 0 -i $i);
	sequentialTiledSpeed=$(getMedianSpeed -v 1 -i $i);
	sequentialOptimizedSpeed=$(getMedianSpeed -v 2 -i $i);

	echo "Séquentielle base $sequentialBaseSpeed ms";
	echo "Séquentielle tuilée $sequentialTiledSpeed ms";
	echo "Séquentielle optimisée $sequentialOptimizedSpeed ms";

	for v in $(seq 0 2); do
		rScriptArgs[$v]="$(filename -v $v -i $i)";
	done;
	
	for v in $(seq 3 7); do
		execute -v $v -i $i;
		rScriptArgs[$v]="$(filename -v $v -i $i)";
	done;
		
	Rscript ${PATH_EXP}tracer-speedUp.R ${rScriptArgs[0]} ${rScriptArgs[3]} $sequentialBaseSpeed "sequential_base_i${i}_s${S}_ft"
	Rscript ${PATH_EXP}tracer-speedUp.R ${rScriptArgs[1]} ${rScriptArgs[4]} ${rScriptArgs[6]} $sequentialTiledSpeed "sequential_tiled_i${i}_s${S}_ft"
	Rscript ${PATH_EXP}tracer-speedUp.R ${rScriptArgs[2]} ${rScriptArgs[5]} ${rScriptArgs[7]} $sequentialOptimizedSpeed "sequential_optimized_i${i}_s${S}_ft"
	
done

mv speedup_* ${PATH_R}




