# macos support<a name="top"></a>
* [install](#install)
* [development for macos](#macos-development)

## install<a name="install"></a>
macOS uses BSD tooling by default while BME is developed mainly on Linux with GNU tooling support.  
For BME to run on macOS with its required dependencies, I suggest installing them through [homebrew](https://brew.sh/).  
Once *homebrew* is installed and configured, you should `brew install` the following packages:
* bash
* coreutils
* findutils
* grep
* gnu-sed
* flock
* jq

Once those packages are installed, they should be made the default instead of those from the system by setting the PATH environment variable on the console.  To help with this process, an example of custom BME Terminal profiles are provided here which you could import, as well as examples for [.bash_profile](./macos/.bash_profile.example), [.bashrc](./macos/.bashrc.example) and [bme_macos_includes](./macos/bme_macos_includes.example) to be sourced from the general [bme_includes file](./bme_includes.example). You could use them as a reference for your own ones under your `${HOME}/` directory.

Two terminal profiles are included (their only difference being the absolute path to brew's Bash), one for [intel-based platforms](./macos/BME.intel.terminal), and another one for [arm64 ones](./macos/BME.arm64.terminal). Review the output of `uname -m` to check your architecture and select the one you import accordingly.

Once *Terminal Profile* and homebrew dependencies are properly installed and configured, you can go on with [the general install instructions](../README.md#install) within your BME (Bash-configured) console.

**In brief:**  
Session steps on macOS:
1. set in place proper `~/.bash_profile`, `~/.bashrc`, `~/.secrets`, `~/bme_includes` and `~/bme_macos_includes` files.
1. import and review the proper *BME Terminal Profile*.
1. open a console with that *BME Terminal Profile*.  Upon start, it will:
   1. run Bash in login mode.
   1. Bash will source your `~/.bash_profile`.
   1. `~/.bash_profile` will source `~/.bashrc`.
   1. On interactive sessions, `~/.bashrc` will source `~/bme_includes`.
   1. `~/bme_includes` will source your `~/.secrets` file.
   1. On macOS' *BME Terminal Profile*, `~/bme_includes` will source `~/bme_macos_includes`.
   1. `~/bme_macos_includes` will check for the required brew dependencies and it will set your session's `$PATH` environment variable as needed.
   1. Finally, back to `~/bme_includes`, it will activate BME by updating your Bash prompt to run `bme_eval_dir()` as you traverse directories on your console.

<sub>[back to top](#top).</sub>

## development for macos<a name="macos-development"></a>
From the nice guys at https://github.com/sickcodes/Docker-OSX.

First make sure your enviroment works properly: your computer supports hardware virtualization, you can run docker from you user, proper qemu display export is working, etc.  Then you can create your local image (a container that in turn runs macOS as a virtual machine).

**Create your own local image:**  
`docker run --name 'macos-ventura' -it --device /dev/kvm -p 50922:10022 -v /tmp/.X11-unix:/tmp/.X11-unix -e "DISPLAY=${DISPLAY:-:0.0}" -e WIDTH=1280 -e HEIGHT=768 -e GENERATE_UNIQUE=true -e MASTER_PLIST_URL='https://raw.githubusercontent.com/sickcodes/osx-serial-generator/master/config-custom.plist' -e SHORTNAME=ventura sickcodes/docker-osx:latest`
  1. Choose disk utility -> erase the largest disk (name: **macos** so you can find it easily later on to install the OS on it).
  1. Quit Disk Utility and choose now *"Reinstall macOS Ventura"* (select *macos* as the disk you want to install macOS onto).

Right after finishing your local macOS installation I suggest you immediately shutdown the VM and take an export/snapshot.  As of now, you can restart the VM where you left it with something like this:
1. find the associated container: `docker container ls --all`
1. re-start it: `docker container start --attach --interactive [container id or name]`  
   i.e.: `docker container start -ai macos-ventura`

**Export/snapshot:** `docker commit [container id or name] newImageName`  
i.e.: `docker commit macos-ventura macos-ventura:1.0.0`

**Run your export:** `docker run --name 'macos-ventura' --interactive --tty --device /dev/kvm --publish 50922:10022 --volume /tmp/.X11-unix:/tmp/.X11-unix --env "DISPLAY=${DISPLAY:-:0.0}" -e WIDTH=1600 -e HEIGHT=900 macos-ventura:1.0.0`

From now on, you can either run your *"current"* state with `docker container start -ai [container id or name]` or take new milestones with `docker commit [container id or name] newImageName` whenever you fill proper.

**Next suggested steps:**
1. Install pending updates (I suggest you do **not** accept global OS upgrades now.  You can always do it later and reexport tagging with the different version, i.e.: `docker commit [container id or name] macos-sonoma:1.0.0`. This way you can select different OS versions with ease)
1. Install [homebrew](https://brew.sh/): `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
1. Install bash (on a new console after installing *homebrew*): `brew install bash`
  * On a default *homebrew* setup preferred `bash` will be the one from brew (you can check it with `which bash` which will show */usr/local/bin/bash* instead of */bin/bash*.

<sub>[back to top](#top).</sub>
