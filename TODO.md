# TO-DO: bash-magic-enviro
Pending actions, general notes, etc. (in no particular order):
* Automatic support for project root's '.bme.d/' directory '.gitignore' inclusion.
* Easier/global management of whitelisting and projects' root directories.
* Auto white/blacklisting of subdirectories (i.e.: to make easy using BME on non-interactive sessions).
* Dynamic load/unload of functions/variables that are only needed within a project environment.
* Per-directory clean function (on top of or instead of the global one?)
* Review the [bashlog project](https://github.com/Zordrak/bashlog).  Authored by the same person than tfenv, seems quite powerful.
* Allow for environment-related files (i.e.: *.bme_env.production*, *.bme_env.local-development*...; consider if this should work just for *.bme_env* files only or also for the main *.bme_project* file).
* Install dir shouldn't need to be in $PATH since we are not installing executable files.
* Install dependencies on known platforms.
* **Containers:**
  * publish docker container so it can be just used.
  * review how to add a *dockercompose.yml* or something to that end for easier macos development on Linux.
* **Makefile:**
  * `make install` may offer to tweak your environment for BME autoconfiguration.
  * Consider new target for checks prior to close a version, i.e.: VERSION, CHANGELOG, Dockerfile, tests... are properly updated, etc.
  * Consider new target to close version, i.e.: `git tag -a [version from VERSION file] -m...`
* dotfiles integration?
  * [stow](https://www.jakewiesler.com/blog/managing-dotfiles)
  * [bare git](https://www.atlassian.com/git/tutorials/dotfiles)
  * https://github.com/deadc0de6/dotdrop
* **Unit tests:**
  * More support functions to load/unload BME, etc.
  * Different environment loaded for different stages (i.e.: check/install process vs core vs modules)
* **BME version pinning:** both projects and modules should be able to declare a range of compatible BME versions.
* **Logging:**
  * log function should allow either positional or by-name parameters.
  * Ability to set logging levels (DEBUG|INFO|WARN|ERROR...) maybe on a scoped level (global vs project vs module-level)
  * Log to either STDOUT or STDERR (maybe two different logging functions)
  * Ability to log to file (possibly on top of console).  Also, file logging level may or may not be tied to console log level.
* **Documentation:**
  * Document upgrade process explicitly (with highlighted mention to *UPGRADE NOTES*^).
  * Document support expectations.
* **Modules:**
  * Allow to put them in subdirectories
    * **WORKAROUND:** within the module itself, calculate its base dir and then source relative to it (already successfully tested on a private module).
  * Heavy refactor: `modulename [load|unload|version|help]`
  * Find a way for modules to provide their own (formatted) help.
  * More flexible searching process for modules.  From higher to lower priority:
    1. on the project's *bme-modules* dir.
    2. on the global *modules* dir.
    3. wherever in $PATH.
  * **[aws-support module](./src/bash-magic-enviro_modules/aws-support.module):**
    * Make the module not to require the *$AWS_MFA* environment variable, as it can be read from the proper AWS profile, or even not requested at all by means of *"bypassing"* its request right to aws-cli.
    * Add flexibility to authentication methods, so MFA is not mandatory.
    * Add flexibility to which the requested AWS profile should be used within a project.
  * **[terraform-support module](./src/bash-magic-enviro_modules/terraform-support.module):**
    * self-management of *.gitignore* entries for ~/bin/[terraform,tfvenv] symlinks.
    * Review [terraform-config-inspect](https://github.com/hashicorp/terraform-config-inspect), which allows to extract configurations from terraform.

## IN PROGRESS
1. **unit tests:** different environment loaded for different stages (i.e.: check/install process vs core vs modules)
