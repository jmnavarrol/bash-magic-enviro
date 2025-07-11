Bash Magic Enviro
=================

**An opinionated Bash configuration tool for development environments.**

This tool allows you to set isolated and configurable *"Bash environments"* (*"projects"*).

Once installed and configured, BME will look for a file named **'.bme_project'** each time you change directories in the console for a *"BME project definition"*, which will be *sourced* when found.  
Once within a *"BME project"* context, it will also look for a file named **'.bme_env'** at each subdirectory to customize your environment as per its contents, which will also be sourced.

BME abilities are extended by means of *"BME modules"* either global or project-level.

So, in brief:
1. You *"declare"* a project by means of its *[.bme_project](./example-project/.bme_project)* file at its topmost directory (the expectation, but not a hard requirement, is that a project's entry point is the root of a *git sandbox*).  This topmost file sets the project's name, the [BME modules](#modules) you want to be loaded, etc.
1. Project behaviour is attained by the contents of your *bme files* and the global or local *BME modules* loaded.
1. Aditional *[.bme_env](./example-project/.bme_env)* files within the project's directory hierarchy may call exported functions, tweak the environment for that given directory, etc. (i.e.: you may [load a Python virtualenv](./example-project/virtualenv-example/.bme_env), [request a custom Terraform version](./example-project/terraform-example/.bme_env), even run whatever Bash code you may need).
1. Once you *"cd out"* from the project's directory hierarchy all these customizations will be automatically cleaned out.

**Quick start:**
1. clone this repository (preferably to its latest [tag](https://github.com/jmnavarrol/bash-magic-enviro/tags), i.e.: `git clone --branch v1.10.1 https://github.com/jmnavarrol/bash-magic-enviro.git`)
1. `cd` into the cloned sandbox and run `make install`.  Review and install dependencies as instructed.
1. edit your *~/.bashrc* file adding to its end the following snippet:
   ```bash
   export PROMPT_COMMAND=bme_eval_dir
   ```
1. open a new bash console, `cd` into the [bash-magic-enviro/example-project/](./example-project/) subdirectory.  Follow instructions.
1. within this new console, `cd` into the *-example* subdirectories for a hint of various BME modules' features.

Now you can read these full instructions so you can manage your own BME projects.

----
**Contents:**<a name="contents"></a>
1. [Requirements](#requirements)
1. [Security](#security)
1. [Install](#install)
   1. [install Bash Magic Enviro](#make_install)
   1. [update your Bash prompt](#prompt)
   1. [configure your project(s)](#project)
   1. [CHANGELOG](./CHANGELOG.md)
1. [BME docker container](#docker-container)
1. [Available features](#features)<a name="feature_list"></a>
   * [jumping among projects](#jumping_projects)
   * [directory whitelisting](#whitelisting)
   * [logging](#log)
   * [colored output](#colors)
   * [custom clean function](#custom_clean)
   * [*Bash Magic Enviro* version checking](#check-versions)
   * [Per-project custom modules](#custom-modules)
1. [Available modules](#modules)<a name="module_list"></a>
   * [load project's bin dir](#bindir)
   * [load Python3 *virtualenvs*](#virtualenvs)
   * [AWS support](#aws)
   * [git client-side hooks support](#githooks)
   * [Terraform support](#terraform)
1. [Development](#development)
   * [modules' development](#dev-modules)
   * [unit tests](#unit-tests)
1. [Support](#support)
1. [License](#license)
----

## Requirements<a name="requirements"></a>
* **[Git](https://git-scm.com/) >= 2.9**. Needed to checkout this project and some other features.
* **[Bash](https://www.gnu.org/software/bash/) >= 4**.  Make sure you are using a full Bash shell.
* **[GNU make](https://www.gnu.org/software/make/) >= 4.2**. Used by this tool's install process.
* **Internet connectivity:** Some features and modules may access Internet at run time (i.e.: *check-version*, *terraform-support*...).
* See each module's requirements section for other dependencies.

**NOTE FOR macOS users:** this project depends heavily on GNU/GPL tooling (Bash itself, but also basic utilities like find, sed, grep...) while BSD versions are installed on this platform.  It is suggested the use of [homebrew](https://brew.sh/) to install the proper dependencies (see [macOS' README](./docs/macos.md) for further details).

<sub>[back to contents](#contents).</sub>

## Security<a name="security"></a>
**A WORD OF CAUTION:** Remember your are sourcing pure Bash code within all those *'.bme_project'* and *'.bme_env'* files, so whatever that can be programmed **will** be run at your privilege level (including *sudo* commands, i.e.: `sudo rm -rf /`).  This means you are just a `cd` away from starting a Global Nuclear War or, at the very least, to happily sweep out your full home directory.

Make sure you review the *'.bme_project'* and *'.bme_env'* files you are going to source **BEFORE** entering a directory for first time.

**YOU'VE BEEN WARNED!!!**

In order to slightly protect you, BME will ask for your permission the first time it finds a *.bme_\** file in a directory.  If you **reject** access, no *.bme_\** files will be sourced within the directory hierarchy for a project.  If you **accept**, *.bme_\** files within that project's root **and all its subdirectories** will be *sourced* when found.

Your answer will be stored at **~/.bme.d/whitelistedpaths** in the form of a Bash associative array, which will also be exported to an environment variable.  You can edit this file, but be aware that the contents in memory will remain for as long as your console session, and they will be overwritten if new changes are requested.

See also the [*'whitelisting'* feature's section](#whitelisting).

<sub>[back to contents](#contents).</sub>

## Install<a name="install"></a>
First of all clone [this repository](https://github.com/jmnavarrol/bash-magic-enviro), then follow the steps below.

Optionally, you may checkout a version tag so you can control what to upgrade to with more finesse:
```bash
~/REPOS$ git clone --branch v1.4.7 https://github.com/jmnavarrol/bash-magic-enviro.git
Cloning into 'bash-magic-enviro'...
remote: Enumerating objects: 735, done.
remote: Counting objects: 100% (294/294), done.
remote: Compressing objects: 100% (137/137), done.
remote: Total 735 (delta 197), reused 238 (delta 153), pack-reused 441
Receiving objects: 100% (735/735), 156.81 KiB | 1.89 MiB/s, done.
Resolving deltas: 100% (422/422), done.
Note: switching to '2c9c025764fab97eee55ca053596463b27239857'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

~/REPOS$ cd bash-magic-enviro
~/REPOS/bash-magic-enviro$
```
Later, when you are ready to upgrade, you may checkout a newer tag and reinstall:
```bash
~/REPOS/bash-magic-enviro$ git checkout v1.4.7-1
Previous HEAD position was 2c9c025 New BME helper container added and documented.
HEAD is now at 6661389 Version bumped: 1.4.7-1
```
```bash
~/REPOS/bash-magic-enviro$ make install
Building BME modules...
        installing module 'src/bash-magic-enviro_modules/aws-support.module'
        installing module 'src/bash-magic-enviro_modules/bindir.module'
        installing module 'src/bash-magic-enviro_modules/githooks.module'
        installing module 'src/bash-magic-enviro_modules/python3-virtualenvs.module'
        installing module 'src/bash-magic-enviro_modules/python3-virtualenvs.old.module'
        installing module 'src/bash-magic-enviro_modules/terraform-support.module'
Building BME modules: DONE!
Building BME: DONE!
Checking requirements...
* Bash version 5.2.15(1)-release: OK
* '~/bin' is in PATH: OK
* Git version 2.39.5: OK
* Python 3.11.2: OK
* Python virtualenv management: OK
* 'md5sum' found: OK
* 'flock' found: OK
* 'jq' found: OK

ALL CHECKS: PASSED.
Checking requirements: DONE!
Installing BME to '~/bin'...
Installing BME: DONE
~/REPOS/bash-magic-enviro$
```
See also [CHANGELOG](./CHANGELOG.md).

<sub>[back to contents](#contents).</sub>

### install Bash Magic Enviro<a name="make_install"></a>
Use [the included Makefile](./Makefile).  See the output of the bare `make` command for available targets.
* `make check`, as the name implies, runs some tests trying to insure required dependencies are in place.
* `make install`, installs Bash Magic Enviro.  It defaults to your personal *~/bin/* directory.  This means that *~/bin/* must be in your *$PATH* (see section [*"Update your Bash prompt"*](#prompt) below).
* `make uninstall` deletes this code from your install path.
  
**NOTES:**
* `make check` is implicitly run before `make install` so you should honor BME's mandatory requirements before succesfully installing it.  
  Pay attention to make's output for errors and hints on how to correct them.
* You can also install/uninstall BME to a path other than your personal *~/bin/* directory with the help of the **DESTDIR** variable, i.e.:  
  `make DESTDIR=/opt/bme install`  
  In this case, you need write permission to the target directory and you should also add *DESTDIR* to the relevant environment PATH (i.e.: system global).  
  Note that it is **highly discouraged** to install BME globally.  While it might make sense a global setup on some scenarios, like a shared container for demonstration purposes or as a helper development tool, carefully pay attention to the [security considerations](#security) anyway.
* `make uninstall` will *"remember"* the previous `make install` and `make dev` paths (either their defaults or the ones explicitly set by *DESTDIR*).  You can also add an extra path to uninstall, i.e. `make DESTDIR=/another/path uninstall`.

<sub>[back to contents](#contents).</sub>

### update your Bash prompt<a name="prompt"></a>
This tool works by altering your Bash prompt so it can process files it finds each time you traverse a directory on the console (by means of Bash' source function).

For this to happen, you need to source *Bash Magic Enviro's* main file ([*'bash-magic-enviro'*](./src/bash-magic-enviro)) and then make your *"prompt command"* to run its main function ([*'bme_eval_dir()'*](https://github.com/jmnavarrol/bash-magic-enviro/blob/24b6de1f364c0b25a5082bd33408a566df8cf76d/src/bash-magic-enviro#L34)) each time you `cd` into a new directory.
1. Create your own *~/bme_includes* file using [this 'bme_includes.example'](./docs/bme_includes.example) as reference.  It provides two features:
   1. It adds your `~/bin` directory (if it exists) to your $PATH.  This way, the helper functions provided by this repository can be found and eventually loaded (of course, if you already added `~/bin` to your $PATH by other means, you won't need to do it here again).
   1. The critical part: it sources the main *bash-magic-enviro* file and alters your Bash prompt so it runs the **bme_eval_dir()** function each time your change directories, which is the one that makes possible looking for (and eventually sourcing) *.bme_\** files.  
You can/should also use your *~/bme_includes* file to export your personal project-related variables, like *secrets*, *tokens* and other data that shouldn't be checked-in to source code management systems (make sure you protect this file with restrictive permissions).
1. Add to the end of your `~/.bashrc` file (or whatever other file you know it gets processed/sourced at interactive login sessions):
   ```bash
   # Other includes
   if [ -r ~/bme_includes ]; then
   	. ~/bme_includes
   fi
   ```

Once you open a new terminal, changes will be loaded.

**In brief:**  
When you open a Bash console once everything is installed and configured:
1. `~/.bashrc`, `~/.secrets`, and `~/bme_includes` are already in place.
   * on macOS, `~/.bash_profile` and `~/bme_macos_includes` are also in place.
1. Bash will source your `~/.bashrc`.
1. On interactive sessions, `~/.bashrc` will source `~/bme_includes`.
1. `~/bme_includes` will source your `~/.secrets` file.
   * on macOS further configuration will be done (see [macos configuration](./docs/macos.md)).
1. `~/bme_includes` will activate BME by updating your Bash prompt to run `bme_eval_dir()` as you traverse directories on your console.

<sub>[back to contents](#contents).</sub>

### configure your project(s)<a name="project"></a>
Once you properly installed and configured your console for *Bash Magic Enviro*, you may configure your projects to use it.
1. Add a **'.bme_project'** file to your project(s)' *"root directory"* to activate and configure their related environment (see [example](./docs/bme_project.example)).  
   Doing this at your git repository's root is preferred.  
   Whenever you `cd` into a project's filesystem hierarchy, its related *'.bme_project'* file will be searched for starting on the current directory and upwards to '/'.  Once found, its [*whitelisting status*](#whitelisting) will be checked and, if allowed, both the *'.bme_project'* file and the *'.bme_env'* file on the project's root (if any) will be sourced.
   ```bash
   ~$ cd ~/REPOS/bash-magic-enviro/example-project/
   INFO: '.bme_project' file found at '~/REPOS/bash-magic-enviro/example-project'.
           Do you want to whitelist this directory? [y/N]: y
   INFO: Directory '~/REPOS/bash-magic-enviro/example-project' whitelisted!
   WARNING: Your current 'Bash Magic Enviro' version couldnt be found at your remote.
           Your local version: 'v1.4.8'.
           Highest version at 'git@github.com:jmnavarrol/bash-magic-enviro.git': 'v1.4.7-1'.
   LOADING: project 'bme_example_project' environment...
           INFO: '~/REPOS/bash-magic-enviro/example-project/bin' added to local path.
           INFO: 'TFENV_TERRAFORM_VERSION' environment variable is not set.  Setting it to 'min-required' by default.
           INFO: 'terraform-support' loaded.
           INFO: 'python3-virtualenvs' (Python 3.11.2) loaded.
                   FUNCTION: load_virtualenv 'venv_name' - Loads the Python virtualenv by name 'venv_name'.
           WARNING: 'aws' command not found.
                   Make sure you load a suitable python virtualenv before calling 'load_aws_credentials'.
           ERROR: Environment variable '$AWS_MFA' can't be found.
                   Remember you should export your AWS MFA device's ID in that variable.
           ERROR: 'aws-support' not loaded. See missed dependencies above.
   INFO: Project 'bme_example_project' loaded.
   
   ~/REPOS/bash-magic-enviro/example-project$: cd some_subdir
   ```
1. Once your main project's configuracion is loaded by means of its *'.bme_project'* file, you can set configurations for each of your project's subdirectories (including its root one) with the help of **'.bme_env'** files.  
   Just remember *'.bme_env'* files are nothing but standard Bash files to be sourced, so you can add whatever Bash code you can run this way, typically calls to previously sourced functions, exports of further environment variables, informational outputs, etc.  
   See [an example *'.bme_env'* file for reference](./docs/bme_env.example), and also take a look at [the provided example project](./example-project/) for inspiration.
1. Once you move away from any BME project space (i.e.: `cd ~`) the environment will be automatically cleaned.
   ```bash
   ~/REPOS/example-project$: cd
           INFO: Custom cleaning finished
           INFO: Custom clean function ended successfully
   CLEANING: Project 'bme-example-project' cleaned.
   ~$:
   ```
   **NOTE:** if you tweaked your project's environment beyond BME's modules support (i.e.: you sourced you own project-level functions, exported some environment variables, etc.), remember cleaning after yourself with the help of [BME's custom clean function](#custom_clean).

*Bash Magic Enviro* also adds project-related configuration on its own (i.e.: local configurations, supporting tools' repositories, etc.).  This tool reserves by default the **'.bme.d/'** directory under your project's root for those, and it will create it upon entering the project's dir if it doesn't exist, so you should add it to your project's *'.gitignore'* file, i.e.:
```shell
# This is the project's main '.gitignore' file

# Bash Magic Enviro related
.bme.d/
```

**NOTE:** the project-level configuration directory path is stored on the global variable **BME_PROJECT_CONFIG_DIR**.  As it's been stated, its default value is *"${BME_PROJECT_DIR}/${BME_HIDDEN_DIR}"* (that is, *'.bme.d/'* under de project's root).  In case you need it, you can set *BME_PROJECT_CONFIG_DIR* to a different value in your *.bme_project* file.  If the path starts with a slash *'/'* it will be considered absolute; without a slash *'/'*, it will be relative to your project's root dir:
* absolute path:
  ```bash
  # on .bme_project file:
  # creates the '/some/absolute/path' directory to store this project's config/hidden files
  BME_PROJECT_CONFIG_DIR='/some/absolute/path'
  ```
* relative path:
  ```bash
  # on .bme_project file:
  # creates the '${BME_PROJECT_DIR}/.subpath' directory to store this project's config/hidden files
  BME_PROJECT_CONFIG_DIR='.subpath'
  ```
  
In case you tweak this *BME_PROJECT_CONFIG_DIR*, make sure your user has permissions to create the directory and write on it.  You also should take care no two different projects use the same *BME_PROJECT_CONFIG_DIR* path.

See also the included [example project](./example-project).

<sub>[back to contents](#contents).</sub>

## BME docker container<a name="docker-container"></a>
Provided as an alternate way to use and test BME, a docker container configuration is provided under the [*'docker-container/'* directory](./docker-container).

As of now, you should build this container locally.  See further info [at its README](./docker-container).

<sub>[back to contents](#contents).</sub>

## Available features<a name="features"></a>
Features are always active and can't be turned off.

### jumping among projects<a name="jumping_projects"></a>
You can freely `cd` among directories in your console and BME will try its best to find the proper *'.bme_project'* file to load (the one *"nearest"* upwards in the filesystem hierarchy).  If a BME project was already loaded it will be cleaned before sourcing the new one.

Be careful, though, for a *"deeper"* *'.bme_env'* file not to depend on configurations from an *"intermediate"* one, since those won't be automatically loaded.  Just the project root's *'.bme_env'* file and the one in the current directory (if any) will be sourced.  I.e.:
```sh
$ cd first_project_root  # 'first_project' will be loaded and its root directory remembered
$ cd subproject_root  # 'first_project' will be unloaded and 'subproject' will be loaded instead
$ cd ../../another_project_root  # 'another_project' will be loaded
$ cd ../first_project_root/subproject_root/some_subdir  # 'some_subdir' will be discovered as within 'subproject' tree, so 'subproject' configuration will be loaded
$ cd ../../another_subdir  # 'another_subdir' belongs to 'first_project', so 'first_project' will be loaded
$ cd ~/unknown_project_root/subdir  # this project's root is still unknown.  You'll be asked for its desired withelisting status
```

<sub>[back to feature list](#feature_list).</sub>

### directory whitelisting<a name="whitelisting"></a>
The first time a **'.bme_project'** file is found in a directory hierarchy, you'll be prompted to either allow or forbid BME to source it.  
Your answer will apply to that directory and **all the project's subdirectories** and it will be stored in the **'~/.bme.d/whitelistedpaths'** file, in the form of an associative array.

You can manually edit your *'~/.bme.d/whitelistedpaths'* file, but be aware the file will be overwritten each time the answer for a new directory is collected (so, i.e.: your comments won't be preserved).

**WARNING:** as already stated at [the Security section](#security), be aware this is by no means is a secure protection, but more of a convenience to avoid glaring overlooks.  You still are fully responsible to review all *.bme_\** contents before entering a directory.  Be also aware of tricks like symlinks, etc. that can fool you into sourcing unexpected code.

<sub>[back to feature list](#feature_list).</sub>

### logging<a name="log"></a>
BME provides its [**bme_log()**](https://github.com/jmnavarrol/bash-magic-enviro/blob/770e375bbfe593fe4e2a153feeca5ad3e7a4835a/src/bash-magic-enviro#L97) function that you can use in your *'.bme_\*'* files to **colorize**, **prefix**, **indent** and **filter** log messages.

*bme_log()* accepts three (positional) parameters and filters its output accordingly to the value of the **BME_LOG_LEVEL** environment variable (with an **INFO** default value).
* **Parameters:**
  1. **log message [mandatory]:** the log message itself.  It accepts codes for colored output (see [below](#colors)).
  1. **log type [optional]:** the type of log, i.e.: *warning*, *info*...  It is represented as a colored uppercase prefix to the message.  
     Run `bme_log` without parameters to get a list of known *log types* and the color it will be used along the prefix.
  1. **log indent [optional]:** when set, it indents your message by as many *tabs* as the number you pass (defaults *0*, no indentation).  
     Remember that, since Bash function parameters are positional, you need to provide a *log type* whenever you want to provide a *log indent*.
* **BME_LOG_LEVEL:** (default **INFO**) this environment variable controls which logs will *bme_log()* print to console.  
  When the *bme_log* type matches a [syslog severity level](https://en.wikipedia.org/wiki/Syslog#Severity_level) and the severity is below the threshold set by *BME_LOG_LEVEL*, the message will **not** be printed.  
  List of severities in decreasing priority:
  1. **EMERGENCY:** System is unusable - A panic condition.
  1. **ALERT:** Action must be taken immediately - A condition that should be corrected immediately, such as a corrupted system database.
  1. **CRITICAL:** Critical conditions - Hard device errors.
  1. **ERROR:** Error conditions.
  1. **WARNING:** Warning conditions.
  1. **NOTICE:** Normal but significant conditions - Conditions that are not error conditions, but that may require special handling.
  1. **INFO:** Informational messages - Confirmation that the program is working as expected.  This is the default.
  1. **DEBUG:** Debug-level messages - Messages that contain information normally of use only when debugging a program.
* **Examples:**
  * *BME_LOG_LEVEL* not explicity set (therefore it gets the *INFO* default):
    * this will be printed: `bme_log "my message" error`
    * these will **not** be printed:
      * `bme_log "my message" debug`  # 'DEBUG' is below default 'INFO' thresold
      * `BME_LOG_LEVEL=ERROR bme_log "my message" function`  # 'FUNCTION' prints at 'INFO' level which here is below thresold
    * this will **always** be printed, as it doesn't match a listed severity: `bme_log "custom message" my_custom_type`
    * a general case example: `bme_log "An 'INFO:' prefix will be added in green. ${C_BOLD}'this is BOLD'${C_NC} and this message will be indented once." info 1`

<sub>[back to feature list](#feature_list).</sub>

### colored output<a name="colors"></a>
Constants are exported that can help you rendering colored outputs (see the output of [bme_log](#log) without params).  
They can be used within your *'.bme_\*'* files with the help of either [bme_log](#log) or *"-e*" echo's option.  I.e.:
```bash
bme_log "${C_RED}This is BOLD RED${C_NC}" info 1
echo -e "Bold follows: ${C_BOLD}'BOLD'${C_NC}"
```
...remember always resetting color option with the `${C_NC}` constant after use.

<sub>[back to feature list](#feature_list).</sub>

### custom clean function<a name="custom_clean"></a>
While *Bash Magic Enviro* will take care of cleaning all its customizations when you go out your project's directory hierarchy, you may also define/export your own custom variables, Bash functions, etc. within your project scope, and *Bash magic enviro* will offer the chance to clean after you.

For this to happen you should declare a *custom clean function* named **bme_custom_clean()** (no params) and it will be called **before** any other cleansing (see [example config](./docs/bme_project.example)).

Once *bme_custom_clean* is run, it will also be *unset* to avoid cluttering your environment.

<sub>[back to feature list](#feature_list).</sub>

### *Bash Magic Enviro* version checking<a name="check-versions"></a>
As the name implies, helps you noticing if your current *Bash Magic Enviro* version is up to date.

A function named [**bme_check_version()**](https://github.com/jmnavarrol/bash-magic-enviro/blob/e69fb64217aaf3844997edd6ca19e905d2e33401/src/bash-magic-enviro#L155) (no parameters) is exported so you can call it wherever you feel proper (i.e.: *.bme_project* and *.bme_env* files or command prompt).

This function compares your current *Bash Magic Enviro's* version against the highest version available, defined as *git tags* at your *git remote*.  Shows a message about current version status.

**NOTE:** BME follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html) with an exception: since this is pure scripted software with version identifiers published as git tags, version is always preceeded with the *'v'* character, i.e.: *v1.2.3* instead of semver fully compatible *1.2.3*.

<sub>[back to feature list](#feature_list) | [back to contents](#contents).</sub>

### Per-project custom modules<a name="custom-modules"></a>
If there's a [bme-modules/ directory](./example-project/bme-modules/) within the root of your BME project, it will be honored and you can load modules from files within in exactly the same conditions and **with precedence** to *global* modules of same name.

You may use this feature when you want module-management abilities (autoloading, preparing an environment, exporting functions, etc.) for things that doesn't make sense out of the limited scope of your project or if/when you need to *overload* the way a global module works.

The standard conditions for modules are supported (i.e.: [naming](#available-modules), [loading](#available-modules), [development](#dev-modules)...).

You can look for inspiration about what can be done with [a *"barebones"* example](./example-project/bme-modules/sample-module.module) as well as the included [global modules' source code](./src/bash-magic-enviro_modules/).

<sub>[back to feature list](#feature_list) | [back to contents](#contents).</sub>

## Available modules<a name="modules"></a>
Modules are *"turned off"* by default, but you can *"turn on"* those you need by means of the **BME_MODULES=()** array (see [example project file](./docs/bme_project.example)).

On top of this README, you can also check your **'~/bin/bash-magic-enviro_modules/'** directory: each file within has the exact name (with *'.module'* extension) of one module you can activate.

**NOTE:** As you may notice, modules are loaded/unloaded by means of a Bash array.  As such, sorting order matters (i.e.: if you want to activate *'aws-support'* loading *awscli* by means of a python virtualenv, make sure you list *'python3-virtualenvs'* module **before** *'aws-support'*).

### project's bin dir<a name="bindir"></a>
**[bindir module](./src/bash-magic-enviro_modules/bindir.module):** the **'bin/'** directory relative to the project's root will be added to $PATH, so custom script helpers, binaries, etc. are automatically available to the environment.

**NOTE:** if *bindir* is requested but the directory doesn't exist, this module will create it on the fly.

<sub>[back to module list](#module_list).</sub>

### load Python3 *virtualenvs*<a name="virtualenvs"></a>
**[python3-virtualenvs module](./src/bash-magic-enviro_modules/python3-virtualenvs.module):** Manages *Python3 virtualenvs*.

By default, this module looks first for `python3 --version` output; if it doesn't find it, it also tries `python --version`, in case it defaults to >=3.

You can also set the environment variable **BME_PYTHON3_CMD**, either on the `.bme_project` or a `.bme_env` file, to a valid Python executable path, i.e.: `export BME_PYTHON3_CMD='python3.11'` or `export BME_PYTHON3_CMD='/usr/local/bin/python3.11'` and this module will use it to build virtual environments.

If [virtualenvwrapper](https://virtualenvwrapper.readthedocs.io/) configuration is detected, this module will rewrite its **WORKON_HOME** environment variable to point to the project's path.  Its original value will be restored once out of a project environment.

See also [the included example](./example-project/virtualenv-example/.bme_env).

**Requirements:**
* Python 3.
* md5sum (it comes from package **coreutils** in the case of Debian systems).
* flock (it comes from package **util-linux** in the case of Debian systems).

**Functions:**
* **load_virtualenv virtualenv [requirements_file]:** creates, loads or updates the requested virtualenv *[virtualenv]*.  Optionally, it accepts a second param with the path to a requirements file to be used to populate the virtualenv (path is relative to the .bme_env file where the function is loaded).
  1. If the function can't find the requested virtualenv *[virtualenv]*, it will look for its requirements file at *"${BME_PROJECT_DIR}/python-virtualenvs/[virtualenv].requirements"* and it will create the requested *virtualenv* using it.  
     It will also use the *requirements_file* provided as second param, if provided.
  1. If the requirements file can't be found, it will create either an *"empty"* virtualenv *[virtualenv]*, along with an empty *requirements* file, so you can start installing packages on it, or the virtualenv *[virtualenv]* populated with pips from the *[requirements_file]* passed as second parameter.
  1. If *pip* is listed in the *requirements* file, and given the requirements' file format is quite sensible about the exact version of *pip* in use, *load_virtualenv* will try to honor your requested pip version before installing the remaining packages into the virtualenv.
  1. This function also stores the requirements file's *md5sum* under the project's *'.bme.d/'* hidden directory, so it can update the virtualenv when changes are detected.
  
  **NOTES:**
  * For virtualenvs created with the help of a requirements file, it is advised to add their associated *"${BME_PROJECT_DIR}/python-virtualenvs/[virtualenv].requirements"* files to *.gitignore* so you don't have two files to maintain providing the same info.

The expectation is that you will install whatever required pips within your virtualenv and, once satisfied with the results, you'll either "dump" its contents to its requirements file, i.e.: `pip freeze > ${BME_PROJECT_DIR}/python-virtualenvs/[virtualenv].requirements`, or you'll maintain them on a different file you pass as requirements file to *load_virtualenv()*.

<sub>[back to module list](#module_list).</sub>

### AWS support<a name="aws"></a>
**[aws-support module](./src/bash-magic-enviro_modules/aws-support.module):** Adds support for [AWS-based](https://aws.amazon.com/) development.

As of now, it works on the expectation that you own a *"personal AWS account"*, protected by means of [MultiFactor Authentication](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html) and a [software OTP device](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_enable_virtual.html).  Your account is, then, granted further access and privileges by means of [role impersonation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-console.html).

**Requirements:**
* [jq](https://github.com/stedolan/jq): a *"lightweight and flexible command-line JSON processor"*.  It is used here to parse AWS API responses.  You should most possibly install it with the help of your system's package manager (i.e.: `sudo apt install jq`).
* A properly profiled AWS access configuration.  I tested this with a local *~/.aws/* directory (this module will use your AWS's **default** profile).  See [examples for *config* and *credentials* files](./docs/aws_dir).
* *$AWS_MFA* environment variable.  You need to export your MFA device to this variable, usually from your [bme_includes file](./docs/bme_includes.example).  Make sure it matches the **mfa_serial** configuration from [your **default** AWS profile](./docs/aws_dir/credentials.example).
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html): most possibly, your best approach is including it in a python virtualenv with the help of our [python3-virtualenvs module](#virtualenvs).
* [python3-virtualenvs module](#virtualenvs): if you load your *awscli* support from within a python virtualenv.
* This module can only be used in an interactive Bash session.

**Functions:**
* **load_aws_credentials:** it contacts, with the help of AWS CLI, AWS's API endpoint to grab an *aws session token* using your *default profile's* credentials.  
Upon loading, it will ask for a single use password from your MFA device, which means this can be only used in interactive sessions.  In the end, it's a wrapper around a command invocation: `aws sts get-session-token --serial-number [your MFA device] --token-code [single use password]`.  It then exports AWS_* session variables to your console, so you don't have to re-authenticate again (up to your session's expiration time).  See [an example usage](./example-project/aws-example/.bme_env).

<sub>[back to module list](#module_list).</sub>

### git client-side hooks support<a name="githooks">
**[githooks module](./src/bash-magic-enviro_modules/githooks.module):** Enables the alternate **githooks/** directory for client-side git hooks so they can be automatically shared among all repository users.

For this to happen, git's **core.hooksPath** property is set to point to the **"${BME_PROJECT_DIR}/githooks"** directory within a repository with this module activated.

**Requirements:**
* git >= 2.9
* BME's project root directory should be the root of a git sandbox (this is to make it easier to manage without worrying about relative paths, etc.)
* Internet connectivity

**NOTE:** the [bme-githooks](https://github.com/jmnavarrol/bme-githooks) helper repository has been created to showcase this module's features.

<sub>[back to module list](#module_list).</sub>

### Terraform support<a name="terraform"></a>
**[terraform-support module](./src/bash-magic-enviro_modules/terraform-support.module):** Adds support for [Terraform](https://www.terraform.io/intro/index.html) development.  It peruses [the tfenv project](https://github.com/tfutils/tfenv/tree/v2.2.3) to allow using different per-project Terraform versions, suited to your hardware.

For this to happen, *Bash Magic Enviro* clones [the tfenv repository](https://github.com/tfutils/tfenv) to *"${BME_CONFIG_DIR}/tfenv"* (defaults to *'~/.bme.d/tfenv/'*) and configures it for usage within your project scope, so make sure you add *'${BME_PROJECT_DIR}/bin/[terraform|tfenv]'* to your ['.gitignore' file](./example-project/.gitignore) (an error will be thrown otherwise).

Once *tfenv* is (automatically) configured for your project, you can normally use any suitable terraform or [tfenv command](https://github.com/tfutils/tfenv/tree/v2.2.0#usage).

You should set your desired terraform version [in terraform's code itself](https://developer.hashicorp.com/terraform/language/settings), i.e.:
```tf
terraform {
  required_version = "= 1.2.6"
}
```
This way, this module will set for you the environment variable `TFENV_TERRAFORM_VERSION=min-required` with which a suitable terraform version will be installed upon your first terraform command invocation.  See [a .bme_env example](./example-project/terraform-example/.bme_env).  This *TFENV_TERRAFORM_VERSION* variable is unset when you go outside the project's directory tree along *Bash Magic Enviro*'s cleaning process.

This module also sets the **'TF_PLUGIN_CACHE_DIR'** environment variable pointing to the *"${BME_CONFIG_DIR}/.terraform.d/plugin-cache/"* directory so plugins can be reused within different Terraform plans even by different BME projects (also unset at project exit).

**NOTE:** when a given terraform version is requested, *symlinks* will be created under the project's *'bin/'* directory for both *tfenv* and *terraform*.  You should include them in your *'.gitignore'* file (see [example](./example-project/.gitignore)).

**Requirements:**
* git command
* Internet connectivity

<sub>[back to module list](#module_list) | [back to contents](#contents).</sub>

## Development<a name="development"></a>
There's a `make dev` target on [the Makefile](./Makefile), that creates *symbolic links* under *~/bin* from source code.  This way, you can develop new features with ease.

**NOTE:** remember you need to re-run `make dev` each time you alter either the [Makefile](./Makefile) (and/or its supporting scripts) or [bash-magic-enviro.version.tpl](./src/bash-magic-enviro.version.tpl) files.

### modules' development<a name="dev-modules"></a>
*Modules* are the way to add new functionality to *Bash Magic Enviro*.  Any file named *[modulename].module* under either the [*'bash-magic-enviro_modules/'* directory](./src/bash-magic-enviro_modules) or a [project's bme-modules subdirectory](#custom-modules) becomes a module by that name.

*Modules* are loaded by including their *modulename* in the **BME_MODULES() array** of your project's *.bme_project* file (see [example](./docs/bme_project.example)).  Upon entering into your project's root directory, the file represented by the module name is first sourced and then its *[modulename]_load()* function is called with no parameters.

When you `cd` out of your project's space, all modules are unloaded by calling their *[modulename]_unload()* function without parameters.

This means that, at the very minimum, every module needs to define these two functions: *[modulename]_load()* and *[modulename]_unload()*:
1. **[modulename]_load():** it should run any preparation the module may need, i.e.: exporting new environment variables, check for the presence of pre-requirements, etc.  
   It is expected that, in case of problems running *[modulename]_load()*, your module cleans after itself before returning, i.e.:
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
       return 1
     else
       bme_log "${C_BOLD}'[modulename]'${C_NC} loaded." info 1
     fi
   }

   ```
   You can also look at [other modules](./src/bash-magic-enviro_modules/) to get some inspiration.
1. **[modulename]_unload():** it should clean any modification to the shell the module introduces.  A good test while developing a new module can be running `set > before.txt` and `set > after.txt` when loading/unloading the module and check the *diff* between both files: there should be no *diff*.

Other than that, anything that can be *sourced* by Bash can be added to the module's file, since that's exactly what will happen (the file is *sourced* when the module is requested).

#### modules' dependencies
If your module depends on other modules to be already loaded (i.e.: [terraform module](#terraform) depends on [bindir module](#bindir)) you can *"pre-load"* them calling the **__bme_modules_load()** function with the desired module as parameter, one at a time, in dependency order, i.e.:
```bash
# Load module pre-dependencies
__bme_modules_load 'first_module'
__bme_modules_load 'second_module'

```

This should be made outside of any function, preferred early on your module file, so the *"pre-loading"* is run when the module code is sourced, before your own *[module]_load()* function is run.  This way the dependency order is insured both at module loading and unloading.

See [the terraform module's source code for an example](./src/bash-magic-enviro_modules/terraform-support.module).

See also documentation about [modules' unit testing](./tests/README.md).

<sub>[back to contents](#contents).</sub>

### unit tests<a name="unit-tests"></a>
A custom framework under [tests/](./tests/) allows for this code's unit testing both for main code and modules.  See [its README](./tests/README.md) for further details.

<sub>[back to contents](#contents).</sub>

### Support<a name="support"></a>
This is a hobby project I work on my free time, so you shouldn't expect but a *"best effort"* support.  You are welcome to [open issues](https://github.com/jmnavarrol/bash-magic-enviro/issues) and offer *pull requests* [on its GitHub page](https://github.com/jmnavarrol/bash-magic-enviro).

I also maintain [an unestructured TODO file](./TODO.md) so you can get an idea on what I'm hoping to work in the future.

<sub>[back to contents](#contents).</sub>

----

### License<a name="license"></a>
*Bash Magic Enviro* is made available under the terms of the **[GPLv3](https://www.gnu.org/licenses/gpl-3.0.html)**.

See the [license file](./LICENSE) that accompanies this distribution for the full text of the license.

<sub>[back to contents](#contents).</sub>
