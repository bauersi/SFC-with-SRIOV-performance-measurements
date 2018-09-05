#!/bin/bash

# specify parameters... (interfaces, perf periodes, sizes, rates)
export IN=""
export OUT=""
export PERIODE_STAT=""
export SIZES=""
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
## build libmoon
cd libmoon
./build.sh 
cd..
echo -e "n\ny\ny\n" | aptitude install linux-perf 
cd
git clone https://github.com/opcm/pcm.git
cd pcm
make
echo 0 > /proc/sys/kernel/nmi_watchdog

rmmod ixgbe
modprobe ixgbe max_vfs=6

ip l set eth-test1 up
ip l set eth-test1 up
ip l set eth-test2 up
ip l set eth-test2 up 
ip link set eth-test1 vf 0 spoofchk off   
ip link set eth-test1 vf 1 spoofchk off                                         
ip link set eth-test1 vf 2 spoofchk off                                         
ip link set eth-test1 vf 3 spoofchk off                                         
ip link set eth-test1 vf 4 spoofchk off                                         
ip link set eth-test1 vf 5 spoofchk off                                         
ip link set eth-test1 vf 6 spoofchk off                                         
ip link set eth-test2 vf 0 spoofchk off  
ip link set eth-test1 vf 0 mac 00:22:33:44:55:00 >> /tmp/log.txt 
ip link set eth-test1 vf 1 mac 00:22:33:44:55:02 >> /tmp/log.txt                
ip link set eth-test1 vf 2 mac 00:22:33:44:55:04 >> /tmp/log.txt                
ip link set eth-test1 vf 3 mac 00:22:33:44:55:06 >> /tmp/log.txt                
ip link set eth-test1 vf 4 mac 00:22:33:44:55:08 >> /tmp/log.txt                
ip link set eth-test1 vf 5 mac 00:22:33:44:55:10 >> /tmp/log.txt                
ip link set eth-test1 vf 6 mac 00:22:33:44:55:12 >> /tmp/log.txt                
ip link set eth-test2 vf 0 mac 00:22:33:44:55:14 >> /tmp/log.txt 
/root/MoonGen/libmoon/deps/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 0000:05:10.0
/root/MoonGen/libmoon/deps/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 0000:05:10.2
/root/MoonGen/libmoon/deps/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 0000:05:10.4
/root/MoonGen/libmoon/deps/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 0000:05:10.6
/root/MoonGen/libmoon/deps/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 0000:05:11.0
/root/MoonGen/libmoon/deps/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 0000:05:11.2
/root/MoonGen/libmoon/deps/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 0000:05:11.4
/root/MoonGen/libmoon/deps/dpdk/usertools/dpdk-devbind.py --bind=igb_uio 0000:05:10.1

#start libmoon script 
cd /root/MoonGen/libmoon
testbed-run dummy ./build/libmoon ./examples/l2-forward_l4.lua 0 2 3 4 5 6 7 1 


#initialize Rates
RATE=$MIN_RATE
RATES=$RATE
NUM_RUNS=0
while (( $(bc <<< "$RATE <= $MAX_RATE ") )) ; do
	RATE=$(($RATE + $DELTA_RATE))
	RATES="$RATES $RATE"
	NUM_RUNS=$(($NUM_RUNS + 1))
done
cd /root/pcm

i=0
for SIZE in $SIZES ; do 
	for RATE in $RATES ; do
		echo "----------------------------------------------"
		echo "Test run $i started"
		# sync between DuT and LG here
		sleep 5
		testbed-run pcm${i} ./pcm-pcie.x -csv=pcm${i}.csv 
		sleep 30
		testbed-kill pcm${i}
		sleep 5
		mv pcm${i}.csv /tmp/
		i=$((i+1))
	done
done

