# TO-DO: bash-magic-enviro
Pending actions, general notes, etc. (in no particular order):
* Think of a less invassive development model.
* Automatic support for project root's '.bme.d/' directory '.gitignore' inclusion.
* Easy support for custom, per-project, modules.
* Find a way for modules to provide their own (formatted) help.
* **[python3-virtualenvs module](./src/bash-magic-enviro_modules/python3-virtualenvs.module):**
  * I think Python3 provides better virtualenv support than Phython2 so, maybe, virtualenvwrapper support is not needed anymore.  Consider this and act accordingly (See [Python3 doc](https://docs.python.org/3/library/venv.html)).
  * Consider making python *virtualenvs* project-restricted instead of user-wide.
* **[aws-support module](./src/bash-magic-enviro_modules/aws-support.module):**
  * Make the module not to require the *$AWS_MFA* environment variable, as it can be read from the proper AWS profile, or even not requested at all by means of *"bypassing"* its request right to aws-cli.
  * Add flexibility to authentication methods, so MFA is not mandatory.
  * Add flexibility to which the requested AWS profile should be used within a project.
* Easier/global management of whitelisting and projects' root directories.
* Auto white/blacklisting of subdirectories (i.e.: to make easy using BME on non-interactive sessions).
* **[terraform-support module](./src/bash-magic-enviro_modules/terraform-support.module):**
  * self-management of *.gitignore* entries for ~/bin/[terraform,tfvenv] symlinks.
  * Review [terraform-config-inspect](https://github.com/hashicorp/terraform-config-inspect), which allows to extract configurations from terraform.

## IN PROGRESS
