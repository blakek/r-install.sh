#!/bin/bash

# This is boring... the least we can do is have nice colors!
white='\e[1;37m'
black='\e[0;30m'
blue='\e[0;34m'
light_blue='\e[1;34m'
green='\e[0;32m'
light_green='\e[1;32m'
cyan='\e[0;36m'
light_cyan='\e[1;36m'
red='\e[0;31m'
light_red='\e[1;31m'
purple='\e[0;35m'
light_purple='\e[1;35m'
brown='\e[0;33m'
yellow='\e[1;33m'
gray='\e[0;30m'
light_gray='\e[0;37m'
nocolor='\e[0m' # Text reset

pinfo() {
	printf "$blue$@$nocolor\n"
}

pwarn() {
	printf "$red$@$nocolor\n"
}

pokay() {
	printf "$green$@$nocolor\n"
}

is_installed() {
	hash "$@" 2> /dev/null && pokay "Found: $@"
}

xcode-select --install # made it work for Will. I didn't need this...

# If Homebrew (http://brew.sh/) is not installed, install it
is_installed brew || {
	pinfo 'Homebrew, a package manager for OS X is about to be installed.'
	pinfo 'All the defaults should be fine to use.'
	pinfo 'For more info, see http://brew.sh/'

	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

	brew doctor
}

# Let's start Homebrew updating in the background
brew update &
bu=$!

# If R (http://www.r-project.org/) is not installed, install it
is_installed r || {
	pinfo "Let's install R!"
	pinfo 'All downloaded packages will go to your Downloads folder.'
	pushd "$HOME/Downloads" > /dev/null

	pinfo 'R: downloading R dependency XQuartz'
	if [ ! -f 'XQuartz-2.7.7.dmg' ]; then
		curl -L#O 'http://xquartz.macosforge.org/downloads/SL/XQuartz-2.7.7.dmg'
	fi

	pinfo 'R: downloading R'
	if [ $(sw_vers -productVersion | awk -F. '/[0-9]/{i++}i==1{print $2; exit}') -ge 9 ]; then
		if [ ! -f 'R-3.1.3-mavericks.pkg' ]; then
			curl -L#O 'http://cran.r-project.org/bin/macosx/R-3.1.3-mavericks.pkg'
		fi
	else
		if [ ! -f 'R-3.1.3-snowleopard.pkg' ]; then
			curl -L#O 'http://cran.r-project.org/bin/macosx/R-3.1.3-snowleopard.pkg'
		fi
	fi

	pinfo 'Installing XQuartz'
	pwarn '(If asked) please type your password below; nothing will be shown as you type.'
	sudo installer -pkg /Volumes/XQuartz-2.7.7/XQuartz.pkg -target /

	pinfo 'Installing R'
	pwarn '(If asked) please type your password below; nothing will be shown as you type.'
	sudo installer -pkg ./R-3.1.3-*.pkg -target /

	popd > /dev/null
}

# We need pkg-config compiling the RGtk2 package for rattle
is_installed pkg-config || {
	pinfo "Let's install pkg-config!"

	pinfo 'Getting ready'
	wait $bu

	pinfo 'pkg-config: installing...'
	brew install pkg-config
}

# We need GTK 2.24.17 or higher for compiling the RGtk2 package for rattle
$(pkg-config --atleast-version=2.24.17 gtk+-2.0) || {
	pinfo 'Getting ready'
	wait $bu

	brew install gtk
}

# Set so pkg-config can find the libraries it needs
export PKG_CONFIG_PATH=/usr/X11/lib/pkgconfig/
for l in /usr/local/Cellar/*/*/lib/pkgconfig/; do
	export PKG_CONFIG_PATH=$l:$PKG_CONFIG_PATH
done

# install RGtk2
r --no-save <<< 'install.packages("RGtk2", repos="http://mirrors.nics.utk.edu/cran/", type="source")'

# install rattle
r --no-save <<< 'install.packages("rattle", repos="http://rattle.togaware.com", type="source")'

# run rattle to install more packages it wants
r --no-save <<< 'library(rattle)
rattle()
'

# If Homebrew ended up not being used, and it's still trying to update packages, let's wait on it to finish
pinfo 'Finishing up (you can safely quit this if needed)'
wait
