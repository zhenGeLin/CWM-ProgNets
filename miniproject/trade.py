#!/usr/bin/env python3

import re

from scapy.all import *

class P4calc(Packet):
    name = "P4calc"
    fields_desc = [ StrFixedLenField("P", "P", length=1),
                    StrFixedLenField("Four", "4", length=1),
                    XByteField("version", 0x01),
                    StrFixedLenField("op", "+", length=1),
                    IntField("price", 0),
                    IntField("result", 0xDEADBABE)]

bind_layers(Ether, P4calc, type=0x1234)

class NumParseError(Exception):
    pass

class OpParseError(Exception):
    pass

class Token:
    def __init__(self,type,value = None):
        self.type = type
        self.value = value

def num_parser(s, i, ts):
    pattern = r"\s*([0-9]+)\s*"
    match = re.match(pattern,s[i:])
    if match:
        ts.append(Token('num', match.group(1)))
        return i + match.end(), ts
    raise NumParseError('Expected number literal.')


def op_parser(s, i, ts):
    pattern = r"\s*([-+&|^])\s*"
    match = re.match(pattern,s[i:])
    if match:
        ts.append(Token('num', match.group(1)))
        return i + match.end(), ts
    raise NumParseError("Expected binary operator '+'.")


def make_seq(p1, p2):
    def parse(s, i, ts):
        i,ts2 = p1(s,i,ts)
        return p2(s,i,ts2)
    return parse

def get_if():
    ifs=get_if_list()
    iface= "veth0-1" # "h1-eth0"

    return iface

def main():

    print("please send the change of stock market price compared to yesterday's average price, + means higher,  - means lower, the value should be the change of price.")
    
    p = make_seq(op_parser,num_parser)
    s = ''
    #iface = get_if()
    iface = "enx0c37965f8a12"

    while True:
        s = input('> ')
        if s == "quit":
            break
        '''print(s)'''
        try:
        
            i,ts = p(s,0,[])
            pkt = Ether(dst='00:04:00:00:00:00', type=0x1234) / P4calc(op=ts[0].value,
                                              price=int(ts[1].value))

            pkt = pkt/' '
            
            #pkt.show()
            resp = srp1(pkt, iface=iface,timeout=5, verbose=False)
            if resp:
                p4calc=resp[P4calc]
                if p4calc:
                    if p4calc.result == 0:
                    	print("buy")
                    elif p4calc.result == 1:
                    	print("sell")
                    else:
                    	print("Don't do anything, keep observing")
                    
                else:
                    print("cannot find P4calc header in the packet")
            else:
                print("Didn't receive response")
        except Exception as error:
            print(error)


if __name__ == '__main__':
    main()


