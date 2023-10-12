###
###  HeraAppHeader
###

struct HeraAppHeader
    mca::Int64
end

function mcnt(hah::HeraAppHeader)
    (ntoh(hah.mca) & 0xffff_ffff_e000_0000) >> 19
end

function chan(hah::HeraAppHeader)
    ((ntoh(hah.mca) & 0x0000_0000_1fff_0000) >> 16) % Int16
end

function ant(hah::HeraAppHeader)
    ((ntoh(hah.mca) & 0x0000_0000_0000_ffff)      ) % Int16
end

function Core.NamedTuple(hah::HeraAppHeader)
    (; mcnt=mcnt(hah), chan=chan(hah), ant=ant(hah))
end

function Base.show(io::IO, hah::HeraAppHeader)
    print(io, "HeraAppHeader(")
    print(io, "mcnt=");   print(io, mcnt(hah))
    print(io, ", chan="); print(io, chan(hah))
    print(io, ", ant=");  print(io, ant(hah))
    print(io, ")")
end

###
###  HeraIbvpktPacket
###

struct HeraIbvpktPacket
    netheader::Vector{UInt8}                  # (NET_HEADER_SIZE,)
    appheader::Array{HeraAppHeader, 0} # ()
    # TODO figure out whether the payload has additional dimensionality
    payload::Vector{UInt8}           # (BYTES_PER_PACKET÷sizeof(Complex{Int32}),)
end

function HeraIbvpktPacket(p::Ptr{Nothing})
    netheader = unsafe_wrap(Array, Ptr{UInt8}(p), NET_HEADER_SIZE)
    p += pad(sizeof(netheader), AVX512_ALIGNMENT)
    appheader = unsafe_wrap(Array, Ptr{HeraAppHeader}(p), ())
    p += pad(sizeof(appheader), AVX512_ALIGNMENT)
    payload = unsafe_wrap(Array, Ptr{UInt8}(p), FENG_PAYLOAD_SIZE)

    HeraIbvpktPacket(netheader, appheader, payload)
end

function Base.sizeof(::Type{HeraIbvpktPacket})
    pad(NET_HEADER_SIZE, AVX512_ALIGNMENT) +
    pad(sizeof(HeraAppHeader), AVX512_ALIGNMENT) +
    pad(FENG_PAYLOAD_SIZE, AVX512_ALIGNMENT)
end

###
###  HeraIbvpktBlock
###

struct HeraIbvpktBlock <: AbstractBlock
    pkts::Vector{HeraIbvpktPacket}  # fld(block_size, sizeof(HeraIbvpktPacket))
end

function HeraIbvpktBlock(p::Ptr{Nothing}, block_size)
    pkts_per_block = fld(block_size, sizeof(HeraIbvpktPacket))
    pkts = Vector{HeraIbvpktPacket}(undef, pkts_per_block)
    for i in 1:pkts_per_block
        pkts[i] = HeraIbvpktPacket(p)
        p += sizeof(HeraIbvpktPacket)
    end

    HeraIbvpktBlock(pkts)
end

# Does not account for any unused space at the end of the databuf block!
function Base.sizeof(h::HeraIbvpktBlock)
    mapreduce(sizeof, +, h.pkts)
end
