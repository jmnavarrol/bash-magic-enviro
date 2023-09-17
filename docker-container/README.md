# BME Docker Container<a name="top"></a>

This container installs BME globally as explained [on the *"install Bash Magic Enviro"* section](../#make_install).

----
**Contents:**<a name="contents"></a>
1. [building this container](#container-build)
1. [running this container](#container-run)
   1. [container session](#container-session)
----

## building this container<a name="container-build"></a>
In order to build this container you should, of course, have a properly configured docker environment (follow instructions for your Operating System).

On this subdirectory you could run a command like the following to build the container:
```sh
docker-container$ docker build --no-cache --tag bme-container:latest .
```
Pay attention to [this container's Dockerfile](./Dockerfile): it sets both where to download BME from and which version. Either edit or overwrite these params to your convenience:
* **ARG BME_REPO**='https://github.com/jmnavarrol/bash-magic-enviro.git'
* **ARG BME_VERSION**='v1.4.6'

An example:
```sh
docker-container$ docker build --no-cache  --build-arg="BME_VERSION=a-development-branch" --tag bme-container:latest .
```

<sub>[back to top](#top).</sub>

## running this container<a name="container-run"></a>
This [container's entrypoint](./entrypoint.sh) can create on the fly an internal user mapping your own UID and username from your local computer.  This way, you can mount a directory under your *~home* which serves as the root of your BME projects.  It is advised, but not mandatory, that this *"project root"* is also the root of a git repository so you can version any customizations of yours.

**HINT:** do **not** mount your own ~home directory as the volume's root since it will lead to nasty problems (you most possibly don't want the same configurations within the container than in your local computer).

**docker run example:**
```sh
docker run \
       --env DESIRED_USERNAME=${USER} \
       --env DESIRED_UID=$(id -u ${USER}) \
       --volume ~/REPOS/BME-PROJECTS-ENTRYPOINT:/home/${USER} \
       --rm --tty --interactive \
       bme-container:latest
```

Let's see what these options mean:
* **--env DESIRED_USERNAME=${USER}:** sets the internal *username* that will be created.  As it is, it maps your own username on your local computer (you can try `echo ${USER}` to check it).
* **--env DESIRED_UID=$(id -u ${USER}):** sets the internal user's UID.  As it is, it maps your own user's UID from your local computer (again, you can try `id -u ${USER}` to check).
* **--volume ~/REPOS/BME-PROJECTS-ENTRYPOINT:/home/${USER}:** provided there already exists a subdirectory under your home directory named *REPOS/BME-PROJECTS-ENTRYPOINT/* this option mounts it as the home directory of the internal user.
* **--rm --tty --interactive:** common options that allows the container to run as expected.  *--rm* will fully destroy the container once you exit it.
* **bme-container:latest:** the name of the image.  It should map the **--tag** you provided when you built it.

All together, these options give you *"transparency"* between the container and your local filesystem honoring your own user and privileges: whatever you edit within the container under the internal user's home will be immediatly *"updated"* on your own computer too, with proper ownership and privileges.  The opposite is also true: whatever you edit from your local computer (say, using your favourite IDE) will be immediatly updated within the container.

In case of problems or if you don't provide the proper parameters, the container will return to you a root prompt.

**NOTE:** the internal user that is created on-the-fly every time you run this container can sudo to root without password in case you needed it.

<sub>[back to top](#top).</sub>

### container session<a name="container-session"></a>
After `docker run...` and provided the internal user creation succeeded, an interactive session within the container will start.  Supposed an empty *~/REPOS/BME-PROJECTS-ENTRYPOINT/* subdirectory, at first launch a basic BME project file will be copied to your project's root and it will be immediatly loaded (see [its configuration file](./etc/skel/.bme_project).  Note that [as per the container's entrypoint](./entrypoint.sh#L46), files will be copied **only** if they don't exist at the target directory.

Along this first container session run, you'll see files appearing under your *~/REPOS/BME-PROJECTS-ENTRYPOINT/* subdirectory: a *.bme_project* file, Bash session management files like *.bashrc*, *.bash_history*, etc.  The container will also ask you to *whitelist* the entrypoint directory as it's the case always [BME *"sees"* a project file for first time](../README.md#whitelisting).

Also, since [the *"standard"* .bme_project comes from within the container](./etc/skel/.bme_project), a provision has been added so you can overwrite and/or augment its configuration by means of a file named **'bme_project_local'** at the root of your project.  Contents on your *bme_project_local* file will have higher precedence that those from the standard *.bme_project* file.

You just need to remember that whatever volume you pass to the container will act as the internal user's home directory, so you can add whatever configurations it makes sense for your use case, of course a *.bme_env* file suitable for your project but also, i.e.: a customized *.ssh/* subdirectory so you can freely connect to other hosts from within the container, or a *.gitconfig* file, etc.

<sub>[back to top](#top).</sub>
