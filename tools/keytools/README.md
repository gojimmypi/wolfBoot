# Key Tools for signing and key generation

See documentation [here](../../docs/Signing.md).


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

