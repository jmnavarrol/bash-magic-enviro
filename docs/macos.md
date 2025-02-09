# macos support
macOS uses BSD tooling while BME is developed mainly on Linux with GNU tooling support.  For BME to run on macOS with its required dependencies, I suggest installing them through [homebrew](https://brew.sh/).  Once *hombrew* is installed and configured, you should install the following packages:
* bash (since macOS' Bash version is too old).  Once homebrew's Bash is installed, you need to open a new console running its version as interactive shell.
* brew install coreutils: GNU variants for (g)mkdir, rm, md5sum, etc.
Commands also provided by macOS and the commands dir, dircolors, vdir have been installed with the prefix "g".
If you need to use these commands with their normal names, you can add a "gnubin" directory to your PATH with:
  PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"

## development for macos
From the nice guys at https://github.com/sickcodes/Docker-OSX.

First make sure your enviroment works properly: your computer supports hardware virtualization, you can run docker from you user, proper qemu display export is working, etc.  Then you can create your local image (a container that in turn run macOS as a virtual machine).

**Create your own local image:**  
`docker run -it --device /dev/kvm -p 50922:10022 -v /tmp/.X11-unix:/tmp/.X11-unix -e "DISPLAY=${DISPLAY:-:0.0}" -e GENERATE_UNIQUE=true -e MASTER_PLIST_URL='https://raw.githubusercontent.com/sickcodes/osx-serial-generator/master/config-custom.plist' -e SHORTNAME=ventura sickcodes/docker-osx:latest`
  1. Choose disk utility -> erase the largest disk (name: **macos** so you can find it easily later on to install the OS on it).
  1. Quit Disk Utility and choose now *"Reinstall macOS Ventura"* (select *macos* as the disk you want to install macOS onto).
  
Right after finishing your local macOS installation I suggest you immediately shutdown the VM and take an export/snapshot.  As of now, you can restart the VM where you left it with something like this:
1. find the associated container: `docker container ls --all`
1. re-start it: `docker container start --attach --interactive [container id or name]`  
   i.e.: `docker container start -ai crazy_thompson`

**Export/snapshot:** `docker commit [container id or name] newImageName`  
i.e.: `docker commit crazy_thompson macos-ventura:1.0.0`

**Run your export:** `docker run --interactive --tty --device /dev/kvm --publish 50922:10022 --volume /tmp/.X11-unix:/tmp/.X11-unix --env "DISPLAY=${DISPLAY:-:0.0}" macos-ventura:1.0.0`

From now on, you can either run your *"current"* state with `docker container start -ai [container id or name]` or take new milestones with `docker commit [container id or name] newImageName` whenever you fill proper.

Next suggested steps:
1. Install pending updates (I suggest you do **not** accept global OS upgrades now.  You can always do it later and reexport tagging with the different version, i.e.: `docker commit [container id or name] macos-sonoma:1.0.0`. This way you can select different OS versions with ease)
1. Install [homebrew](https://brew.sh/): `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
1. Install bash (on a new console after installing *homebrew*): `brew install bash`
  * On a default *homebrew* setup preferred `bash` will be the one from brew (you can check it with `which bash` which will show */usr/local/bin/bash* instead of */bin/bash*.
