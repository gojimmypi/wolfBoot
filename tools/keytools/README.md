# Key Tools for signing and key generation

See documentation [here](../../docs/Signing.md).

## KeyGen

```
make wolfboot_signing_private_key.der SIGN=ECC256

# or
./tools/keytools/keygen --ecc256 -g wolfboot_signing_private_key.der
```

## Local Visual Studio Projects

Right-click on `wolfBootKeygenTool`

Properties - Configuration Properties - Debugging

```text
Command:           $(TargetPath)
Command Arguments: --ed25519 -g $(ProjectDir)wolfboot_signing_private_key.der   -keystoreDir  $(ProjectDir)
Working Directory: $(ProjectDir)
```

and for the `wolfBootSignTool`:

```text
Command:           $(TargetPath)
Command Arguments: --ed25519 --sha256 "$(ProjectDir)test.bin"  "$(ProjectDir)wolfboot_signing_private_key.der"  1
Working Directory: $(ProjectDir)
```

The  `$(ProjectDir)` will typically be something like this, where the `keystore.c` is generated:

```text
C:\workspace\wolfBoot-%USERNAME%\tools\keytools
```

Replace `$(ProjectDir)` with your desired path for keys and firmware locations.

### wolfBootTestlib Visual Studio Project

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
