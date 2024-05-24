

#include <core.p4>
#include <v1model.p4>


header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

/*
 * This is a custom protocol header for the calculator. We'll use
 * etherType 0x1234 for it (see parser)
 */
const bit<16> P4CALC_ETYPE = 0x1234;
const bit<8>  P4CALC_P     = 0x50;   // 'P'
const bit<8>  P4CALC_4     = 0x34;   // '4'
const bit<8>  P4CALC_VER   = 0x01;   // v0.1
const bit<8>  P4CALC_PLUS  = 0x2b;   // '+'
const bit<8>  P4CALC_MINUS = 0x2d; //'-'
 

header p4calc_t {

	bit<8> P;
	bit<8> four;
	bit<8> ver;
	bit<8> op;
	bit<32> price;
	bit<32> res;
	bit<32> tprice;
	bit<8> tpricesign;

}

struct headers {
    ethernet_t   ethernet;
    p4calc_t     p4calc;
}


struct metadata {
    
}

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            P4CALC_ETYPE : check_p4calc;
            default      : accept;
        }
    }

    state check_p4calc {
       
       
        transition select(packet.lookahead<p4calc_t>().P,
        packet.lookahead<p4calc_t>().four,
        packet.lookahead<p4calc_t>().ver) {
            (P4CALC_P, P4CALC_4, P4CALC_VER) : parse_p4calc;
            default                          : accept;
        }
       
    }

    state parse_p4calc {
        packet.extract(hdr.p4calc);
        transition accept;
    }
}

/*************************************************************************
 ************   C H E C K S U M    V E R I F I C A T I O N   *************
 *************************************************************************/
control MyVerifyChecksum(inout headers hdr,
                         inout metadata meta) {
    apply { }
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action send_back(bit<32> result) {
       
	hdr.p4calc.res = result;
	bit<48> tempswap = hdr.ethernet.dstAddr;
	hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
	hdr.ethernet.srcAddr = tempswap;
	standard_metadata.egress_spec = standard_metadata.ingress_port;
    }

    action operation_buy() {
       
	send_back(0);//buy represent 0

    }
    action operation_sell()
    {
    	send_back(1);//sell represent 1
    }
    action operation_noaction()
    {
    	send_back(2);//not sell or buy
    }

    action operation_drop() {
        mark_to_drop(standard_metadata);
    }

    
  

    apply {

    	
        if (hdr.p4calc.isValid()) 
        {
            if(hdr.p4calc.op == P4CALC_PLUS)
            {
          	  if(hdr.p4calc.tpricesign == P4CALC_PLUS)
         	   {
         	   	hdr.p4calc.tprice = hdr.p4calc.price + hdr.p4calc.tprice;
         	   	if(hdr.p4calc.tprice > 20){operation_sell();}
            		else{operation_noaction();}
            	   }
           	   else if (hdr.p4calc.tpricesign== P4CALC_MINUS)
           	   {
           	 	if(hdr.p4calc.tprice < hdr.p4calc.price)
           	 	{
           	 		hdr.p4calc.tpricesign = P4CALC_PLUS;
           	 		hdr.p4calc.tprice = hdr.p4calc.price - hdr.p4calc.tprice;
           	 		if(hdr.p4calc.tprice > 20){operation_buy();}
            			else{operation_noaction();}
           	 	}
           	 	else
           	 	{
				hdr.p4calc.tprice = hdr.p4calc.tprice - hdr.p4calc.price;
				if(hdr.p4calc.tprice > 20){operation_sell();}
            			else{operation_noaction();}
           	 	}
           	   }
           }
           
           if(hdr.p4calc.op == P4CALC_MINUS)
           {
           	if(hdr.p4calc.tpricesign == P4CALC_PLUS)
           	{
           		if(hdr.p4calc.tprice < hdr.p4calc.price)
           		{
           			hdr.p4calc.tpricesign = P4CALC_MINUS;
           			hdr.p4calc.tprice = hdr.p4calc.price - hdr.p4calc.tprice;
           			if(hdr.p4calc.tprice > 20){operation_buy();}
            			else{operation_noaction();}
           		}
           		else
           		{
           			hdr.p4calc.tprice = hdr.p4calc.tprice - hdr.p4calc.price;
           			if(hdr.p4calc.tprice > 20){operation_sell();}
            			else{operation_noaction();}
           		}
           	}
           	
           	else if(hdr.p4calc.tpricesign == P4CALC_MINUS)
           	{
           		hdr.p4calc.tprice = hdr.p4calc.price + hdr.p4calc.tprice;
         	   	if(hdr.p4calc.tprice > 20){operation_buy();}
            		else{operation_noaction();}
           	}
           }
        
        } else {
            operation_drop();
        }
 
    }
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { }
}

/*************************************************************************
 *************   C H E C K S U M    C O M P U T A T I O N   **************
 *************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

/*************************************************************************
 ***********************  D E P A R S E R  *******************************
 *************************************************************************/
control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.p4calc);
    }
}

/*************************************************************************
 ***********************  S W I T T C H **********************************
 *************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;

