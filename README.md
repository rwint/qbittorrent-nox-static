# qbittorrent-nox-static

A build script for qBittorent nox (mostly) static using the current releases of the main dependencies.

## Info

The truth is that it might not be possible to build a totally static build of [qBittorrrent](https://www.qbittorrent.org/) but this is a pretty good attempt at an automated build script to do just that.

This is a very functional build script that creates a binary that can be executed on another matching build platform with no installation dependency requirements.

## Details

Tested as root and a local user on these supported operating systems:

Debian 10 (buster) amd64 and arm64
 
Ubuntu 18.04 LTS amd64 and arm64

## Build settings:

qBittorrent 4.2.1 was built with the following libraries:

Qt: 5.14.0
Libtorrent: 1.2.3.0
Boost: 1.72.0
OpenSSL: 1.1.1d
zlib: 1.2.11

## Script usage:

Follow these instructions to install and use this build tool.

### info

The script will build to a hard coded path in the script `$install_dir` as to avoid installing files to a server and causing conflicts.

~~~
export install_dir="$HOME/qbittorrent-build"
~~~

*Note: Apart from the required dependencies installed using `apt` the system is not modified in any way.*

It will allow you to install qBittorrent in two ways:

Root - Built to - `/root/qbittorrent-build`

Root - Optionally installed to `/usr/local`

*Note: A local user still requires the core dependencies are installed to proceed.*

Local user - Built to - `$HOME/qbittorrent-build`

Local user - Optionally installed to `$HOME/bin`

### installation

Download the script and make it executable to your user:

~~~
wget -qO ~/qbittorrent-nox-static.sh https://git.io/JvfCX
chmod 700 ~/qbittorrent-nox-static.sh
~~~

Now you can just run it to do a full build

~~~
./qbittorrent-nox-static.sh
~~~

The default build location is `~/qbittorrent-build` in the user's home directory.

Once the build has completed you can install using this command:

~~~
./qbittorrent-nox-static.sh install
~~~

If you are root the executable is installed to `/usr/local/bin`

If you are a non root user the executable is installed to `~/bin` in that user's home directory.

## Post installation rebuilds

After you have used it once there are these features:

In the script you can modify these variables to skip certain modules being built again.

~~~
skip_zlib='no'
skip_icu='no'
skip_openssl='no'
skip_boost_build='no'
skip_boost='no'
skip_qtbase='no'
skip_qttools='no'
skip_libtorrent='no'
skip_qbittorrent='no'
~~~

Then the script accepts a single module name as a positional parameter to override a skipped module.

~~~
./qbittorrent-nox-static.sh zlib
~~~

Current modules accepted as the first argument after the script name.

~~~
zlib
icu
openssl
boost_build
boost
qtbase
qtmake
libtorrent
qbittorrent
~~~

## How to download and install static builds as a non root user:

Debian 10 (buster) - amd64:

~~~
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://git.io/JvfCB
chmod 700 ~/bin/qbittorrent-nox
~~~

Debian 10 (buster) - arm64:

~~~
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://git.io/JvfCB
chmod 700 ~/bin/qbittorrent-nox
~~~

Now you just run it and enjoy!

~~~
qbittorrent-nox
~~~

Ubuntu 18.04 - amd64:

~~~
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://git.io/JvfC0
chmod 700 ~/bin/qbittorrent-nox
~~~

Ubuntu 18.04 - arm64:

~~~
mkdir -p ~/bin && source ~/.profile
wget -qO ~/bin/qbittorrent-nox https://git.io/JvfC0
chmod 700 ~/bin/qbittorrent-nox
~~~

Now you just run it and enjoy!

~~~
qbittorrent-nox
~~~

## Credits

Inspired by these gists

https://gist.github.com/notsure2