BME: unitary tests
==================

As BME grows more complex, the need for unit tests arises.  While there are some frameworks for testing bash/shell scripts, I preferred building one customized for this project's needs (this may change in the future).

----
**Contents:**<a name="contents"></a>
1. [General considerations](#general)
1. [Test types](#types)

## General considerations<a name="general"></a>
* Tests should be files matching the *'test_\*.sh*' pattern and should have the execution bit set (i.e.: `chmod ug+x`).
* Tests are run by the [maketests.sh](./maketests.sh) script.
* [maketests.sh](./maketests.sh) script without parameters will run all tests it finds under the ['tests/' directory](./) and subdirectories within.
* [maketests.sh](./maketests.sh) also accepts paths (either absolute or relative to current directory) and in that case it will run tests found within those.  
  i.e.: `./maketests.sh core` or `./maketests.sh ../../alternate_dir/modules/something/test_sometest.sh core`.
* [maketests.sh](./maketests.sh) sets a *scratch directory* for each script and runs it a clean subshell with helper functions and some environment variables:
  * **helper functions:** the [helper functions file](./helper_functions.sh) is sourced into the tests' environment so its included functions can be used by scripts.  Review its contents.
  * **environment variables:** only those needed to launch the test scripts.  A general description follows:
    * **PATH:** set to a default, minimal path: *'/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin'*.
    * **SOURCES_DIR:** directory with a copy of BME's sources.
    * **HOME:** an empty directory that the tests may use (i.e.: it can mimic a user's home directory under which you can set a test project, etc.).  This scratch dir is deleted after each test unless it fails; in that case it is preserved for diagnosis.
    * **CURRENT_TESTFILE_NUMBER:** *"internal"* counter that helps tests' presentation output from the *test_name()* helper function.  Do not modify.

Each test script runs on a clean subshell (except for the environment variables described above) and its return code is checked: **0** for success, any other code for failure.

**NOTES:**
* [version tests](./core/test_010_version.sh) require internet access since it tries to compare local versions with highest published at GitHub.
* [modules' tests](./modules/): review each module requirements or else their related tests may fail.

<sub>[back to contents](#contents).</sub>

## Test types<a name="types"></a>
There are three different types of tests.  Each type is restricted to a given subdirectory and gets a different environment:
1. **[setup](./setup/):** unit tests for the *pre-flight* features, before BME itself is configured or installed (i.e.: checks for [Makefile](../Makefile) targets, [check dependencies script](../make-checks.sh), etc.).  
  These tests get the following environment variables:
   * **HOME:** set to the test's dedicated *scratch dir*.
   * **PATH:** minimal path **without** *~/bin*.
   * **SOURCES_DIR:** path within *$HOME* to already built BME sources.
1. **[core](./core/):** unit tests for BME's core features.  These tests get an environment with BME already installed under `${HOME}/bin` and `${HOME}/bin` in path, but still unloaded.  
  Environment variables:
   * **HOME:** set to the test's dedicated *scratch dir*.
   * **PATH:** path already includes *~/bin*, where BME is installed, so BME can be loaded by `source bash-magic-enviro`.
1. **[modules](./modules/):** unit tests for BME modules.  Tests get BME already installed and loaded.  
  Environment variables:
   * **HOME:** set to the test's dedicated *scratch dir*.
   * **PATH:** path already includes *~/bin*, where BME is installed, and `bash-magic-enviro` is already sourced so each test script needs only to focus on its related modules' features.

<sub>[back to contents](#contents).</sub>

