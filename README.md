Bash Magic Enviro
=================

An opinionated Bash configuration tool for development environments.

This tool allows to set *"isolated"* per-project Bash environments.

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
1. [Development](#development)
   * [modules' development](#dev-modules)
1. [License](#license)

----

## Requirements<a name="requirements"></a>
* **[Bash](https://www.gnu.org/software/bash/) >= 5**.  Make sure you are using a full Bash shell.
* **[GNU make](https://www.gnu.org/software/make/) >= 4.2**. Used by this tool's install process.

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

In order for this main *.bme_env* to be sourced, you need to first *"stop"* by your project's root directory **before** entering any other subdirectory (i.e.: `cd ~/REPOS/project_directory && cd some_subir`).

Once you move *"above"* the project's root dir (i.e.: `cd ~`) the project's environment will be automatically cleaned.

See also the included [example project](./example-project).

*Bash Magic Enviro* can also add project-related configuration on its own (i.e.: local configurations, supporting tools' repositories, etc.).  This tool reserves the *'.bme.d/'* directory for those, and it will create it upon entering the project's dir if it doesn't exist, so you should add it to your project's *'.gitignore'* file, i.e.:
```shell
# This is the project's main '.gitignore' file

# Bash Magic Enviro related
.bme.d/
```

<sub>[back to contents](#contents).</sub>

## Available features and modules<a name="modules"></a>
Features are always active and can't be turned off.

Modules are *"turned off"* by default, but you can *"turn on"* those you need (see [example environment file](./docs/bme_env.example)).  On top of this README, you can also check your *~/bin/bash-magic-enviro_modules/* dir: each file within has the exact name of one module you can activate.

### logging function<a name="log"></a>
**Feature** (always on).  A function named **bme_log** is exported which accepts three (positional) params:
1. **log message [mandatory]:** the log message itself.  It accepts colored output (see [below](#colors)).
1. **log type [optional]:** the type of log, i.e.: *warning*, *info*...  It is represented as a colored uppercase prefix to the message.  As of now, you need to look at [the *switch/case* statement on the bme_log() method](./src/bash-magic-enviro).
1. **log level [optional]:** when set, it indents your message by as many *tabs* as the number you pass (defaults *0*, no indentation).

**example:** `bme_log "Some info. ${C_BOLD}'this is BOLD'${C_NC} and this message will be indented once." info 1`

### colored output<a name="colors"></a>
**Feature** (always on).  Constants are exported that can help you rendering colored outputs (see the *"style table"* early on [the bash-magic-enviro file](./src/bash-magic-enviro)).  They can be used within your *.enviro* files with the help of *"-e*" echo's option.  I.e.:
```bash
echo -e "${C_RED}This is BOLD RED${C_NC}"
echo -e "Bold follows: '${C_BOLD}BOLD${C_NC}'"
```
...remember always resetting color option with the `${C_NC}` constant after use.

### custom clean function<a name="custom_clean"></a>
**Feature** (always on).  While *Bash Magic Enviro* will take care of cleaning all its customizations when you go out your project's filesystem, you can also define/export your own custom variables, Bash functions, etc. within your project scope, and *Bash magic enviro* will offer the chance to clean after you.

For this to happen you should declare a *custom clean function* named **bme_custom_clean()** and it will be called **before** any other cleansing (see [example config](./docs/bme_env.example)).

Once *bme_custom_clean* is run, it will also be *unset* to avoid cluttering your environment.

### look for new *Bash Magic Enviro* versions<a name="check-versions"></a>
**[check-version module](./src/bash-magic-enviro_modules/check-version.module):** exports the **check-version (no params) function**, which compares your current *Bash Magic Enviro's* version against the higest version available, defined as *git tags* at your *git remote*.  Shows a message about current version status.

**NOTES:**
1. When this module is requested, it will show *check-version's* result at project activation (i.e.: when you `cd` into your project's root dir).
1. Version comparation is very crude and limits itself to show differences between *local* and *remote* versions.  Use your own judgement when considering an upgrade.

### project's bin dir<a name="bindir"></a>
**[bindir module](./src/bash-magic-enviro_modules/bindir.module):** the *bin/* dir relative to the project's root will be added to $PATH, so custom script helpers, binaries, etc. are automatically available to the environment.

**NOTE:** if *bindir* is requested but the directory doesn't exists, this module will create it on the fly.

## Development<a name="development"></a>
There's a `make dev` target on [the Makefile](./Makefile), that creates *symbolic links* under *~/bin* from source code.  This way, you can develop new features with ease.

**NOTE:** remember you need to re-run `make dev` each time you alter either the [Makefile](.Makefile) or [bash-magic-enviro](./src/bash-magic-enviro) files.

### modules' development<a name="dev-modules"></a>
*Modules* are the way to add new functionality to *Bash Magic Enviro*.  Any file named *[modulename].module* under the [bash-magic-enviro_modules/ directory](./src/bash-magic-enviro_modules) becomes a module by that name.

*Modules* are loaded by including their *modulename* in the **BME_MODULES array** of your *"main"* project's *.bme_env* file (see [example](./docs/bme_env.example)).  Upon entering your project's root directory, the file represented by the module name is first sourced and then its *[modulename]_load* method is called with no parameters.

When you `cd` out your project's space, all modules are unloaded by calling their *[modulename]_unload* method without parameters.

This means that, at the very minimum, every module needs to define these two methods: *[modulename]_load* and *[modulename]_unload*:
1. **[modulename]_load:** it should run any preparation the module may need, i.e.: exporting new environment variables, check for the presence or pre-requirements, etc.
1. **[modulename]_unload:** it should clean any modification to the shell the module introduces.  A good test while developing a new module can be running `set > before.txt` and `set > after.txt` when loading/unloading the module and check the *diff* between both files: there should be no *diff*.

Other than that, anything that can be *sourced* by Bash can be added to the module's file, since that's exactly what will happen (the file is *sourced* when the module is requested).

<sub>[back to contents](#contents).</sub>

----

### License<a name="license"></a>
*Bash Magic Enviro* is made available under the terms of the **GPLv3**.

See the [license file](./LICENSE) that accompanies this distribution for the full text of the license.

<sub>[back to contents](#contents).</sub>
