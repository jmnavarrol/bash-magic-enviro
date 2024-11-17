BME: unitary tests
==================

As BME grows more complex, the need for unit tests arises.  While there are some frameworks for testing bash/shell scripts, I preferred building one customized for this project's needs (this may change in the future).

The tests' entrypoint is the [maketests.sh](./maketests.sh) script:
1. it finds the test files (those with name following the *'test_\*.sh* pattern).  Optionally, you can pass a list of paths to tests and the script will run those instead.
1. it runs each script on a clean subshell with helper functions and some environment variables:
   * **helper functions:** the [helper functions file](./helper_functions.sh) is sourced into the tests' environment so they can be used by scripts.  Review its contents.
   * **environment variables:** only those needed to launch the test scripts.
     * **PATH:** PATH is mangled so it includes the directory where BME code can be found.  That means that in order to load BME's entrypoint you just need to `source bash-magic-enviro` (just like it's expected for end-users to do on their Bash environments).
     * **HOME:** an empty directory that the tests may use (i.e.: it can mimick a user's home directory under which you can set a test project, etc.).  This scratch dir is deleted after each test unless it fails; in that case it is preserved for diagnosis.
     * **CURRENT_TESTFILE_NUMBER:** *"internal"* counter that helps tests' presentation output from the *test_name()* helper function.  Do not modify.

Test scripts can be either right under this tests directory or in subdirectories within for better organization.

Test scripts must have the execute bit set and should start with env Bash shabang *#!/usr/bin/env bash*.  Scripts are **not** sourced, they are run.

Each test script runs on a clean subshell (except for the environment variables described above) and its return code is checked: **0** for success, any other code for failure.

**NOTES:**
* [version tests](./core/test_010_version.sh) require internet access since it tries to compare local versions with highest published at GitHub.
* [modules' tests](./modules/): review each module requirements or else their related tests may fail.
