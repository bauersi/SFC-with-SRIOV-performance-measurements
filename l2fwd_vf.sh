#!/bin/bash

export DELTA_RATE=
export MAX_RATE=
export MIN_RATE=
                               
#moongen deps                                                                   
apt-get install build-essential cmake linux-headers-`uname -r` pciutils libnuma1 libnuma-dev -y --allow-unauthenticated           
                                                                                
#install MoonGen                                                               
git clone https://github.com/emmericp/MoonGen.git                               
cd MoonGen                                                                      
git submodule update --init                                                     
./build.sh                                                                      
./setup-hugetlbfs.sh                                                            
        
echo -e "n\ny\ny\n" | aptitude install linux-perf 

rmmod ixgbe
modprobe ixgbe max_vfs=1

ip l set eth-test1 up
ip l set eth-test1 up
ip l set eth-test2 up
ip l set eth-test2 up 
ip link set eth-test1 vf 0 spoofchk off                                         
ip link set eth-test2 vf 0 spoofchk off  
ip link set eth-test1 vf 0 mac 00:22:33:44:55:66 >> /tmp/log.txt                
ip link set eth-test2 vf 0 mac aa:bb:cc:dd:ee:01 >> /tmp/log.txt 
/root/MoonGen/libmoon/deps/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 0000:05:10.0
/root/MoonGen/libmoon/deps/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 0000:05:10.1

cd /root/MoonGen/libmoon                                                                      
./build.sh                                                                      
                                                                                
cd /root/MoonGen/libmoon                                                        
./build/libmoon ./examples/l2-forward.lua 0 1 &  

#initialize Rates
RATE=$MIN_RATE
RATES=$RATE
NUM_RUNS=0
while (( $(bc <<< "$RATE <= $MAX_RATE ") )) ; do
	RATE=$(($RATE + $DELTA_RATE))
	RATES="$RATES $RATE"
	NUM_RUNS=$(($NUM_RUNS + 1))
done
#
i=1
for RATE in $RATES ; do
	# sync between DuT and LG here 
	sleep 60
	i=$((i+1))
done
