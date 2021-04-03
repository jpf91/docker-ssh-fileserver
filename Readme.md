# [jpf91/ssh-fileserver](https://github.com/jpf91/docker-ssh-fileserver)

This image provides all sorts of SSH based file servers, including SSH shell, SCP, SFTP, Rsync and Borg access. It integrates authentication with the host system to enable multiuser support.

## Supported Architectures

Currently only `x86_64` images are being built, allthough the `Dockerfile` is not architecture dependent.

## Usage

Here are some instructions and snippets to help you get started creating a container.

### Initial Setup

Before starting the container the first time, you need to generate the SSH host keys in the persistent key folder:
```bash
cd </path/to/appdata>
# Initilialize directory
mkdir keys
ssh-keygen -f keys/ssh_host_rsa_key     -N '' -t rsa
ssh-keygen -f keys/ssh_host_ecdsa_key   -N '' -t ecdsa
ssh-keygen -f keys/ssh_host_ed25519_key -N '' -t ed25519
# Make sure private have proiper permissions
chown root keys/*
chmod 600 keys/ssh_host_rsa_key keys/ssh_host_ecdsa_key keys/ssh_host_ed25519_key
```

You also have to provide a `sshd` configuration file `sshd_config`, which in a minimal form can look like this:
```
HostKey /etc/ssh/keys/ssh_host_rsa_key
HostKey /etc/ssh/keys/ssh_host_ecdsa_key
HostKey /etc/ssh/keys/ssh_host_ed25519_key

Subsystem	sftp	internal-sftp

UsePAM yes
PasswordAuthentication yes
```

### Running using podman cli

```
podman run --name ssh-fileserver --privileged  \
    -p 22:22 \
    -v /home:/home \
    -v </path/to/appdata/sshd_config>:/etc/ssh/sshd_config \
    -v </path/to/appdata/keys>:/etc/ssh/keys \
    -v /etc/krb5.conf:/etc/krb5.conf \
    -v /var/lib/sss/pipes/:/var/lib/sss/pipes/ \
    -v /etc/passwd:/etc/passwd -v /etc/group:/etc/group -v /etc/shadow:/etc/shadow \
    docker.io/jpf91/ssh-fileserver
```

### Limiting Network Access in the Containter

If you want to use the container only for file serving, it is recommended to disable outbound network connectivity.
If you don't do this, users can open a `ssh` shell on the server and then call `rsync` and other commands against remote servers.

The simplest way to do this seems to create a custom network, then disable IP masquerading on the network:
```bash
podman network create internal-ssh
# Set ipMasq to false
nano /etc/cni/net.d/internal-ssh.conflist
```
Finally add `--net internal-ssh` to your container parameters.

### Testing the Container

To test whether the login integration is fully working, you can `ssh` into the container. Then issue the following commands:

```bash
# If you have IPA / AD / Kerberos Integration
kinit $USER
klist

# Basic user information
id $USER
ls /home/$USER

# Login using password
su $USER
su $USER

# Should fail if you disabled the network
ping google.de
```

## Parameters

Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 22:22` would expose port `22` from inside the container to be accessible from the host's IP on port `22` outside the container.

| Parameter | Function |
| :----: | --- |
| `-p 22` | SSH main port. |
| `-v /home` | Usual place for user home folders. You should mount any folders you want to have accessible over SSH. If your home is not `/home`, use your custom home location in the container as well. Also add any additional folder you want to have served via the container. |
| `-v /etc/ssh/sshd_config` | OpenSSH daemon configuration file. |
| `-v /etc/ssh/keys/` | OpenSSH daemon host key location. |
| `-v /etc/krb5.conf` | For SSSD based authentication, make the kerberos configuration available. |
| `-v /var/lib/sss/pipes/` | For SSSD based authenticationl, make the host SSSD API available. |
| `-v /etc/passwd -v /etc/group -v /etc/shadow` | For local user authentication, make the host passwed files available. |

## Application Setup

Add additional directory mounts as needed to make them available in the container and to the SSH based services.
It is recommended to keep the same directory layout as on the host: If you export your files using different
protocols (e.g. NFS, FTP) it is useful to have the same paths in SSH based fileservers.

### Authentication

This image supports two types of authentication: Using the host system's SSSD (IPA, AD and more) or using the host systems local users from `/etc/passwd`. Depending on the variant you want to use, set parameters as mentioned before. You can also include both local users and SSSD.

For authentication using SSSD and Kerberos, make sure that your `/etc/krb5.conf` file does not enable sssd-kcm. If you
want to use sssd-kcm on the host, configure it in `/etc/krb5.conf.d/`, as that configuration will be ignored in the container.

## Support Info

* Shell access whilst the container is running: `podman exec -it ssh-fileserver /bin/bash`
* To monitor the logs of the container in realtime: `podman logs -f ssh-fileserver`
* Report bugs [here](https://github.com/jpf91/docker-ssh-fileserver).

## Building locally

If you want to make local modifications to these images for development purposes or just to customize the logic:
```
git clone https://github.com/jpf91/docker-ssh-fileserver.git
cd docker-ssh-fileserver
podman build \
  -t docker.io/jpf91/ssh-fileserver:latest .
```

## Versions

* **07.02.21:** - Initial Release.
