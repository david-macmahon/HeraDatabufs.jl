module HeraDatabufs

using HashpipeDatabufs
using Sockets: IPv4

export HeraCatcherIbvpktBlock, netheader, appheader, header
export HeraIbvpktBlock
export HeraCatcherBdaInputBlock

# Re-export the module
export HashpipeDatabufs
# Re-export the struct
export HashpipeDatabuf
# Re-export functions
export get_block_states
export get_block_states!
export states_to_bitmask

const NET_HEADER_SIZE = 42
const FENG_PAYLOAD_SIZE = 4608
const BYTES_PER_PACKET = 4096
const HASHPIPE_IBVPKT_DATABUF_ALIGNMENT_SIZE = 4096

# As of 2023-06-07
const AVX512_ALIGNMENT = 64
const CACHE_ALIGNMENT = 128
const CATCHER_N_BLOCKS = 16
const BASELINES_PER_BLOCK = 4096
const TIME_DEMUX = 2
const N_CHAN_TOTAL = 6144
const N_STOKES = 4

"""
    pad(sz, n)

Returns first multiple of `n` that is greater than or equal to `sz`.
"""
function pad(sz, n)
    cld(sz, n) * n
end

include("hera_ibvpkt.jl")
include("catcher_ibvpkt.jl")
include("catcher_bda_input.jl")

end # module HeraDatabufs