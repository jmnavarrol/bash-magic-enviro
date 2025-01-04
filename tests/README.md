BME: unitary tests
==================

As BME grows more complex, the need for unit tests arises.  While there are some frameworks for testing bash/shell scripts, I preferred building one customized for this project's needs (this may change in the future).

* Tests should be files matching the *'test_\*.sh*' pattern and should have the execution bit set (i.e.: `chmod ug+x`).
* Tests are run by the [maketests.sh](./maketests.sh) script.
* [maketests.sh](./maketests.sh) script without parameters will run all tests it finds under the ['tests/' directory](./) and subdirectories within.
* [maketests.sh](./maketests.sh) also accepts paths (either absolute or relative to current directory) and in that case it will run tests found within those.  
  i.e.: `./maketests.sh core` or `./maketests.sh ../../alternate_dir/modules/something/test_sometest.sh core`.
* [maketests.sh](./maketests.sh) runs each script on a clean subshell with helper functions and some environment variables:
  * **helper functions:** the [helper functions file](./helper_functions.sh) is sourced into the tests' environment so its included functions can be used by scripts.  Review its contents.
  * **environment variables:** only those needed to launch the test scripts.
    * **PATH:** PATH is mangled so it includes the directory where BME code can be found.  That means that in order to load BME's entrypoint you just need to `source bash-magic-enviro` (just like it's expected for end-users to do on their Bash environments).
    * **HOME:** an empty directory that the tests may use (i.e.: it can mimic a user's home directory under which you can set a test project, etc.).  This scratch dir is deleted after each test unless it fails; in that case it is preserved for diagnosis.
    * **CURRENT_TESTFILE_NUMBER:** *"internal"* counter that helps tests' presentation output from the *test_name()* helper function.  Do not modify.

Each test script runs on a clean subshell (except for the environment variables described above) and its return code is checked: **0** for success, any other code for failure.

**NOTES:**
* [version tests](./core/test_010_version.sh) require internet access since it tries to compare local versions with highest published at GitHub.
* [modules' tests](./modules/): review each module requirements or else their related tests may fail.
