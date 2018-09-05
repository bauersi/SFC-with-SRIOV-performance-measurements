--- Forward packets between two ports
local lm     = require "libmoon"
local device = require "device"
local stats  = require "stats"
local log    = require "log"
local memory = require "memory"

function configure(parser)
	parser:argument("dev", "Devices to use, specify the same device twice to echo packets."):args(2):convert(tonumber)
	parser:option("-t --threads", "Number of threads per forwarding direction using RSS."):args(1):convert(tonumber):default(1)
	return parser:parse()
end

function master(args)
	-- configure devices
	for i, dev in ipairs(args.dev) do
		args.dev[i] = device.config{
			port = dev,
			txQueues = args.threads,
			rxQueues = args.threads,
			rssQueues = args.threads
		}
	end
	device.waitForLinks()

	-- print stats
	stats.startStatsTask{devices = args.dev}

	-- start forwarding tasks
--	for i = 1, args.threads do
	i =1
	lm.startTask("forwardA", args.dev[1]:getRxQueue(i - 1), args.dev[2]:getTxQueue(i - 1))
	-- lm.startTask("forwardB", args.dev[3]:getRxQueue(i - 1), args.dev[4]:getTxQueue(i - 1))
	-- lm.startTask("forwardC", args.dev[5]:getRxQueue(i - 1), args.dev[6]:getTxQueue(i - 1))
	-- lm.startTask("forwardD", args.dev[7]:getRxQueue(i - 1), args.dev[8]:getTxQueue(i - 1))
	-- lm.startTask("forwardE", args.dev[9]:getRxQueue(i - 1), args.dev[10]:getTxQueue(i - 1))

	-- bidirectional fowarding only if two different devices where passed
	--	if args.dev[1] ~= args.dev[2] then
	--		lm.startTask("forward", args.dev[2]:getRxQueue(i - 1), args.dev[1]:getTxQueue(i - 1))
	--	end
	--end
	lm.waitForTasks()
end

function forwardA(rxQueue, txQueue)
	-- a bufArray is just a list of buffers that we will use for batched forwarding
	local bufs = memory.bufArray()
	nextMacA = parseMacAddress("00:22:33:44:55:04",true)
	while lm.running() do -- check if Ctrl+c was pressed
		-- receive one or more packets from the queue
		local count = rxQueue:recv(bufs)
		for i = 1, count do
			local buf = bufs[i]
			pkt = buf:getEthPacket()
			pkt.eth.dst:set(nextMacA)
		end
		-- send out all received bufs on the other queue
		-- the bufs are free'd implicitly by this function
		txQueue:sendN(bufs, count)
	end
end

function forwardB(rxQueue, txQueue)
        -- a bufArray is just a list of buffers that we will use for batched forwarding
        local bufs = memory.bufArray()
        nextMacB = parseMacAddress("00:22:33:44:55:08",true)
        while lm.running() do -- check if Ctrl+c was pressed
                -- receive one or more packets from the queue
                local count = rxQueue:recv(bufs)
                for i = 1, count do
                        local buf = bufs[i]
                        pkt = buf:getEthPacket()
                        pkt.eth.dst:set(nextMacB)
                end
                -- send out all received bufs on the other queue
                -- the bufs are free'd implicitly by this function
                txQueue:sendN(bufs, count)
        end
end

function forwardC(rxQueue, txQueue)
        -- a bufArray is just a list of buffers that we will use for batched forwarding
        local bufs = memory.bufArray()
        nextMacB = parseMacAddress("00:22:33:44:55:12",true)
        while lm.running() do -- check if Ctrl+c was pressed
                -- receive one or more packets from the queue
                local count = rxQueue:recv(bufs)
                for i = 1, count do
                        local buf = bufs[i]
                        pkt = buf:getEthPacket()
                        pkt.eth.dst:set(nextMacB)
                end
                -- send out all received bufs on the other queue
                -- the bufs are free'd implicitly by this function
                txQueue:sendN(bufs, count)
        end
end

function forwardD(rxQueue, txQueue)
        -- a bufArray is just a list of buffers that we will use for batched forwarding
        local bufs = memory.bufArray()
        nextMacB = parseMacAddress("00:22:33:44:55:16",true)
        while lm.running() do -- check if Ctrl+c was pressed
                -- receive one or more packets from the queue
                local count = rxQueue:recv(bufs)
                for i = 1, count do
                        local buf = bufs[i]
                        pkt = buf:getEthPacket()
                        pkt.eth.dst:set(nextMacB)
                end
                -- send out all received bufs on the other queue
                -- the bufs are free'd implicitly by this function
                txQueue:sendN(bufs, count)
        end
end

function forwardE(rxQueue, txQueue)
        -- a bufArray is just a list of buffers that we will use for batched forwarding
        local bufs = memory.bufArray()
        nextMacB = parseMacAddress("00:22:33:44:55:20",true)
        while lm.running() do -- check if Ctrl+c was pressed
                -- receive one or more packets from the queue
                local count = rxQueue:recv(bufs)
                for i = 1, count do
                        local buf = bufs[i]
                        pkt = buf:getEthPacket()
                        pkt.eth.dst:set(nextMacB)
                end
                -- send out all received bufs on the other queue
                -- the bufs are free'd implicitly by this function
                txQueue:sendN(bufs, count)
        end
end

