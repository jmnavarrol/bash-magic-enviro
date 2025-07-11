# CHANGELOG

## Next Release
* differences from [previous tag](/../../compare/v1.10.1…main).

## v1.10.1 (2025-JUL-05)
* differences from [previous tag](/../../compare/v1.10.0…v1.10.1).
* **logs management:**
  * README updated.
  * **bme_log():**
    * *log_level* "internal" function variable renamed to *log_indent* to better match its purpose.
    * color is reset at the end of log message in case the caller forgot it.
    * all known log types are mapped to a syslog severity so they are printed accordingly (or not printed at all).
    * *DEBUG* level adds the calling function name to the log message prefix.

## v1.10.0 (2025-APR-06)
* differences from [previous tag](/../../compare/v1.9.2…v1.10.0).
* **logs management:**
  * **bme_log():** on multiline log messages it now honors the requested indentation level instead of indenting just the first line.
  * New **BME_LOG_LEVEL** environment variable (default **INFO**) to set which logs will be printed or not.
* all `return -1` calls updated to `return 1` for POSIX standard alignment.
* **unit tests:**
  * framework refactored so now it offers different pre-loaded environments for *setup*, *core* or *modules* tests (see [README](./tests/README.md)).
  * [#13](../../issues/13): [tests/maketests.sh](./tests/maketests.sh/) $PATH setting on macos with homebrew corrected.
* **UPGRADE NOTES:**
  * Due to the change in *bme_log()*, you may need to review your own calls to this function with a multiline message and adjust the number of tabs you add on the 2nd line onwards.
  * If you made use of the unit testing framework you may need to review your scripts' expectations.
  * **DEBUG** level messages won't be printed anymore unless you set the **BME_LOG_LEVEL** environment variable to **DEBUG** value.

## v1.9.2 (2025-FEB-23)
* differences from [previous tag](/../../compare/v1.9.1…v1.9.2).
* tests framework discovers test scripts on generic paths.
* [#12](../../issues/12): BME now runs on macos.

## v1.9.1 (2025-JAN-03)
* differences from [previous tag](/../../compare/v1.9.0…v1.9.1).
* [#11](../../issues/11): python3-virtualenvs module doesn't properly manage requirements' includes.

## v1.9.0 (2025-JAN-03)
* differences from [previous tag](/../../compare/v1.8.2…v1.9.0).
* [#10](../../issues/10): `make uninstall` preserves contents it doesn't manage.
  * install/uninstall process moved to MANIFEST file based one.
  * Added tests for this new feature.
* [python3-virtualenvs.module](./src/bash-magic-enviro_modules/python3-virtualenvs.module) doesn't depend on [virtualenvwrapper](https://virtualenvwrapper.readthedocs.io) anymore.
* **unit tests framework:**
  * total and per-batch timers added.
  * new helper method: **indentor**.
* **UPGRADE NOTES:**
  * **[python3-virtualenvs.module](./src/bash-magic-enviro_modules/python3-virtualenvs.module):**
    * **BME_PYTHON_VERSION** renamed to **BME_PYTHON3_CMD**.  If you make use of the *BME_PYTHON_VERSION* environment variable to set a explicit Python executable, you should rename it to *BME_PYTHON3_CMD* in your *.bme_\** files.
  * `make uninstall` no longer looks for *.installdir* and *.devinstalldir* under sources but **.MANIFEST** and **.MANIFEST.DEV** instead to *"remeber"* where BME was installed.  If you made use of these files' contents you should review the new files and format and plan accordingly.

## v1.8.2 (2024-NOV-22)
* differences from [previous tag](/../../compare/v1.8.1…v1.8.2).
* [#8](../../issues/8): new project environment variable **BME_PROJECT_CONFIG_DIR** allows setting per-project *"hidden dir"*.
* __bme_debug(): behaviour refactored so it emits the message passed as param instead of a return code.
* unittest framework:
  * offers better isolation for each test script.
  * it can accept a list of tests to run from command line.
  * added [README](./tests/README.md) for developers' benefit.

## v1.8.1 (2024-MAY-15)
* differences from [previous tag](/../../compare/v1.8.0…v1.8.1).
* Unit test framework refactored so each test run gets a clean environment.
* BUG CORRECTED: Another fix for proper .bme_env file loading (only when exact directory match for BME_PROJECT_DIR, or new project loading if dropping on a subdirectory).

## v1.8.0 (2024-MAY-02)
* differences from [previous tag](/../../compare/v1.7.2…v1.8.0).
* **UPGRADE NOTES:**
  * Python virtualenvs are now project-scoped instead of user-global.  That means they will be regenerated under "${BME_PROJECT_DIR}/${BME_HIDDEN_DIR}" and you can delete them from under ${BME_CONFIG_DIR} (which defaults to "${HOME}/${BME_HIDDEN_DIR}").
  * "${TF_PLUGIN_CACHE_DIR}" is now user-global instead of project-scoped.  That means Terraform plugins will be downloaded under ${BME_CONFIG_DIR} and you can delete them from under "${BME_PROJECT_DIR}/${BME_HIDDEN_DIR}".
* **terraform-support** module:
  * Both tfenv repository and *'TF_PLUGIN_CACHE_DIR'* environment variable are now per-user global instead of project-bound.
* **python3-virtualenvs** module:
  * *Virtualenvs* are now project-restricted instead of user-wide so there's no virtualenv name collisions among projects.
* New function __bme_load_env_file() to avoid code duplication.
* BUG CORRECTED: bme_eval_dir() didn't load project's root .bme_env file when reaching right into a project's subdirectory.

## v1.7.2 (2024-APR-20)
* differences from [previous tag](/../../compare/v1.7.1…v1.7.2).
* Tests:
  * Added [version-related unit tests](./tests/test_bme_version.sh).
  * Output [support functions](./tests/maketests.sh).
* **python3-virtualenvs** module: new environment variable *'BME_PYTHON_VERSION'* allows configuration for the Python binary used to build virtualenvs.

## v1.7.1 (2024-FEB-04)
* differences from [previous tag](/../../compare/v1.7.0…v1.7.1).
* Version comes now from [VERSION file](./VERSION).
* Added a minimal unit testing framework.
* Added .editorconfig file.
* python3-virtualenvs module: load_virtualenv() now accepts an optional param to use a requirements file to build a virtualenv.

## v1.7.0 (2023-OCT-20)
* differences from [previous tag](/../../compare/v1.6.1…v1.7.0).
* Added support for per-project modules.
* BUG CORRECTED: message erratum on githooks module.
* BUG CORRECTED: bme_eval_dir() loaded project root's .bme_env file twice.

## v1.6.1 (2023-OCT-07)
* differences from [previous tag](/../../compare/v1.6.0…v1.6.1).
* __bme_load_project() now runs in the directory it gets as param so it can properly load root's .bme_env file.

## v1.6.0 (2023-OCT-01)
* differences from [previous tag](/../../compare/v1.5.0…v1.6.0).
* New module: [githooks](./src/bash-magin-enviro_modules/githooks.module).

## v1.5.0 (2023-SEP-30)
* differences from [previous tag](/../../compare/v1.4.7-1…v1.5.0).
* *bme_env* at project's root always loaded, not only current dir's.
* CHANGELOG added.
* `make install` *"remembers"* where it was deployed so `make uninstall` can do the proper thing.

## Changelog started on version 1.5.0
