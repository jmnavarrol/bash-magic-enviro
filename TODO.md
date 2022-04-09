# TO-DO: bash-magic-enviro
Pending actions, general notes, etc. (in no particular order):
* Add a *"support"* section.
* Think of a less invassive development model.
* Control *whitelisting* at the project-level directory, so projects can be easily blacklisted even within another project's hierarchy.
* Automatic support for project root's '.bme.d/' directory '.gitignore' inclusion.
* Easy support for custom, per-project, modules.
* Find a way for modules to provide their own (formatted) help.
* **[python3-virtualenvs module](./src/bash-magic-enviro_modules/python3-virtualenvs.module):** I think Phyton3 provides better virtualenv support than Phython2 so, maybe, virtualenvwrapper support is not needed anymore.  Consider this and act accordingly.
* **[aws-support module](./src/bash-magic-enviro_modules/aws-suport.module):**
  * Make the module not to require the *$AWS_MFA* environment variable, as it can be read from the proper AWS profile, or even not requested at all by means of *"bypassing"* its request right to aws-cli.
  * Add flexibility to authentication methods, so MFA is not mandatory.
  * Add flexibility to which the requested AWS profile should be used within a project.

## IN PROGRESS
