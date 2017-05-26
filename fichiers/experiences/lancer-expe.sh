#!/bin/bash
export OMP_NUM_THREADS

PATH_PROG="../prog"
PATH_RES="result/"

ITE=$(seq 10) # nombre de mesures
  
THREADS=$(seq 2 2 24) # nombre de threads

PARAM="-n -s 256" # parametres commun à toutes les executions 

I="10 100 1000"

execute (){
	EXE="./$PATH_PROG $* $PARAM"
	OUTPUT="$PATH_RES$(echo $EXE | tr -d ' ./')"
	for nb in $ITE; do \
		for OMP_NUM_THREADS in $THREADS; do \
			echo -n "$OMP_NUM_THREADS " >> $OUTPUT ; \
			$EXE 2>> $OUTPUT; \
		done;
	done
}

filename (){
	EXE="./$PATH_PROG $* $PARAM"
	OUTPUT="$PATH_RES$(echo $EXE | tr -d ' ./')"
	echo $OUTPUT
}

#execute -v 0
#execute -v 1
#execute -v 2
#execute -v 3


if [ ! -f "$PATH_RES" ]
then
    mkdir $PATH_RES
fi

rScriptArgs=( "" "" "" "" "" "" "" "" "" "" )


for i in $I; do \
	#sequencialBaseSpeed=$(getMedianSpeed -v 0 -i $i); \
	#sequencialTiledSpeed=$(getMedianSpeed -v 1 -i $i); \
	#sequencialOptimizedSpeed=$(getMedianSpeed -v 2 -i $i); \

	#echo "Séquentielle base $sequencialBaseSpeed ms"; \
	#echo "Séquentielle tuilée $sequencialTiledSpeed ms"; \
	#echo "Séquentielle optimisée $sequencialOptimizedSpeed ms"; \

	for v in $(seq 0 9); do \
		execute -i $i -v $v;
		rScriptArgs[$v]="${rScriptArgs[$v]} $(filename -v $v -i $i)"; 
	done
done


Rscript tracer-speedUp.R rScriptArgs[0] $sequencialOptimizedSpeed "sequential_optimized"


