#ifndef __CUSTOM_HEADERS__
#define __CUSTOM_HEADERS__

struct headers_t {
    packet_out_header_t packet_out;
    packet_in_header_t packet_in;
    ethernet_t ethernet;
    ipv4_t ipv4;
    tcp_t tcp;
    udp_t udp;
}

struct local_metadata_t {
    bit<16>         l4_src_port;
    bit<16>         l4_dst_port;
    next_hop_id_t   next_hop_id;
    session_size_t  current_session_size;
    flow_id_t       flow_id;
    flow_id_t       flow_key;
}

#endif
