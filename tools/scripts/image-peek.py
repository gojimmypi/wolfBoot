#!/usr/bin/env python3
import struct, sys, datetime
from pathlib import Path
TYPE_NAMES={0x0001:'version',0x0002:'timestamp',0x0003:'hash',0x0004:'attr',0x0010:'pubkey_hint',0x0020:'signature'}
def parse_header(data,header_size=0x100):
    magic=data[0:4]; size_le=struct.unpack('<I',data[4:8])[0]; tlvs=[]; off=8
    while off<header_size:
        while off<header_size and data[off]==0xFF: off+=1
        if off+4>header_size: break
        t=struct.unpack('<H',data[off:off+2])[0]; l=struct.unpack('<H',data[off+2:off+4])[0]; off+=4
        if off+l>header_size: break
        v=data[off:off+l]; off+=l; tlvs.append((t,l,v))
    return {'magic':magic,'size':size_le,'tlvs':tlvs,'header_size':header_size}
def decode_tlv(t,v):
    n=TYPE_NAMES.get(t,'unknown_0x%04x'%t)
    if t==0x0001 and len(v)==4: return n,struct.unpack('<I',v)[0]
    if t==0x0002 and len(v)==8: ts=struct.unpack('<Q',v)[0];
    if t==0x0002 and len(v)==8:
        try: dt=datetime.datetime.utcfromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S UTC')
        except Exception: dt='out-of-range'
        return n,{'unix':ts,'utc':dt}
    if t==0x0003: return n,{'sha':v.hex()}
    if t==0x0010: return n,{'digest':v.hex()}
    if t==0x0020: return n,{'sig':v.hex()}
    if t==0x0004:
        return (n,struct.unpack('<H',v)[0]) if len(v)==2 else (n,v.hex())
    return n,v.hex()
def print_report(p):
    try: m=p['magic'].decode('ascii')
    except Exception: m=p['magic'].hex()
    print('Magic:',m,'(raw:',p['magic'].hex()+')')
    print('Payload size:%d bytes (0x%08X)'%(p['size'],p['size']))
    print('Assumed header size:%d bytes (0x%X)'%(p['header_size'],p['header_size']))
    print('TLVs:')
    for i,(t,l,v) in enumerate(p['tlvs'],1):
        n,val=decode_tlv(t,v)
        print('%2d) type=0x%04X (%s) len=%d'%(i,t,n,l))
        if isinstance(val,dict):
            for k,vv in val.items(): print('     %s: %s'%(k,vv))
        else: print('     value:',val)
def main():
    if len(sys.argv)<2:
        print('Usage: python wolfboot_parse.py <signed_image.bin>'); sys.exit(2)
    path=Path(sys.argv[1]); data=path.read_bytes(); p=parse_header(data,header_size=0x100); print_report(p)
if __name__=='__main__': main()
