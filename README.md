Bash Magic Enviro
=================

**An opinionated Bash configuration tool for development environments.**

This tool allows to set *"isolated"* per-project Bash environments.

Once installed and configured, this tool will look for a *'.bme_env'* file each time you change directories, and will *"source"* them when found.  
You *"declare"* a project by means of the *.bme_env* file at its topmost directory (the expectation, but not a hard requirement, is that a project's entry point is the root of a git sandbox).  This topmost file sets the project's name, the modules you want to be loaded for this project, etc.  
Aditional *.bme_env* files within the project's directory hierarchy may call exported functions, tweak the environment for that given directory, etc. (i.e.: you may load a virtualenv, request a custom Terraform version, even run whatever Bash code you may need).  
This tool also allows you to add your own project-specific extensions/customizations as needed.

Once you *"cd out"* from the project's hierarchy all these customizations will be automatically cleaned out.

**Contents:**<a name="contents"></a>
1. [Requirements](#requirements)
1. [Install](#install)
   1. [update your Bash prompt](#prompt)
   1. [install Bash Magic Enviro](#install)
   1. [set your project's *"main"* *.bme_env* file](#project)
1. [Available features and modules](#modules)
   * [logging function](#log)
   * [colored output](#colors)
   * [custom clean function](#custom_clean)
   * [look for new *Bash Magic Enviro* versions](#check-versions)
   * [load project's bin dir](#bindir)
   * [load Python3 *virtualenvs*](#virtualenvs)
   * [Terraform support](#terraform)
1. [Development](#development)
   * [modules' development](#dev-modules)
1. [License](#license)

----

## Requirements<a name="requirements"></a>
* **[Git](https://git-scm.com/)**. Needed to checkout this project and some other features.
* **[Bash](https://www.gnu.org/software/bash/) >= 5**.  Make sure you are using a full Bash shell.
* **[GNU make](https://www.gnu.org/software/make/) >= 4.2**. Used by this tool's install process.
* **Internet connectivity:** Some features and modules may access Internet at run time (i.e.: *check-version*, *terraform-support*...).
* See each module's requirements section for other dependencies.

<sub>[back to contents](#contents).</sub>

## Install<a name="install"></a>
First of all clone this repository, then follow the steps below.

### update your Bash prompt<a name="prompt"></a>
This tool works by altering your Bash prompt so it can process (source) files it finds each time you traverse a directory on the console.  For this to happen, you need to source *Bash Magic Enviro's* main file (*'bash-magic-enviro'*) and then make your *"prompt command"* to run its main function (*'bme_eval_dir'*) each time you `cd` into a new directory.
1. Create your own *~/bash_includes* file using [this 'bash_includes.example'](./docs/bash_includes.example) as reference.  It provides two features:
   1. It adds your `~/bin` directory (if it exists) to your $PATH.  This way, the helper functions provided by this repository can be found and eventually loaded (of course, if you already added `~/bin` to your $PATH by other means, you won't need to do it here again).
   1. The critical part: it alters your Bash prompt exporting the **bme_eval_dir** function, which is the one that makes possible looking for *.bme_env* files.  
You can/should also use your *~/bash_includes* file to export your personal project-related variables, like *secrets*, *tokens* and other data that shouldn't be checked-in to source code management systems (make sure you protect this file with restrictive permissions).
1. Add to the end of your `~/.bashrc` file (or whatever other file you know it gets processed/sourced at login):
   ```bash
   # Other includes
   if [ -f ~/bash_includes ]; then
   	. ~/bash_includes
   fi
   ```

Once you open a new terminal, changes will be loaded.

<sub>[back to contents](#contents).</sub>

### install Bash Magic Enviro<a name="prompt"></a>
Use [the included Makefile](./Makefile).  See the output of the bare `make` command for available targets.
* `make check`, as the name implies, runs some tests trying to insure required dependencies are in place.
* `make install`, installs Bash Magic Enviro into your personal *~/bin/* directory.  This means that *~/bin/* must be in your *$PATH* (see section [*"Update your Bash prompt"*](#prompt) above).
* `make uninstall` deletes this code from your *~/bin/* dir.

<sub>[back to contents](#contents).</sub>

### set your project's *"main"* *.bme_env* file<a name="project"></a>
Once you properly installed *Bash Magic Enviro*, you may add to your project(s) a *"main"* *.bme_env* file to activate and configure the environment (see [example](./docs/bme_env.example)).

In order for this main *.bme_env* to be sourced, you need to first *"stop"* by your project's root directory **before** entering any other subdirectory (i.e.: `~$: cd ~/REPOS/project_directory ~$: cd some_subir`).

Once you move *"above"* the project's root dir (i.e.: `cd ~`) the project's environment will be automatically cleaned.

See also the included [example project](./example-project).

*Bash Magic Enviro* can also add project-related configuration on its own (i.e.: local configurations, supporting tools' repositories, etc.).  This tool reserves the *'.bme.d/'* directory under your project's root for those, and it will create it upon entering the project's dir if it doesn't exist, so you should add it to your project's *'.gitignore'* file, i.e.:
```shell
# This is the project's main '.gitignore' file

# Bash Magic Enviro related
.bme.d/
```

<sub>[back to contents](#contents).</sub>

## Available features and modules<a name="modules"></a>
Features are always active and can't be turned off.

Modules are *"turned off"* by default, but you can *"turn on"* those you need (see [example environment file](./docs/bme_env.example)).  On top of this README, you can also check your *~/bin/bash-magic-enviro_modules/* dir: each file within has the exact name of one module you can activate.

As you may note, modules are loaded/unloaded by means of a Bash array.  As such, sorting order matters (i.e.: *'terraform-support'* depends on *'bindir'* which means *'bindir'* must be listed **before** *'terraform-support'*).

### logging function<a name="log"></a>
**Feature** (always on).  A function named **bme_log** is exported which accepts three (positional) params:
1. **log message [mandatory]:** the log message itself.  It accepts colored output (see [below](#colors)).
1. **log type [optional]:** the type of log, i.e.: *warning*, *info*...  It is represented as a colored uppercase prefix to the message.  As of now, you need to look at [the *switch/case* statement on the bme_log() method](./src/bash-magic-enviro).
1. **log level [optional]:** when set, it indents your message by as many *tabs* as the number you pass (defaults *0*, no indentation).

**example:** `bme_log "Some info. ${C_BOLD}'this is BOLD'${C_NC} and this message will be indented once." info 1`

### colored output<a name="colors"></a>
**Feature** (always on).  Constants are exported that can help you rendering colored outputs (see the *"style table"* early on [the bash-magic-enviro file](./src/bash-magic-enviro)).  They can be used within your *.enviro* files with the help of either [bme_log](#log) or *"-e*" echo's option.  I.e.:
```bash
echo -e "${C_RED}This is BOLD RED${C_NC}"
echo -e "Bold follows: ${C_BOLD}'BOLD'${C_NC}"
```
...remember always resetting color option with the `${C_NC}` constant after use.

### custom clean function<a name="custom_clean"></a>
**Feature** (always on).  While *Bash Magic Enviro* will take care of cleaning all its customizations when you go out your project's filesystem, you may also define/export your own custom variables, Bash functions, etc. within your project scope, and *Bash magic enviro* will offer the chance to clean after you.

For this to happen you should declare a *custom clean function* named **bme_custom_clean()** (no params) and it will be called **before** any other cleansing (see [example config](./docs/bme_env.example)).

Once *bme_custom_clean* is run, it will also be *unset* to avoid cluttering your environment.

### look for new *Bash Magic Enviro* versions<a name="check-versions"></a>
**[check-version module](./src/bash-magic-enviro_modules/check-version.module):** as the name implies, helps you noticing if your current *Bash Magic Enviro* version is up to date.

**Requirements:**
* git command
* Internet connectivity

**Functions:**
* **check-version (no params):** it compares your current *Bash Magic Enviro's* version against the highest version available, defined as *git tags* at your *git remote*.  Shows a message about current version status.

**NOTES:**
1. When this module is requested, it will show *check-version's* result at project activation (i.e.: when you `cd` into your project's root dir).
1. Version comparation is very crude and limits itself to show differences between *local* and *remote* versions.  Use your own judgement when considering an upgrade.

### project's bin dir<a name="bindir"></a>
**[bindir module](./src/bash-magic-enviro_modules/bindir.module):** the *bin/* dir relative to the project's root will be added to $PATH, so custom script helpers, binaries, etc. are automatically available to the environment.

**NOTE:** if *bindir* is requested but the directory doesn't exists, this module will create it on the fly.

### load Python3 *virtualenvs*<a name="virtualenvs"></a>
**[python3-virtualenvs module](./src/bash-magic-enviro_modules/python3-virtualenvs.module):** Manages *Python3 virtualenvs* using your system Python version (this module looks first for `python3 --version` output; if it doesn't find it, it also tries `python --version`, in case it defaults to >=3.  
It requires [virtualenvwrapper](https://virtualenvwrapper.readthedocs.io/) to be installed (i.e.: `sudo apt install virtualenvwrapper`).  Remember that, in order to *"activate"* virtualenvwrapper, you need to source its Bash control script, *virtualenvwrapper.sh* within your environment.  An example has been added to [the bash_includes example](./docs/bash_includes.example). Make sure you set the the script's path accordingly to your system.

See also [the included example](./example-project/virtualenv-example/.bme_env).

**Requirements:**
* Python 3.
* [virtualenvwrapper](https://virtualenvwrapper.readthedocs.io/).
* md5sum (it comes from package **coreutils** in the case of Debian systems).

**Functions:**
* **load_virtualenv [virtualenv]:** loads, with the help of *virtualenvwrapper*, the requested virtualenv *[virtualenv]* if it exists (`workon [virtualenv]`).
  1. If the function can't find the requested virtualenv *[virtualenv]*, it will look for the requirements file *"${PROJECT_DIR}/python-virtualenvs/[virtualenv].requirements"* and will create the named *virtualenv* using it.
  1. If the requirements file can't be found, it will create an *"empty"* virtualenv *[virtualenv]*, along with an empty *requirements* file, so you can start installing packages on it.
  1. If *pip* is listed in the *requirements* file, and given the requirements' file format is quite sensible about the exact version of *pip* in use, *load_virtualenv* will try to honor your requested pip version before installing the remaining packages into the virtualenv.
  1. This function also stores the requirements file's *md5sum* under the *'.bme.d/'* hidden directory, so it can update the virtualenv when changes are detected.

The expectation is that you will install whatever required pips within your virtualenv and, once satisfied with the results, you'll "dump" its contents to the requirements file, i.e.: `pip freeze > ${PROJECT_DIR}/python-virtualenvs/[virtualenv].requirements`.

### Terraform support<a name="terraform"></a>
**[terraform-support module](./src/bash-magic-enviro_modules/terraform-support.module):** Adds support for [Terraform](https://www.terraform.io/intro/index.html) development.  It peruses [the tfenv project](https://github.com/tfutils/tfenv/tree/v2.2.0) to allow using different per-project Terraform versions, suited to your hardware.

For this to happen, *Bash Magic Enviro* clones [the tfenv repository](https://github.com/tfutils/tfenv/tree/v2.2.0) to the *.bme.d/tfenv/* subdirectory relative to your project's root and configures it for usage within your project scope, so make sure you add `.bme.d/` to your `.gitignore` file (an error will be thrown otherwise).

Once *tfenv* is (automatically) configured for your project, you can normally use any suitable terraform or [tfenv command](https://github.com/tfutils/tfenv/tree/v2.2.0#usage).

You can globably set your project's Terraform version by means of the **'TFENV_TERRAFORM_VERSION'** environment variable defined on your project's main *.bme_env file* (See [example project](./example-project/.bme_env)).  This variable is unset when you go outside the project's directory tree along *Bash Magic Enviro*'s cleaning process.

This module also sets the **'TF_PLUGIN_CACHE_DIR'** environment variable pointing to the *.bme.d/.terraform.d/plugin-cache/* directory relative to your project's root, so plugins can be reused within different Terraform plans in your project (also unset at project exit).

**Requirements:**
* **[bindir module](#bindir)** to be listed **before** *terraform-support*.
* git command
* Internet connectivity

## Development<a name="development"></a>
There's a `make dev` target on [the Makefile](./Makefile), that creates *symbolic links* under *~/bin* from source code.  This way, you can develop new features with ease.

**NOTE:** remember you need to re-run `make dev` each time you alter either the [Makefile](.Makefile) or [bash-magic-enviro](./src/bash-magic-enviro) files.

### modules' development<a name="dev-modules"></a>
*Modules* are the way to add new functionality to *Bash Magic Enviro*.  Any file named *[modulename].module* under the [bash-magic-enviro_modules/ directory](./src/bash-magic-enviro_modules) becomes a module by that name.

*Modules* are loaded by including their *modulename* in the **BME_MODULES array** of your *"main"* project's *.bme_env* file (see [example](./docs/bme_env.example)).  Upon entering your project's root directory, the file represented by the module name is first sourced and then its *[modulename]_load* function is called with no parameters.

When you `cd` out of your project's space, all modules are unloaded by calling their *[modulename]_unload* function without parameters.

This means that, at the very minimum, every module needs to define these two functions: *[modulename]_load* and *[modulename]_unload*:
1. **[modulename]_load:** it should run any preparation the module may need, i.e.: exporting new environment variables, check for the presence of pre-requirements, etc.  
   It is expected that, in case of problems running *[modulename]_load*, your module cleans after itself before returning, i.e.:
   ```bash
   [modulename]_load() {
     local unmet_dependencies=false  # true and false are defined in the global bash-magic-enviro file
     [...]
     if ! something_that_fails; then
       unmet_dependencies=true
       bme_log "${C_BOLD}'something_that_fails'${C_NC} failed.  Try so-and-so to recover." error 1
     fi
     [...]
     if ($unmet_dependencies); then
       [modulename]_unload
       bme_log "${C_BOLD}'[modulename]'${C_NC} not loaded. See missed dependencies above." error 1
       return -1
     else
       bme_log "${C_BOLD}'[modulename]'${C_NC} loaded." info 1
     fi
   }

   ```
   You can also look at [other modules](./src/bash-magic-enviro_modules/) to get some inspiration.
1. **[modulename]_unload:** it should clean any modification to the shell the module introduces.  A good test while developing a new module can be running `set > before.txt` and `set > after.txt` when loading/unloading the module and check the *diff* between both files: there should be no *diff*.

Other than that, anything that can be *sourced* by Bash can be added to the module's file, since that's exactly what will happen (the file is *sourced* when the module is requested).

<sub>[back to contents](#contents).</sub>

----

### License<a name="license"></a>
*Bash Magic Enviro* is made available under the terms of the **GPLv3**.

See the [license file](./LICENSE) that accompanies this distribution for the full text of the license.

<sub>[back to contents](#contents).</sub>
