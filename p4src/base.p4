/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

#include "include/headers.p4"
#include "include/custom_headers.p4"
#include "include/defines.p4"
#include "include/parsers.p4"
#include "include/actions.p4"
#include "include/port_counters.p4"
#include "include/port_meters.p4"
#include "include/checksums.p4"
#include "include/packet_io.p4"
#include "include/table0.p4"
#include "include/host_meter_table.p4"
#include "include/device_recognition_registers.p4"
#include "include/device_recognition_table.p4"

//------------------------------------------------------------------------------
// INGRESS PIPELINE
//------------------------------------------------------------------------------

control ingress(inout headers_t hdr,
                inout local_metadata_t local_metadata,
                inout standard_metadata_t standard_metadata) {

    apply {
        port_counters_ingress.apply(hdr, standard_metadata);
        port_meters_ingress.apply(hdr, standard_metadata);
        device_recognition_table_control.apply(hdr, standard_metadata);
        packetio_ingress.apply(hdr, standard_metadata);
        table0_control.apply(hdr, local_metadata, standard_metadata);
        host_meter_control.apply(hdr, local_metadata, standard_metadata);
     }
}

//------------------------------------------------------------------------------
// EGRESS PIPELINE
//------------------------------------------------------------------------------

control egress(inout headers_t hdr,
               inout local_metadata_t local_metadata,
               inout standard_metadata_t standard_metadata) {

    apply {
        port_counters_egress.apply(hdr, standard_metadata);
        port_meters_egress.apply(hdr, standard_metadata);
        packetio_egress.apply(hdr, standard_metadata);
    }
}

//------------------------------------------------------------------------------
// SWITCH INSTANTIATION
//------------------------------------------------------------------------------

V1Switch(parser_impl(),
         verify_checksum_control(),
         ingress(),
         egress(),
         compute_checksum_control(),
         deparser()) main;
