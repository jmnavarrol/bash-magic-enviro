# TO-DO: bash-magic-enviro
Pending actions, general notes, etc. (in no particular order):
* publish docker container so it can be just used.
* Automatic support for project root's '.bme.d/' directory '.gitignore' inclusion.
* Find a way for modules to provide their own (formatted) help.
* Easier/global management of whitelisting and projects' root directories.
* Auto white/blacklisting of subdirectories (i.e.: to make easy using BME on non-interactive sessions).
* Dynamic load/unload of functions/variables that are only needed within a project environment.
* Per-directory clean function (on top of or instead of the global one?)
* Review the [bashlog project](https://github.com/Zordrak/bashlog).  Authored by the same person than tfenv, seems quite powerful.
* Helper function to indent lines (for proper log formatting)
* Allow for environment-related files (i.e.: *.bme_env.production*, *.bme_env.local-development*...; consider if this should work just for *.bme_env* files only or also for the main *.bme_project* file).
* Install dir shouldn't need to be in $PATH since we are not installing executable files.
* **Makefile:**
  * `make install` may offer to tweak your environment for BME autoconfiguration.
  * Consider new target for checks prior to close a version, i.e.: VERSION, CHANGELOG, Dockerfile, tests... are properly updated, etc.
  * Consider new target to close version, i.e.: `git tag -a [version from VERSION file] -m...`
* dotfiles integration?
  * [stow](https://www.jakewiesler.com/blog/managing-dotfiles)
  * [bare git](https://www.atlassian.com/git/tutorials/dotfiles)
  * https://github.com/deadc0de6/dotdrop
* **Modules:**
  * Allow to put them in subdirectories
  * Heavy refactor: `modulename [load|unload|version|help]`
* **[aws-support module](./src/bash-magic-enviro_modules/aws-support.module):**
  * Make the module not to require the *$AWS_MFA* environment variable, as it can be read from the proper AWS profile, or even not requested at all by means of *"bypassing"* its request right to aws-cli.
  * Add flexibility to authentication methods, so MFA is not mandatory.
  * Add flexibility to which the requested AWS profile should be used within a project.
* **[terraform-support module](./src/bash-magic-enviro_modules/terraform-support.module):**
  * self-management of *.gitignore* entries for ~/bin/[terraform,tfvenv] symlinks.
  * Review [terraform-config-inspect](https://github.com/hashicorp/terraform-config-inspect), which allows to extract configurations from terraform.
* **Unit tests:**
  * More support functions to load/unload BME, etc.

## IN PROGRESS
