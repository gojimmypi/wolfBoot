
# Convert the wolfBoot raw public key der file to a standard public-key container
#
# make_spki_from_raw_xy.py  (ASCII only)
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization

raw = open("keystore.der", "rb").read()  # expected 64 bytes: X||Y
if len(raw) != 64:
    raise SystemExit(f"expected 64 bytes, got {len(raw)}")

# Build uncompressed SEC1 point: 0x04 || X || Y
sec1 = b"\x04" + raw

# Create a key object (assumes prime256v1 / NIST P-256)
key = ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), sec1)

# Write SPKI DER and PEM
open("signer_pub.der", "wb").write(
    key.public_bytes(
        serialization.Encoding.DER,
        serialization.PublicFormat.SubjectPublicKeyInfo
    )
)
open("signer_pub.pem", "wb").write(
    key.public_bytes(
        serialization.Encoding.PEM,
        serialization.PublicFormat.SubjectPublicKeyInfo
    )
)
print("Wrote signer_pub.der and signer_pub.pem")
