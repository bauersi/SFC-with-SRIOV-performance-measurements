#!/bin/bash

# content
# tbd

# parameters 
export IN=""
export OUT=""
export PERIODE_STAT=""
export SIZES=""
export DELTA_RATE=
export MAX_RATE=
export MIN_RATE=

#prepare DuT
apt-get -y update --allow-unauthenticated
echo -e "y\n" | aptitude install build-essential
apt-get install cmake -y --allow-unauthenticated
apt-get install linux-headers-$(uname -r) -y --allow-unauthenticated
apt-get install openvswitch-switch -y --allow-unauthenticated
apt-get install openvswitch-switch -y --allow-unauthenticated
apt-get -y install cpufrequtils
echo -e "n\nn\ny\ny\nyes\n" | aptitude install linux-perf

# prepare IFs
ip l set $IN up
ip l set $OUT up

# assign interrupts to cores
IRQIDS=""

for i in $IRQIDS ; do
	echo "0001" > /proc/irq/${i}/smp_affinity
done	

#prepare OvS
ovs-vsctl add-br br0
ovs-ofctl mod-port br0 br0 noflood
ovs-vsctl add-port br0 $IN
ovs-vsctl add-port br0 $OUT
ovs-ofctl del-flows br0
ovs-ofctl add-flow br0 in_port=1,actions=output:2

#initialize Rates                                                               
RATE=$MIN_RATE                                                                  
RATES=$RATE                                                                     
while (( $(bc <<< "$RATE <= $MAX_RATE ") )) ; do                                
	RATE=$(($RATE + $DELTA_RATE))                                           
	RATES="$RATES $RATE"                                                    
done      

i=0

for SIZE in $SIZES ; do 
	for RATE in $RATES ; do 
		# sync between DuT and LG here
		perf stat -C 0 -a -g -e cpu-cycles,instructions,L1-dcache-load-misses,L1-dcache-loads,LLC-load-misses,LLC-loads -o /tmp/perfstat${i}.csv -x, sleep $PERIODE_STAT
		testbed-upload /tmp/perfstat${i}.csv
		i=$((i+1))
	done
done




