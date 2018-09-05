#!/bin/bash

# specify parameters... (interfaces, perf periodes, sizes, rates) 
export IN=""
export OUT=""
export PERIODE_STAT=""
export PERIODE_RECORD=""
export SIZES=""
export DELTA_RATE=
export MAX_RATE=
export MIN_RATE=
export INTERFACES=""

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


# prepare DuT with OvS VF chain
echo 9 > /sys/class/net/eth-test1/device/sriov_numvfs
echo 1 > /sys/class/net/eth-test2/device/sriov_numvfs

ip link set eth-test1 vf 0 mac 10:22:33:44:55:00
ip link set eth-test1 vf 1 mac 10:22:33:44:55:02
ip link set eth-test1 vf 2 mac 10:22:33:44:55:04
ip link set eth-test1 vf 3 mac 10:22:33:44:55:06
ip link set eth-test1 vf 4 mac 10:22:33:44:55:08
ip link set eth-test1 vf 5 mac 10:22:33:44:55:10                                
ip link set eth-test1 vf 6 mac 10:22:33:44:55:12
ip link set eth-test1 vf 7 mac 10:22:33:44:55:14                                
ip link set eth-test1 vf 8 mac 10:22:33:44:55:16 
ip link set eth-test2 vf 0 mac 10:22:33:44:55:18

ip link set eth-test1 vf 0 spoofchk off
ip link set eth-test1 vf 1 spoofchk off
ip link set eth-test1 vf 2 spoofchk off
ip link set eth-test1 vf 3 spoofchk off
ip link set eth-test1 vf 4 spoofchk off
ip link set eth-test1 vf 5 spoofchk off                                         
ip link set eth-test1 vf 6 spoofchk off 
ip link set eth-test1 vf 7 spoofchk off                                         
ip link set eth-test1 vf 8 spoofchk off
ip link set eth-test2 vf 0 spoofchk off

ip link set enp5s16 up
ip link set enp5s16f2 up
ip link set enp5s16f4 up
ip link set enp5s16f6 up
ip link set enp5s17 up
ip link set enp5s17f2 up
ip link set enp5s17f4 up
ip link set enp5s17f6 up                                                        
ip link set enp5s18 up 
ip link set enp5s16f1 up

ovs-vsctl add-br br0
ovs-vsctl add-br br1
ovs-vsctl add-br br2
ovs-vsctl add-br br3
ovs-vsctl add-br br4

ovs-ofctl mod-port br0 br0 noflood
ovs-ofctl mod-port br1 br1 noflood
ovs-ofctl mod-port br2 br2 noflood
ovs-ofctl mod-port br3 br3 noflood
ovs-ofctl mod-port br4 br4 noflood 

ovs-vsctl add-port br0 enp5s16
ovs-vsctl add-port br0 enp5s16f2
ovs-vsctl add-port br1 enp5s16f4
ovs-vsctl add-port br1 enp5s16f6
ovs-vsctl add-port br2 enp5s17
ovs-vsctl add-port br2 enp5s17f2 
ovs-vsctl add-port br3 enp5s17f4 
ovs-vsctl add-port br3 enp5s17f6
ovs-vsctl add-port br4 enp5s18                                                
ovs-vsctl add-port br4 enp5s16f1  

ovs-ofctl del-flows br0
ovs-ofctl add-flow br0 in_port=1,actions=mod_dl_dst:10:22:33:44:55:04,output:2
ovs-ofctl del-flows br1
ovs-ofctl add-flow br1 in_port=1,actions=mod_dl_dst:10:22:33:44:55:08,output:2
ovs-ofctl del-flows br2                                                        
ovs-ofctl add-flow br2 in_port=1,actions=mod_dl_dst:10:22:33:44:55:12,output:2
ovs-ofctl del-flows br3                                                         
ovs-ofctl add-flow br3 in_port=1,actions=mod_dl_dst:10:22:33:44:55:16,output:2
ovs-ofctl del-flows br4
ovs-ofctl add-flow br4 in_port=1,actions=mod_dl_dst:00:25:90:ED:BD:DD,output:2

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
		perf stat -C 0 -a -g -e cycles,instructions,L1-dcache-load-misses,L1-dcache-loads,LLC-load-misses,LLC-loads -o /tmp/perfstat${i}.csv -x, sleep $PERIODE_STAT
		sleep 5
		testbed-upload /tmp/perfstat${i}.csv
		
		#write counter                                                              
		for INTERFACE in $INTERFACES ; do                           
			rx_packets=$(cat /sys/class/net/$INTERFACE/statistics/rx_packets)
			rx_missed_errors=$(cat /sys/class/net/$INTERFACE/statistics/rx_missed_errors)
			tx_packets=$(cat /sys/class/net/$INTERFACE/statistics/tx_packets)
			tx_dropped=$(cat /sys/class/net/$INTERFACE/statistics/tx_dropped)
			rx_dropped=$(cat /sys/class/net/$INTERFACE/statistics/rx_dropped)
			echo "----Rate: $RATE ---- Size: 64B ----- " >> /tmp/rate_${RATE}_ifs.txt
			echo "IF: $INTERFACE, Rate: $RATE, rx_packets: $rx_packets" >> /tmp/rate_${RATE}_ifs.txt
			echo "IF: $INTERFACE, Rate: $RATE, rx_missed_errors: $rx_missed_errors" >> /tmp/rate_${RATE}_ifs.txt
			echo "IF: $INTERFACE, Rate: $RATE, tx_packets: $tx_packets" >> /tmp/rate_${RATE}_ifs.txt 
			echo "IF: $INTERFACE, Rate: $RATE, rx_dropped: $rx_dropped" >> /tmp/rate_${RATE}_ifs.txt
			echo "IF: $INTERFACE, Rate: $RATE, tx_dropped: $tx_dropped" >> /tmp/rate_${RATE}_ifs.txt
		done
		testbed-upload /tmp/rate_${RATE}_ifs.txt   
		i=$((i+1))
		sleep 1
	done
done

