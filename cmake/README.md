
From the [docs for CMake Presets](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html):

"_Added in version 3.19.

One problem that CMake users often face is sharing settings with other people for common ways to configure
a project. This may be done to support CI builds, or for users who frequently use the same build. CMake
supports two main files, `CMakePresets.json` and `CMakeUserPresets.json`, that allow users to specify common
configure options and share them with others. CMake also supports files included with the include field.

`CMakePresets.json` and` CMakeUserPresets.json` live in the project's root directory. They both have
exactly the same format, and both are optional (though at least one must be present if `--preset` is
specified). `CMakePresets.json` is meant to specify project-wide build details, while `CMakeUserPresets.json`
is meant for developers to specify their own local build details.

CMakePresets.json may be checked into a version control system, and `CMakeUserPresets.json` should NOT be
checked in. For example, if a project is using Git, `CMakePresets.json` may be tracked, and
`CMakeUserPresets.json` should be added to the .gitignore."

