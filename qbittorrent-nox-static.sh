#! /usr/bin/env bash
#
# Copyright 2019 by userdocs and contributors
#
# SPDX-License-Identifier: Apache-2.0
#
# @author - userdocs
#
# @credits - https://gist.github.com/notsure2
#
## https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html 
#
set -e
#
## The installation is modular. You can select the parts you want or need here or using ./scriptname module
#
skip_zlib='no'
skip_icu='no'
skip_openssl='no'
skip_boost_build='no'
skip_boost='no'
skip_qtbase='no'
skip_qttools='no'
skip_libtorrent='no'
skip_qbittorrent='no'
#
## Set this to assume yes unless set to no by a dependency check.
#
deps_installed='yes'
#
## Check for required and optional dependencies
#
echo -e "\n\e[1mCore dependencies required to be installed by apt install\e[0m\n"
#
[[ "$(dpkg -s build-essential 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - build-essential" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - build-essential"; }
[[ "$(dpkg -s pkg-config 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - pkg-config" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - pkg-config"; }
[[ "$(dpkg -s automake 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - libtool" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - libtool"; }
[[ "$(dpkg -s git 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - git" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - git"; }
[[ "$(dpkg -s perl 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - perl" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - perl"; }
[[ "$(dpkg -s python 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - python" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - python"; }
[[ "$(dpkg -s python-dev 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - python-dev" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - python-dev"; }
#
## Check if user is able to install the depedencies, if yes then do so, if no then exit.
#
if [[ "$deps_installed" = 'no' ]]; then
	if [[ "$(id -un)" = 'root' ]]; then
		#
		echo -e "\n\e[32mUpdating\e[0m\n"
		#
		apt update -y
		apt upgrade -y
		apt autoremove -y
		#
		[[ -f /var/run/reboot-required ]] && { echo -e "\n\e[31mThis machine requires a reboot to continue installation. Please reboot now.\e[0m\n"; exit; } || :
		#
		echo -e "\n\e[32mInstalling required dependencies\e[0m\n"
		#
		apt install -y build-essential pkg-config automake libtool git perl python python-dev
		#
		echo -e "\n\e[32mDependencies installed!\e[0m\n"
		#
	else
		echo -e "\n\e[1mPlease request or install the missing core dependencies before using this script\e[0m"
		#
		echo -e '\napt install -y build-essential pkg-config automake libtool git perl python python-dev\n'
		#
		exit
	fi
fi
#
## All checks passed echo
#
if [[ "$deps_installed" = 'yes' ]]; then
	echo -e "\n\e[1mGood, we have all the core dependencies installed, continuing to build\e[0m\n"
fi
#
## The build and installation directory
#
export install_dir="$HOME/qbittorrent-build"
#
## post build install command via postional parameter.
#
if [[ "$1" = 'install' ]];then 
	if [[ -f "$install_dir/bin/qbittorrent-nox" ]]; then
		#
		if [[ "$(id -un)" = 'root' ]]; then
			mkdir -p "/usr/local/bin"
			cp -rf "$install_dir/bin/qbittorrent-nox" "/usr/local/bin"
		else
			mkdir -p "$HOME/bin"
			cp -rf "$install_dir/bin/qbittorrent-nox" "$HOME/bin"
		fi
		#
		echo -e 'qbittorrent-nox has been installed!\n'
		echo -e 'Run it using this command:\n'
		#
		[[ "$(id -un)" = 'root' ]] && echo -e '\e[32mqbittorrent-nox\e[0m\n' || echo -e '\e[32m~/bin/qbittorrent-nox\e[0m\n'
		#
		exit
	else
		echo -e "qbittorrent-nox has not been built to the defined install directory:\n"
		echo -e "\e[32m$install_dir\e[0m\n"
		echo -e "Please build it using the script first then install\n"
		#
		exit
	fi
fi
#
## Create the configured install directory.
#
mkdir -p "$install_dir"
#
## Set lib and include directory paths based on install path.
#
export include_dir="$install_dir/include"
export lib_dir="$install_dir/lib"
#
echo -e "Setting install prefix to - $install_dir\n"
#
## Set some build settings we need applied
#
export CXXFLAGS="-std=c++14"
export CPPFLAGS="-I$include_dir"
export LDFLAGS="-Wl,--no-as-needed -ldl -L$lib_dir -lpthread -pthread"
#
## Define some build specific variables
#
export PATH="$install_dir/bin:$HOME/bin${PATH:+:${PATH}}"
export LD_LIBRARY_PATH="-L$lib_dir"
export PKG_CONFIG_PATH="-L$lib_dir/pkgconfig"
export local_boost="--with-boost=$install_dir"
export local_openssl="--with-openssl=$install_dir"
#
## Define some URLs to download our apps. They are dynamic and set the most recent version or release.
#
export zlib_github_tag="$(curl -sNL https://github.com/madler/zlib/releases | grep -Pom1 'v1.2.([0-9]{1,2})')"
export zlib_url="https://github.com/madler/zlib/archive/$zlib_github_tag.tar.gz"
#
export icu_url="$(curl -sNL https://api.github.com/repos/unicode-org/icu/releases/latest | grep -Pom1 'ht(.*)icu4c(.*)-src.tgz')"
#
export openssl_github_tag="$(curl -sNL https://github.com/openssl/openssl/releases | grep -Pom1 'OpenSSL_1_1_([0-9][a-z])')"
export openssl_url="https://github.com/openssl/openssl/archive/$openssl_github_tag.tar.gz"
#
export boost_version="$(curl -sNL https://www.boost.org/users/download/ | sed -rn 's#(.*)e">Version (.*)</s(.*)#\2#p')"
export boost_url="https://dl.bintray.com/boostorg/release/$boost_version/source/boost_${boost_version//./_}.tar.gz"
export boost_github_tag="boost-$boost_version"
export boost_build_url="https://github.com/boostorg/build/archive/$boost_github_tag.tar.gz"
#
export qt_version='5.14'
export qt_github_tag="$(curl -sNL https://github.com/qt/qtbase/releases | grep -Pom1 "v$qt_version.([0-9]{1,2})")"
#
export libtorrent_github_tag="$(curl -sNL https://api.github.com/repos/arvidn/libtorrent/releases/latest | sed -rn 's#(.*)"tag_name": "(.*)",#\2#p')"
#
export qbittorrent_github_tag="$(curl -sNL https://github.com/qbittorrent/qBittorrent/releases | grep -Pom1 'release-([0-9]{1,4}\.?)+')"
#
## zlib installation
#
if [[ "$skip_zlib" = 'no' ||  "$1" = 'zlib' ]]; then
	echo -e "\e[32mInstalling zlib\e[0m"
	echo
	#
	file_zlib="$install_dir/zlib.tar.gz"
	#
	cd ~/ && [[ -f "$file_zlib" ]] && rm -rf {$(tar tf "$file_zlib" | grep -Pom1 "(.*)[^/]"),zlib.tar.gz}
	#
	wget -qO "$file_zlib" "$zlib_url"
	tar xf "$file_zlib" -C "$install_dir"
	cd "$install_dir/$(tar tf "$file_zlib" | head -1 | cut -f1 -d"/")"
	./configure --prefix="$install_dir" --static
	make -j$(nproc) CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS"
	make install
else
	echo "Skipping zlib library installation"
fi
#
## ICU installation
#
if [[ "$skip_icu" = 'no' || "$1" = 'icu' ]]; then
	echo -e "\n\e[32mInstalling icu\e[0m"
	echo
	#
	file_icu="$install_dir/icu.tar.gz"
	#
	cd ~/ && [[ -f "$file_icu" ]] && rm -rf {$(tar tf "$file_icu" | grep -Pom1 "(.*)[^/]"),icu.tar.gz}
	#
	wget -qO "$file_icu" "$icu_url"
	tar xf "$file_icu" -C "$install_dir"
	cd "$install_dir/$(tar tf "$file_icu" | head -1 | cut -f1 -d"/")/source"
	./configure --prefix="$install_dir" --disable-shared --enable-static CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS"
	make -j$(nproc)
	make install
else
	echo "Skipping icu library installation"
fi
#
## openssl installation
#
if [[ "$skip_openssl" = 'no' || "$1" = 'openssl' ]]; then
	echo -e "\n\e[32mInstalling openssl\e[0m"
	echo
	#
	file_openssl="$install_dir/openssl.tar.gz"
	#
	[[ -f "$file_openssl" ]] && rm -rf {$(tar tf "$file_openssl" | grep -Pom1 "(.*)[^/]"),openssl.tar.gz}
	#
	wget -qO "$file_openssl" "$openssl_url"
	tar xf "$file_openssl" -C "$install_dir"
	cd "$install_dir/$(tar tf "$file_openssl" | head -1 | cut -f1 -d"/")"
	./config --prefix="$install_dir" threads no-shared no-dso no-comp CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS"
	make -j$(nproc) 
	make install_sw install_ssldirs
else
	echo "Skipping openssl library installation"
fi
#
## boost build install
#
if [[ "$skip_boost_build" = 'no' ]] || [[ "$1" = 'boost_build' ]]; then
	echo -e "\n\e[32mInstalling boost build\e[0m"
	echo
	#
	file_boost_build="$install_dir/build.tar.gz"
	#
	[[ -f "$file_boost_build" ]] && rm -rf {$(tar tf "$file_boost_build" | grep -Pom1 "(.*)[^/]"),build.tar.gz}
	#
	wget -qO "$file_boost_build" "$boost_build_url"
	tar xf "$file_boost_build" -C "$install_dir"
	cd "$install_dir/$(tar tf "$file_boost_build" | head -1 | cut -f1 -d"/")"
	./bootstrap.sh
	./b2 install --prefix="$install_dir"
else
	echo "Skipping boost build installation"
fi
#
## boost libraries install
#
if [[ "$skip_boost" = 'no' ]] || [[ "$1" = 'boost' ]]; then
	echo -e "\n\e[32mInstalling boost libraries\e[0m"
	echo
	#
	file_boost="$install_dir/boost.tar.gz"
	#
	[[ -f "$file_boost" ]] && rm -rf {$(tar tf "$file_boost" | grep -Pom1 "(.*)[^/]"),boost.tar.gz}
	#
	wget -qO "$file_boost" "$boost_url"
	tar xf "$file_boost" -C "$install_dir"
	cd "$install_dir/$(tar tf "$file_boost" | head -1 | cut -f1 -d"/")"
	./bootstrap.sh
	"$install_dir/bin/b2" -j$(nproc) variant=release threading=multi link=static runtime-link=static cxxstd=14 cxxflags="$CXXFLAGS" cflags="$CPPFLAGS" linkflags="$LDFLAGS" toolset=gcc install --prefix="$install_dir"
else
	echo "Skipping boost libraries installation"
fi
#
## qt base install
#
if [[ "$skip_qtbase" = 'no' ]] || [[ "$1" = 'qtbase' ]]; then
	echo -e "\n\e[32mInstalling QT Base\e[0m"
	echo
	#
	folder_qtbase="$install_dir/qtbase"
	#
	[[ -d "$folder_qtbase" ]] && rm -rf "$folder_qtbase"
	#
	git clone --branch "$qt_github_tag" --single-branch --depth 1 https://github.com/qt/qtbase.git "$folder_qtbase"
	cd "$folder_qtbase"
	#
	./configure -prefix "$install_dir" -openssl-linked -static -opensource -confirm-license -release -c++std c++14 -no-shared -no-opengl -no-dbus -no-widgets -no-gui -no-compile-examples -I "$include_dir" -L "$lib_dir" QMAKE_LFLAGS="$LDFLAGS"
	make -j$(nproc)
	make install
else
	echo "Skipping qtbase installation"
fi
#
## qt tools install
#
if [[ "$skip_qttools" = 'no' ]] || [[ "$1" = 'qttools' ]]; then
	echo -e "\n\e[32mInstalling QT Tools\e[0m"
	echo
	#
	folder_qttools="$install_dir/qttools"
	#
	[[ -d "$folder_qttools" ]] && rm -rf "$folder_qttools"
	#
	git clone --branch "$qt_github_tag" --single-branch --depth 1 https://github.com/qt/qttools.git "$folder_qttools"
	cd "$folder_qttools"
	#
	"$install_dir/bin/qmake" -set prefix "$install_dir"
	"$install_dir/bin/qmake"
	make -j$(nproc)
	make install
else
	echo "Skipping qttools installation"
fi
#
## libtorrent install
#
if [[ "$skip_libtorrent" = 'no' ]] || [[ "$1" = 'libtorrent' ]]; then
	echo -e "\n\e[32mInstalling Libtorrent\e[0m"
	echo
	#
	folder_libtorrent="$install_dir/libtorrent"
	#
	[[ -d "$folder_libtorrent" ]] && rm -rf "$folder_libtorrent"
	#
	git clone --branch "$libtorrent_github_tag" --single-branch --depth 1 https://github.com/arvidn/libtorrent.git "$folder_libtorrent"
	cd "$folder_libtorrent"
	#
	./bootstrap.sh "$local_boost" "$local_openssl"
	"$install_dir/bin/b2" -j$(nproc) dht=on encryption=on crypto=openssl i2p=on extensions=on variant=release threading=multi link=static boost-link=static runtime-link=static cxxstd=14 cxxflags="$CXXFLAGS" cflags="$CPPFLAGS" linkflags="$LDFLAGS" toolset=gcc install --prefix="$install_dir"
else
	echo "Skipping libtorrent installation"
fi
#
## qbitorrent install (static)
#
if [[ "$skip_qbittorrent" = 'no' ]] || [[ "$1" = 'qbittorrent' ]]; then
	echo -e "\n\e[32mInstalling Qbitorrent\e[0m"
	echo
	#
	folder_qbittorrent="$install_dir/qbittorrent"
	#
	cd ~/ && [[ -d "$folder_qbittorrent" ]] && rm -rf "$folder_qbittorrent"
	#
	git clone --branch "$qbittorrent_github_tag" --single-branch --depth 1 https://github.com/qbittorrent/qBittorrent.git "$folder_qbittorrent"
	cd "$folder_qbittorrent"
	#
	./bootstrap.sh
	./configure --prefix="$install_dir" "$local_boost" --disable-gui CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS -l:libboost_system.a" openssl_CFLAGS="-I$include_dir" openssl_LIBS="-L$lib_dir -l:libcrypto.a -l:libssl.a" libtorrent_CFLAGS="-I$include_dir" libtorrent_LIBS="-L$lib_dir -l:libtorrent.a" zlib_CFLAGS="-I$include_dir" zlib_LIBS="-L$lib_dir -l:libz.a" QT_QMAKE=$install_dir/bin
	#
	sed -i 's/-lboost_system//' conf.pri
	sed -i 's/-lcrypto//' conf.pri
	sed -i 's/-lssl//' conf.pri
	#
	make -j$(nproc)
	make install
else
	echo "Skipping qbittorrent installation"
fi
#
## Cleanup and exit
#
if [[ "$2" != 'nodel' ]]; then
	#
	cd "$install_dir"
	#
	[[ -f "$file_zlib" ]] && rm -rf {$(tar tf "$file_zlib" | grep -Pom1 "(.*)[^/]"),zlib.tar.gz}
	[[ -f "$file_icu" ]] && rm -rf {$(tar tf "$file_icu" | grep -Pom1 "(.*)[^/]"),icu.tar.gz}
	[[ -f "$file_openssl" ]] && rm -rf {$(tar tf "$file_openssl" | grep -Pom1 "(.*)[^/]"),openssl.tar.gz}
	[[ -f "$file_boost_build" ]] && rm -rf {$(tar tf "$file_boost_build" | grep -Pom1 "(.*)[^/]"),build.tar.gz}
	[[ -f "$file_boost" ]] && rm -rf {$(tar tf "$file_boost" | grep -Pom1 "(.*)[^/]"),boost.tar.gz}
	[[ -d "$folder_qtbase" ]] && rm -rf "$folder_qtbase"
	[[ -d "$folder_qttools" ]] && rm -rf "$folder_qttools"
	[[ -d "$folder_libtorrent" ]] && rm -rf "$folder_libtorrent"
	[[ -d "$folder_qbittorrent" ]] && rm -rf "$folder_qbittorrent"
	#
fi
#
##
#
exit
