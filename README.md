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
1. [Available modules](#modules)
   * [colored output](#colors)
   * [load project's bin dir](#bindir)
1. [Development](#development)
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

<sub>[back to contents](#contents).</sub>

## Available modules<a name="modules"></a>
Modules are *"turned off"* by default, but you can *"turn on"* those you need (see [example environment file file](./docs/bme_env.example)).  On top of this README, you can also check your *~/bin/bash-magic-enviro_modules/* dir: each file within has the exact name of one option you can activate.

### colored output<a name="colors"></a>
**No option** (always on).  Constants are exported that can help you rendering colored outputs (see the *"style table"* early on [the bash-magic-enviro file](./src/bash-magic-enviro)).  They can be used within your *.enviro* files with the help of *"-e*" echo's option.  I.e.:
```bash
echo -e "${C_RED}This is BOLD RED${C_NC}"
echo -e "Bold follows: '${C_BOLD}BOLD${C_NC}'"
```
...remember always resetting color option with the `${C_NC}` constant after use.

### project's bin dir<a name="bindir"></a>
Option **bindir**.  The *bin/* dir relative to the project's root will be added to $PATH, so custom script helpers, binaries, etc. are automatically available to the environment.

**NOTE:** if *bindir* is requested but the directory doesn't exists, this module will create it on the fly.

## Development<a name="development"></a>
There's a `make dev` target on [the Makefile](./Makefile), that creates *symbolic links* under *~/bin* from source code.  This way, you can develop new features with ease.

<sub>[back to contents](#contents).</sub>

----

### License<a name="license"></a>
*Bash Magic Enviro* is made available under the terms of the **GPLv3**.

See the [license file](./LICENSE) that accompanies this distribution for the full text of the license.

<sub>[back to contents](#contents).</sub>
