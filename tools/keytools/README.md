# Key Tools for signing and key generation

## Sign

See documentation in [docs/Signing.md](../../docs/Signing.md).

## KeyGen and KeyStore

See documentation [docs/keystore.md](../../docs/keystore.md).

## Quick STart (Linux)

```
make wolfboot_signing_private_key.der SIGN=ECC256

# or
./tools/keytools/keygen --ecc256 -g wolfboot_signing_private_key.der
```

## Local Visual Studio Projects

There are three projects to:

1. Generate a new signing key
2. Sign an image
3. Verify the signed image

Visual Studio `$(ProjectDir)` is typically `[WOLFBOOT_ROOT]\tools\keytools`.

### Step 1: wolfBootKeyGenTool Visual Studio Project

Build the project. Generate a new signing key with `keygen.exe`.

```DOS
keygen.exe [ --ed25519 | --ed448 | --ecc256 | --ecc384 | --ecc521 | --rsa2048 | --rsa3072 | --rsa4096 ] ^
           [ -g privkey]     [ -i pubkey] [ -keystoreDir dir]  ^
           [ --id {list}]    [ --der]                        ^
           [ --exportpubkey] [ --nolocalkeys]
```

WARNING: Key Generation will *overwrite* any prior keystore files.

Right-click on `wolfBootKeygenTool` project, typically in:

```text
C:\workspace\wolfBoot-%USERNAME%\tools\keytools
```

Select: Properties - Configuration Properties - Debugging:

```text
Command:           $(TargetPath)
Command Arguments: --ed25519 -g $(ProjectDir)wolfboot_signing_private_key.der   -keystoreDir  $(ProjectDir)
Working Directory: $(ProjectDir)
```

Replace `$(ProjectDir)` with your desired path for keys and firmware locations.
Otherwise the private key will be created in `tools\keytools`.

Example:

```DOS
cd $WOLFBOOT_ROOT\tools\keytools

:: cmd       sign     private key
:: ------- --------- -----------------------------------
keygen.exe --ed25519 -g wolfboot_signing_private_key.der
```



### Step 2: wolfBootSignTool Visual Studio Project

Build the project. Sign an image with `sign.exe  [OPTIONS]  IMAGE.BIN  KEY.DER  VERSION`.

Right-click on `wolfBootSignTool` project, typically in:

```text
C:\workspace\wolfBoot-%USERNAME%\tools\keytools
```

Select: Properties - Configuration Properties - Debugging:

```text
Command:           $(TargetPath)
Command Arguments: --ed25519 --sha256 "$(ProjectDir)test.bin"  "$(ProjectDir)wolfboot_signing_private_key.der"  1
Working Directory: $(ProjectDir)
```

The `$(ProjectDir)` will typically be something like this, where the `keystore.c` was generated in Step 1 (above):

Example:

```DOS
cd $WOLFBOOT_ROOT\tools\keytools

:: cmd       sign     hash   input     private key                    version
:: ----- --------- -------- -------- -------------------------------- -------
sign.exe --ed25519 --sha256 test.bin wolfboot_signing_private_key.der 1
```

Be sure the signing algorithm used here matches the one on the key generation!

Expected output:

```text
wolfBoot KeyTools (Compiled C version)
wolfBoot version 2060000
Update type:          Firmware
Input image:          C:\workspace\wolfBoot-<user>\tools\keytools\test.bin
Selected cipher:      ED25519
Selected hash:        SHA256
Private key:          C:\workspace\wolfBoot-<user>\tools\keytools\wolfboot_signing_private_key.der
Output  image:        C:\workspace\wolfBoot-<user>\tools\keytools\test_v1_signed.bin
Target partition id:  1
Manifest header size: 256
Found ED25519 key
Hashing primary pubkey, size: 32
Calculating SHA256 digest...
Signing the digest...
Sign: 0x01
Output image(s) successfully created.
```


### Step 3. wolfBootTestlib Visual Studio Project

The `IS_TEST_LIB_APP` Macro is needed for the Visual Studio `wolfBootTestLib.vcproj` project file.
See also the related `wolfBootImage.props` file.

Other additional preprocessor macros defined in project file:

```text
__WOLFBOOT;
WOLFBOOT_NO_PARTITIONS;
WOLFBOOT_HASH_SHA256;
WOLFBOOT_SIGN_ECC256;
WOLFSSL_USER_SETTINGS;
WOLFSSL_HAVE_MIN;
WOLFSSL_HAVE_MAX;
```
