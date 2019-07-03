#ifndef __DEVICE_RECOGNITION_TABLE__
#define __DEVICE_RECOGNITION_TABLE__

#include "headers.p4"
#include "defines.p4"
// #include "device_recognition_registers.p4"

typedef bit<8> DevCount_t;
typedef bit<32> DevIpAddr_t;
register<DevCount_t>(512) device_list;

control device_recognition_table_control(inout headers_t hdr,
                       inout standard_metadata_t standard_metadata) {

    action track_new() {

    }

    action update_known() {

    }

    table device_recognition_table {
        key = {
            hdr.ipv4.src_addr : ternary;
            hdr.ipv4.dst_addr : ternary;
        }
        actions = {
            track_new;
            update_known;
        }
        const default_action = track_new();
    }

    apply {
        device_recognition_table.apply();
     }
}

#endif
