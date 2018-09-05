#!/bin/bash

# specify rate
export DELTA_RATE=
export MAX_RATE=
export MIN_RATE=

#moongen deps                                                                   
apt-get install build-essential cmake linux-headers-`uname -r` pciutils libnuma1 libnuma-dev -y --allow-unauthenticated           

                                                                          
# install MoonGen                                                               
git clone https://github.com/emmericp/MoonGen.git                               
cd MoonGen                                                                      
git checkout 5388192fa1dc016797fabe8912bbcdfc7713756e
git submodule update --init                                                     
./build.sh                                                                      
./setup-hugetlbfs.sh                                                            

echo -e "n\nn\ny\ny\nyes\n" | aptitude install linux-perf                                                               

rmmod ixgbe                                                                     
modprobe ixgbe max_vfs=0


ip l set eth-test1 up                                                           
ip l set eth-test1 up                                                           
ip l set eth-test2 up                                                           
ip l set eth-test2 up 

/root/MoonGen/libmoon/deps/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 0000:05:00.0
/root/MoonGen/libmoon/deps/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 0000:05:00.1
                                         
cd libmoon                                                                      
./build.sh 

cd /root/MoonGen/libmoon                            
./build/libmoon ./examples/l2-forward.lua 0 1 &

testbed-sync READY_TO_TEST $EXPERIMENT_ID
echo "synced - ready to start" >> /root/log.txt

#initialize Rates
RATE=$MIN_RATE
RATES=$RATE
NUM_RUNS=0
while (( $(bc <<< "$RATE <= $MAX_RATE ") )) ; do
	RATE=$(($RATE + $DELTA_RATE))
	RATES="$RATES $RATE"
	NUM_RUNS=$(($NUM_RUNS + 1))
done

i=1
for RATE in $RATES ; do
	# sync between DuT and LG here
	sleep 60 
	i=$((i+1))
done

















