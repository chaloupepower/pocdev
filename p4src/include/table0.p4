#ifndef __TABLE0__
#define __TABLE0__

#include "headers.p4"
#include "defines.p4"

control table0_control(inout headers_t hdr,
                       inout local_metadata_t local_metadata,
                       inout standard_metadata_t standard_metadata) {

    direct_counter(CounterType.packets_and_bytes) table0_counter;

    action ipv4_forward(mac_t dst_addr, port_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action drop() {
        mark_to_drop(standard_metadata);
    }

    table table0 {
        key = {
            standard_metadata.ingress_port : ternary;
            hdr.ethernet.src_addr          : ternary;
            hdr.ethernet.dst_addr          : ternary;
            hdr.ethernet.ether_type        : ternary;
            hdr.ipv4.src_addr              : ternary;
            hdr.ipv4.dst_addr              : ternary;
            hdr.ipv4.protocol              : ternary;
            local_metadata.l4_src_port     : ternary;
            local_metadata.l4_dst_port     : ternary;
        }
        actions = {
            ipv4_forward;
            NoAction;
            drop;
        }
        const default_action = drop;
        counters = table0_counter;
    }

    apply {
        table0.apply();
     }
}

#endif
