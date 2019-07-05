#ifndef __DEFINES__
#define __DEFINES__

#define ETH_TYPE_IPV4 0x0800
#define IP_PROTO_TCP 8w6
#define IP_PROTO_UDP 8w17
#define IP_VERSION_4 4w4
#define IPV4_IHL_MIN 4w5
#define MAX_PORTS 511
#define FEATURE_SESSION_LENGTH 10
#define MAX_DEVICES 254
#define MAX_FLOWS 64516

#ifndef _BOOL
#define _BOOL bool
#endif
#ifndef _TRUE
#define _TRUE true
#endif
#ifndef _FALSE
#define _FALSE false
#endif

typedef bit<48> mac_t;
typedef bit<32> ip_address_t;
typedef bit<16> l4_port_t;
typedef bit<9>  port_t;
typedef bit<16> next_hop_id_t;
typedef bit<16> flow_id_t;
typedef bit<8>  session_size_t;

register<flow_id_t>(MAX_FLOWS) flow_list;
register<session_size_t>(MAX_DEVICES*2) flow_session_size;
register<flow_id_t>(1) flow_count;
register<bit<32>>(MAX_DEVICES*2*FEATURE_SESSION_LENGTH) feature_timestamp;
register<bit<32>>(MAX_DEVICES*2*FEATURE_SESSION_LENGTH) feature_packet_length;

const port_t CPU_PORT = 255;

#endif
