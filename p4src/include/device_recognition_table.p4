#ifndef __DEVICE_RECOGNITION_TABLE__
#define __DEVICE_RECOGNITION_TABLE__

#include "headers.p4"
#include "defines.p4"

control device_recognition_table_control(inout headers_t hdr,
                       inout standard_metadata_t standard_metadata,
                       inout local_metadata_t metadata) {

    //Instanciates a flow key as the concatenation of ip src and addr last bytes
    //Reads and stores the id of the last added flow
    action instanciate_flow_var() {
        metadata.flow_key = hdr.ipv4.src_addr[7:0] ++ hdr.ipv4.dst_addr[7:0];
        flow_count.read(metadata.flow_id, 0);
    }

    //Updates flow count and list to keep track of a new flow; Initializes session size
    action track_new() {
        flow_count.write(0, metadata.flow_id+1);
        flow_list.write((bit<32>)metadata.flow_key, metadata.flow_id);
        metadata.current_session_size=0;
    }

    //Fetch known flow id using the flow key and retrieve its session size
    action read_session_status() {
        flow_list.read(metadata.flow_id, (bit<32>)metadata.flow_key);
        flow_session_size.read(metadata.current_session_size, (bit<32>)metadata.flow_id);
    }

    //Extracts and stores reception timestamp and size of the packet; Increments session size
    //Converts switch original timestamp from microseconds to seconds, ts=tµs/10^6~tµs/2^20
    action extract_features() {
        bit<32> timestamp = (bit<32>)standard_metadata.ingress_global_timestamp >> 20;
        feature_timestamp.write((bit<32>)metadata.flow_id, timestamp);
        feature_packet_length.write((bit<32>)metadata.flow_id, standard_metadata.packet_length);
        flow_session_size.write((bit<32>)metadata.flow_id, metadata.current_session_size+1);
    }

    action drop() {
        mark_to_drop(standard_metadata);
    }

    //Table matching on IP src/dst + TCP src/dst
    table device_recognition_table {
        key = {
            hdr.ipv4.src_addr : ternary;
            hdr.ipv4.dst_addr : ternary;
            hdr.tcp.src_port  : ternary;
            hdr.tcp.dst_port  : ternary;
        }
        actions = {
            NoAction;
            drop;
        }
        const default_action = NoAction();
    }

    apply {
        @atomic {
            instanciate_flow_var();
            if (device_recognition_table.apply().hit) {
                read_session_status();
                if (metadata.current_session_size<FEATURE_SESSION_LENGTH) {
                    extract_features();
                }
            }
            else {
                track_new();
                extract_features();
            }
        }
     }
}

#endif
