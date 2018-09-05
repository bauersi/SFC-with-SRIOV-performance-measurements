#!/bin/bash

# specify parameters... (interfaces, perf periodes, sizes, rates)
export IN=""
export OUT=""
export SIZES=""
export DELTA_RATE=
export MAX_RATE=
export MIN_RATE=

#moongen deps
apt-get install build-essential cmake linux-headers-`uname -r` pciutils libnuma1 libnuma-dev -y --allow-unauthenticated           


## install MoonGen
git clone https://github.com/emmericp/MoonGen.git
cd MoonGen
git checkout 5388192fa1dc016797fabe8912bbcdfc7713756e
git submodule update --init
./build.sh
./setup-hugetlbfs.sh
echo "MoonGen installed" >> /tmp/log.txt

# insert MAC address of first interface on DuT and modify the MoonGen script
sed -i '13s/.*/local DST_MAC = ""/' /root/MoonGen/examples/l3-load-latency.lua

RATE=$MIN_RATE
RATES=$RATE
NUM_RUNS=0
while (( $(bc <<< "$RATE <= $MAX_RATE ") )) ; do
	RATE=$(($RATE + $DELTA_RATE))
	RATES="$RATES $RATE"
	NUM_RUNS=$(($NUM_RUNS + 1))
done

i=0
for SIZE in $SIZES ; do 
     for RATE in $RATES ; do
          echo "----------------------------------------------"
          echo "$(date) Test run $i started"
          #implement sync between DuT and LG here 
	  testbed-sync TEST_RUN_START$i $EXPERIMENT_ID
          testbed-run send$i ./build/MoonGen examples/l3-load-latency.lua 0 1 -r $RATE -s $SIZE
          echo "$(date) MoonGen started: Rate=$RATE, MinRate=$MIN_RATE, MaxRate=$MAX_RATE, Delta=$DELTA_RATE"
          sleep 45
          testbed-kill send$i
          mv /root/MoonGen/histogram.csv /tmp/hist${i}.csv
          echo "$(date) Test run $i ended"
          i=$((i+1))
          sleep 5
     done
done





