#!/bin/sh

# OS detection code from http://stackoverflow.com/questions/394230/detect-the-os-from-a-bash-script
lowercase(){
	echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

OS=`lowercase \`uname\``
KERNEL=`uname -r`
MACH=`uname -m`

if [ "{$OS}" == "windowsnt" ]; then
	OS=windows
elif [ "{$OS}" == "darwin" ]; then
	OS=osx
else
	OS=`uname`
	if [ "${OS}" = "SunOS" ] ; then
		OS=Solaris
		ARCH=`uname -p`
		OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
	elif [ "${OS}" = "AIX" ] ; then
		OSSTR="${OS} `oslevel` (`oslevel -r`)"
	elif [ "${OS}" = "Linux" ] ; then
		if [ -f /etc/redhat-release ] ; then
			DistroBasedOn='RedHat'
			DIST=`cat /etc/redhat-release |sed s/\ release.*//`
			PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
			REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
		elif [ -f /etc/SuSE-release ] ; then
			DistroBasedOn='SuSe'
			PSUEDONAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
			REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
		elif [ -f /etc/mandrake-release ] ; then
			DistroBasedOn='Mandrake'
			PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
			REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
		elif [ -f /etc/debian_version ] ; then
			DistroBasedOn='Debian'
			DIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
			PSUEDONAME=`cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }'`
			REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
		fi
		if [ -f /etc/UnitedLinux-release ] ; then
			DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
		fi
		if [ -f /etc/arch-release ] ; then
			DIST="arch"
		fi
		OS=`lowercase $OS`
		DistroBasedOn=`lowercase $DistroBasedOn`
		readonly OS
		readonly DIST
		readonly DistroBasedOn
		readonly PSUEDONAME
		readonly REV
		readonly KERNEL
		readonly MACH
	fi
fi

echo "Powerline installation wizard"
echo "-----------------------------"
echo
echo "Detected OS: $OS"
echo "Detected dist: $DIST"
echo

if [[ "$OS" != "osx" && "$OS" != "linux" ]]; then
	echo "Your OS is not supported by this installation script."
	echo "Please see https://powerline.readthedocs.org/en/latest/index.html for manual installation instructions."
	exit 1
fi

if [[ "$DIST" == "arch" ]]; then
	echo "Powerline is installable from the AUR:"
	echo "- python2-powerline-git"
	echo "- python-powerline-git"
	exit 0
fi

echo -en "Do you want to use the custom arrows and symbols? [Y/n] "
read -e -n1 YESNO
case $YESNO in
	[yY]) USE_CUSTOM_SYMBOLS=1 ;;
	[nN]) USE_CUSTOM_SYMBOLS=0 ;;
	*)    USE_CUSTOM_SYMBOLS=1 ;;
esac

echo
echo -en "Please select the applications you want to enable Powerline in:\n"
echo -en "\tvim  [Y/n] "
read -e -n1 YESNO
case $YESNO in
	[yY]) ENABLE_APP_VIM=1 ;;
	[nN]) ENABLE_APP_VIM=0 ;;
	*)    ENABLE_APP_VIM=1 ;;
esac

if [[ "$OS" == "osx" ]]; then
	echo -en "\tMacVim [Y/n] "
else
	echo -en "\tGvim [Y/n] "
fi
read -e -n1 YESNO
case $YESNO in
	[yY]) ENABLE_APP_GVIM=1 ;;
	[nN]) ENABLE_APP_GVIM=0 ;;
	*)    ENABLE_APP_GVIM=1 ;;
esac

echo -en "\tbash [y/N] "
read -e -n1 YESNO
case $YESNO in
	[yY]) ENABLE_APP_BASH=1 ;;
	[nN]) ENABLE_APP_BASH=0 ;;
	*)    ENABLE_APP_BASH=0 ;;
esac

echo -en "\tzsh  [y/N] "
read -e -n1 YESNO
case $YESNO in
	[yY]) ENABLE_APP_ZSH=1 ;;
	[nN]) ENABLE_APP_ZSH=0 ;;
	*)    ENABLE_APP_ZSH=0 ;;
esac

echo -en "\ttmux [y/N] "
read -e -n1 YESNO
case $YESNO in
	[yY]) ENABLE_APP_TMUX=1 ;;
	[nN]) ENABLE_APP_TMUX=0 ;;
	*)    ENABLE_APP_TMUX=0 ;;
esac

if [[ $USE_CUSTOM_SYMBOLS -eq 1 ]]; then
	echo
	echo "Please choose your terminal emulator:"
	if [[ "$OS" == "linux" ]]; then
		echo -e "\t[1] Gnome Terminal"
		echo -e "\t[2] Konsole"
		echo -e "\t[3] lxterminal"
		echo -e "\t[4] rxvt-unicode"
		echo -e "\t[5] st"
		echo -e "\t[6] Xfce Terminal"
		echo -e "\t[7] xterm"
		echo -en "Terminal emulator number or enter to skip: "

		read -e -n1 TERM_EMULATOR
		case $TERM_EMULATOR in
			1) TERM_EMULATOR="gnome-terminal" ;;
			2) TERM_EMULATOR="konsole" ;;
			3) TERM_EMULATOR="lxterminal" ;;
			4) TERM_EMULATOR="rxvt-unicode" ;;
			5) TERM_EMULATOR="st" ;;
			6) TERM_EMULATOR="xfce-terminal" ;;
			7) TERM_EMULATOR="xterm" ;;
			*) TERM_EMULATOR="" ;;
		esac
	elif [[ "$OS" == "darwin" ]]; then
		echo -e "\t[1] iTerm2"
		echo -e "\t[2] Terminal.app"
		echo -en "Terminal emulator number or enter to skip: "

		read -e -n1 TERM_EMULATOR
		case $TERM_EMULATOR in
			1) TERM_EMULATOR="iterm2" ;;
			2) TERM_EMULATOR="terminal.app" ;;
			*) TERM_EMULATOR="" ;;
		esac
	fi
fi

if [[ ($ENABLE_APP_VIM -eq 1 || $ENABLE_APP_GVIM -eq 1)
	&& $ENABLE_APP_BASH -eq 0
	&& $ENABLE_APP_ZSH -eq 0
	&& $ENABLE_APP_TMUX -eq 0 ]]; then
	echo -en "Only vim is selected, do you want to install Powerline as a vim bundle? [Y/n] "

	read -e -n1 YESNO
	case $YESNO in
		[yY]) USE_VIM_BUNDLE=1 ;;
		[nN]) USE_VIM_BUNDLE=0 ;;
		*)    USE_VIM_BUNDLE=1 ;;
	esac

	if [[ $USE_VIM_BUNDLE -eq 1 ]]; then
		echo -en "Are you using Vundle? [y/N] "

		read -e -n1 YESNO
		case $YESNO in
			[yY]) USE_VIM_BUNDLE_VUNDLE=1 ;;
			[nN]) USE_VIM_BUNDLE_VUNDLE=0 ;;
			*)    USE_VIM_BUNDLE_VUNDLE=0 ;;
		esac
	fi
fi

echo
echo "The following operations will be performed:"
if [[ $USE_CUSTOM_SYMBOLS -eq 1 ]]; then     echo "- Use custom arrows and symbols"; fi
if [[ $ENABLE_APP_VIM -eq 1 ]]; then         echo "- Enable vim support"; fi
if [[ $ENABLE_APP_GVIM -eq 1 ]]; then        echo "- Enable Gvim support"; fi
if [[ $ENABLE_APP_BASH -eq 1 ]]; then        echo "- Enable bash support"; fi
if [[ $ENABLE_APP_ZSH -eq 1 ]]; then         echo "- Enable zsh support"; fi
if [[ $ENABLE_APP_TMUX -eq 1 ]]; then        echo "- Enable tmux support"; fi
if [[ $USE_VIM_BUNDLE -eq 1 ]]; then         echo "- Install as a vim bundle"; fi
if [[ $USE_VIM_BUNDLE_VUNDLE -eq 1 ]]; then  echo "- Install as a Vundle bundle"; fi
if [[ "$TERM_EMULATOR" != "" ]]; then        echo "- Enable terminal emulator support for $TERM_EMULATOR"; fi

echo
echo -n "Please confirm [Y/n] "
read -e -n1 YESNO
case $YESNO in
	[yY]) CONFIRM=1 ;;
	[nN]) CONFIRM=0 ;;
	*)    CONFIRM=1 ;;
esac

# ----------

if [[ $USE_CUSTOM_SYMBOLS -eq 1 ]]; then
	FONT_METHOD=""
	case $TERM_EMULATOR in
		"gnome-terminal" | "konsole" | "lxterminal" | "st" | "xfce-terminal")
			FONT_METHOD="fontconfig"
			;;
		"xterm" | "iterm2" | "terminal.app")
			FONT_METHOD="patched"
			;;
		"rxvt-unicode")
			FONT_METHOD="special-urxvt"
			;;
	esac
	if [[ $ENABLE_APP_GVIM -eq 1 ]]; then
		FONT_METHOD="patched"
	fi

	echo "Using custom symbols: $FONT_METHOD"

	case $FONT_METHOD in
		"fontconfig")
			if [[ -d "~/.config/fontconfig/conf.d" ]]; then
				echo "New fontconfig"
			elif [[ -d "~/.fonts.conf.d" ]]; then
				echo "Old fontconfig"
			else
				echo "No fontconfig!"
			fi
			;;
		"patched")
			if [[ -d "~/.fonts" ]]; then
				echo "Home font dir"
			elif [[ -d "/usr/share/fonts" ]]; then
				echo "Global font dir"
			else
				echo "Unknown font dir!"
			fi
			;;
		"special-urxvt")
			URXVT_UNICODE3_SUPPORT=`urxvt -help | grep unicode3`
			;;
	esac
fi

if [[ $ENABLE_APP_VIM -eq 1 || $ENABLE_APP_GVIM -eq 1 ]]; then
	echo "Enabling vim/gvim support"
fi

if [[ $ENABLE_APP_BASH -eq 1 ]]; then
	echo "Enabling bash support"
fi

if [[ $ENABLE_APP_ZSH -eq 1 ]]; then
	echo "Enabling zsh support"
fi

if [[ $ENABLE_APP_TMUX -eq 1 ]]; then
	echo "Enabling tmux support"
fi

if [[ $USE_VIM_BUNDLE -eq 1 ]]; then
	if [[ $USE_VIM_BUNDLE_VUNDLE -eq 1 ]]; then
		echo "Using Vundle"
		echo "Please run :BundleInstall after launching vim."
	else
		echo "Using Bundle"
	fi
fi
