# Visual Studio Workspace Files

Normally excludes from source control, but here for a Visual Studio CMake project workaround:

## launch.vs.json

A default, no-operation project.

## ProjectSettings.json

Without some non-blank default here, Visual Studio starts up with an unintuitive error:

```
CMake Error: Run 'cmake --help' for all supported options.
```

## tasks.vs.json

A hint file that the startup item should be the `CMakeLists.txt` file.

## VSWorkspaceSettings.json

Without the `ExcludedItems` listed in this file, Visual Studio tries top be "helpful"
and set the default startup item to some project file found in the directory tree. This is undesired.


## VSWorkspaceState.json

