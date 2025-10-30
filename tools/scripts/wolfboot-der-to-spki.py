#!/usr/bin/env python3

# Convert the wolfBoot raw public key der file to a standard public-key container
#
# make_spki_from_raw_xy.py  (ASCII only)
#
# Example:
#   ./tools/scripts/wolfboot-der-to-spki.py   ./tools/keytools/keystore.der

import argparse
import sys
from pathlib import Path

def main():
    ap = argparse.ArgumentParser(
        description="Convert a raw ECC public key (X||Y) to SPKI DER/PEM next to the input file. "
                    "If the input is already SPKI DER, PEM is produced too.")
    ap.add_argument("input", help="Path to input public key file (raw X||Y or SPKI DER)")
    ap.add_argument("--curve", choices=["p256", "p384", "p521"], default=None,
                    help="Curve override. If not set, auto-detect by file size (64=P-256, 96=P-384, 132=P-521).")
    args = ap.parse_args()

    in_path = Path(args.input).resolve()
    if not in_path.is_file():
        print("ERROR: input path does not exist or is not a file:", in_path, file=sys.stderr)
        sys.exit(2)
    raw = in_path.read_bytes()

    # Decide curve and wrap as SPKI if necessary
    curve = args.curve
    is_raw_xy = False

    # Try to load as SPKI DER first
    key_obj = None
    load_err = None
    try:
        from cryptography.hazmat.primitives import serialization
        key_obj = serialization.load_der_public_key(raw)
    except Exception as e:
        load_err = e

    if key_obj is None:
        # Not SPKI DER; assume raw X||Y
        is_raw_xy = True
        ln = len(raw)
        if curve is None:
            if ln == 64:
                curve = "p256"
            elif ln == 96:
                curve = "p384"
            elif ln == 132:
                curve = "p521"
            else:
                print("ERROR: input looks like raw X||Y but length is not 64/96/132 bytes:", ln, file=sys.stderr)
                sys.exit(3)

        from cryptography.hazmat.primitives.asymmetric import ec
        if curve == "p256":
            crv = ec.SECP256R1()
            exp_len = 64
        elif curve == "p384":
            crv = ec.SECP384R1()
            exp_len = 96
        else:
            crv = ec.SECP521R1()
            exp_len = 132

        if ln != exp_len:
            print("ERROR: curve", curve, "expects", exp_len, "bytes of X||Y, got", ln, file=sys.stderr)
            sys.exit(4)

        # Build uncompressed SEC1 point: 0x04 || X || Y
        sec1 = b"\x04" + raw
        try:
            key_obj = ec.EllipticCurvePublicKey.from_encoded_point(crv, sec1)
        except Exception as e:
            print("ERROR: cannot wrap raw X||Y into SEC1/SPKI:", e, file=sys.stderr)
            sys.exit(5)

    # Prepare outputs next to input
    out_der = in_path.with_name(in_path.stem + "_spki.der")
    out_pem = in_path.with_name(in_path.stem + "_spki.pem")

    from cryptography.hazmat.primitives import serialization
    der = key_obj.public_bytes(
        serialization.Encoding.DER,
        serialization.PublicFormat.SubjectPublicKeyInfo
    )
    pem = key_obj.public_bytes(
        serialization.Encoding.PEM,
        serialization.PublicFormat.SubjectPublicKeyInfo
    )
    out_der.write_bytes(der)
    out_pem.write_bytes(pem)

    # Also print the SPKI SHA-256 (useful to compare with wolfBoot pubkey-hint TLV)
    try:
        import hashlib, binascii
        h = hashlib.sha256(der).digest()
        print("Wrote:", out_der)
        print("Wrote:", out_pem)
        print("SPKI SHA-256 (hex):", binascii.hexlify(h).decode("ascii"))
    except Exception:
        print("Wrote:", out_der)
        print("Wrote:", out_pem)

if __name__ == "__main__":
    main()
