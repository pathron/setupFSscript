#!/bin/sh

# A very simple script containing the set-up commands to get
# FlexibleSUSY up and running on coepp14.physics.adelaide.edu.au.
# There are two optional arguments:
#   --with-flexisusy-dir=/path/to/desired/flexibleSUSY/dir
#   --with-sarah-dir=/path/to/desired/sarah/dir
# Make sure you have write/execute permissions for those
# directories (or, if they are not specified, the directory
# in which this script is located).

# Location of this script - ideally should be your home directory.
BASEDIR=$(dirname $0)
ABSDIR=$(cd -- "${BASEDIR}"; pwd)

# Location script is called from.
CURRENTDIR=$(pwd)

# url for the current master branch on GitHub
# (using FlexibleSUSY/FlexibleSUSY).
flexisusydir="${CURRENTDIR}"
flexisusyurl="git://github.com/FlexibleSUSY/FlexibleSUSY.git"

# SARAH version to install if needed.
sarahmajor=4
sarahminor=2
sarahpatch=1
sarahversion="${sarahmajor}.${sarahminor}.${sarahpatch}"

required_sarah_major="4"
required_sarah_minor="0"
required_sarah_patch="4"
required_sarah_version="${required_sarah_major}.${required_sarah_minor}.${required_sarah_patch}"

sarahdir=""
sarahurl="http://www.hepforge.org/archive/sarah/SARAH-${sarahversion}.tar.gz"

#_______________________________________________________
help() {
cat<<EOF
Usage: ./`basename $0` [options]
Options:

  --help,-h                     Print this help message and exit.

By default, FlexibleSUSY will be installed in the current directory,
in a new directory called FlexibleSUSY. If not already installed,
SARAH will usually be set up in the 
/home/<user>/.Mathematica/Applications/ directory.

You may change the location in which FlexibleSUSY and/or SARAH are
installed using the options

  --with-flexisusy-dir=[path]   Path to the desired location to create
                                FlexibleSUSY directory in.
  --with-sarah-dir=[path]       Path to the desired location to create
                                SARAH directory in.
EOF
}

trap "exit 1" INT QUIT TERM

# Parse command line arguments
if test $# -gt 0 ; then
    while [ ! "x$1" = "x" ] ; do
	case "$1" in
	    -*=*) optarg=`echo "$1" | sed 's/[-_a-zA-Z0-9]*=//'` ;;
	    *) optarg= ;;
	esac

	case $1 in
	    --with-flexisusy-dir=*) flexisusydir=${optarg} ;;
	    --with-sarah-dir=*) sarahdir=${optarg} ;;
	    --help|-h) help; exit 0 ;;
	    *) echo "Invalid option '$1'. For usage, try $0 --help" ; exit 1 ;;
	esac

	shift
    done
fi

# Get absolute path to requested FlexibleSUSY install location.
if (! cd -- "${flexisusydir}" 2> /dev/null ) ; then
    echo "WARNING: ${flexisusydir} does not exist. Create it? [y/n]"
    read response
    while [ ! "${response}" = "y" -a ! "${response}" = "n" ] ; do
	echo "Please enter y or n:"
	read response
    done

    if [ "${response}" = "y" ] ; then
	mkdir -p -- "${flexisusydir}"
	# Extra check to make sure that creating the directory worked.
	if (! cd -- "${flexisusydir}") ; then
	    echo "Error creating new directory. Exiting set-up script."
	    exit 1
	fi
    else
	echo "Exiting set-up script. Try again with a valid location."
	exit 0
    fi
fi

flexisusydir=$(cd -- "${flexisusydir}" ; pwd)
flexisusydir="${flexisusydir}/FlexibleSUSY"

# Need to check if FlexibleSUSY directory is already present
# at the specified location. Cloning the repository won't work
# if something called FlexibleSUSY is present in the directory, but
# is not itself an empty directory.
if [ ! -e "${flexisusydir}" ] ; then
    git clone "${flexisusyurl}" "${flexisusydir}"
    if [ $? -eq 0 ] ; then
	echo "FlexibleSUSY repository cloned. Checking for SARAH..."
	# Here is where we'd switch to the master branch, but
	# while we are using the development branch we don't need to 
	# do this...
	# Switch to master branch
	#cd -- "${flexisusydir}"
	#git fetch origin master:master
	#git checkout master
	#cd -- "${CURRENTDIR}"
    else
	echo "Error occurred cloning repository. Exiting set-up script."
	exit 1
    fi
else
    # We can clone so long as the FlexibleSUSY present is just
    # an empty directory.
    if [ "$(ls -A -- "${flexisusydir}")" ] ; then
	echo "ERROR: ${flexisusydir} is not an empty directory."
	echo "Exiting set-up script. Try again with a valid location."
	exit 1
    else
	git clone "${flexisusyurl}" "${flexisusydir}"
	if [ $? -eq 0 ] ; then
	    echo "FlexibleSUSY repository cloned. Checking for SARAH..."
	 #   cd -- "${flexisusydir}"
	 #   git fetch origin master:master
	 #   git checkout master
	 #   cd -- "${CURRENTDIR}"
	else
	    echo "Error occurred cloning repository. Exiting set-up script."
	    exit 1
	fi
    fi
fi


# Next we make sure Mathematica and SARAH are set up.
# This code is just out of the FlexibleSUSY configure script.
# If we can pass this then FlexibleSUSY should be properly set-up.
# Mathematica is already installed on coepp14, so no need to check that
# it is present. Check for SARAH instead.

sarahtest="${flexisusydir}/sarahtest"
userbasedirtest="${flexisusydir}/userbasedirtest"

rm -f "${sarahtest}" "${userbasedirtest}"

math <<EOF >/dev/null
Export["${userbasedirtest}", \$UserBaseDirectory, "String"];
Quit[0]
EOF

# Read base directory for Mathematica.
userbasedir=`cat ${userbasedirtest}`

math <<EOF >/dev/null
Needs["SARAH\`"];
If[!ValueQ[SA\`Version], Quit[1]];
Export["${sarahtest}", SA\`Version, "String"];
Quit[0]
EOF

_sarah_is_available="$?"
if test "x${_sarah_is_available}" = "x0" ; then
    if test -r "${sarahtest}" ; then
	SARAH_VERSION=`cat ${sarahtest}`
	SARAH_MAJOR=`echo ${SARAH_VERSION} | awk -F . '{ print $1 }'`
	SARAH_MINOR=`echo ${SARAH_VERSION} | awk -F . '{ print $2 }'`
	SARAH_PATCH=`echo ${SARAH_VERSION} | awk -F . '{ print $3 }'`
	if test \
	    \( "${SARAH_MAJOR}" -lt "${required_sarah_major}" \) -o \
	    \( \( "${SARAH_MAJOR}" -eq "${required_sarah_major}" \) -a \
	    \( "${SARAH_MINOR}" -lt "${required_sarah_minor}" \) \) -o \
	    \( \( "${SARAH_MAJOR}" -eq "${required_sarah_major}" \) -a \
	    \( "${SARAH_MINOR}" -eq "${required_sarah_minor}" \) -a \
	    \( "${SARAH_PATCH}" -lt "${required_sarah_patch}" \) \)
	then
	    echo "WARNING: installed SARAH version is out-of date."
	    echo "Install updated version? [y/n]"
	    read sarahresponse
	    while [ ! "${sarahresponse}" = "y" -a ! "${sarahresponse}" = "n" ] ; do
		echo "Please enter y or n:"
		read sarahresponse
	    done
	    if [ "${sarahresponse}" = "y" ] ; then
		echo "Installing SARAH-${sarahversion}"
		if [ ! "${sarahdir}" ] ; then
		    sarahinstalldir="${userbasedir}/Applications/"
		else
		    # Check the requested directory exists and get absolute path
		    if (! cd -- "${sarahdir}" 2> /dev/null ) ; then
			echo "WARNING: ${sarahdir} does not exist. Create it? [y/n]"
			read response
			while [ ! "${response}" = "y" -a ! "${response}" = "n" ] ; do
			    echo "Please enter y or n:"
			    read response
			done
			
			if [ "${response}" = "y" ] ; then
			    mkdir -p -- "${sarahdir}"
			    # Extra check to make sure that creating the directory worked.
			    if (! cd -- "${sarahdir}") ; then
				echo "Error creating new directory. Exiting set-up script."
				rm -f "${sarahtest}" "${userbasedirtest}"
				exit 1
			    fi
			else
			    echo "Exiting set-up script. Try again with a valid location."
			    rm -f "${sarahtest}" "${userbasedirtest}"
			    exit 0
			fi
		    fi

		    sarahdir=$(cd -- "${sarahdir}" ; pwd)
		    sarahinstalldir="${sarahdir}"
		fi
		# Install to Mathematica base directory
		if [ ! -e "${sarahinstalldir}/SARAH-${sarahversion}" ] ; then
		    wget "${sarahurl}" -O "${sarahinstalldir}/SARAH-${sarahversion}.tar.gz"
		    if [ $? -eq 0 ] ; then
			cd -- "${sarahinstalldir}"
			gunzip "SARAH-${sarahversion}.tar.gz"
			tar -xf "SARAH-${sarahversion}.tar"
			rm "SARAH-${sarahversion}.tar"
			# Also append the location of this directory to init.m
			sarahload="AppendTo[\$Path, FileNameJoin[{\"${sarahinstalldir}\", \"SARAH-${sarahversion}\"}]]"
			cat "${userbasedir}/Kernel/init.m" | sed '$a\'"${sarahload}" > "${userbasedir}/Kernel/init2.m"
			mv "${userbasedir}/Kernel/init2.m" "${userbasedir}/Kernel/init.m"	    
			cd "${CURRENTDIR}"
			rm -f "${sarahtest}" "${userbasedirtest}"
			echo "SARAH-${sarahversion} installed in ${sarahinstalldir}"
			echo "Set-up complete."
			exit 0
		    else
			echo "Error downloading SARAH-${sarahversion}. Exiting set-up script."
			rm -f "${sarahtest}" "${userbasedirtest}"
			exit 1
		    fi
		else
		    echo "ERROR: ${sarainstalldir}/SARAH-${sarahversion} already exists."
		    echo "Check that Mathematica is correctly loading SARAH."
		    echo "Exiting set-up script."
		    rm -f "${sarahtest}" "${userbasedirtest}"
		    exit 1
		fi
	    else
		echo "Exiting set-up script."
		echo "Use the configure option --disable-meta to run without SARAH."
		rm -f "${sarahtest}" "${userbasedirtest}"
		exit 0
	    fi
	else
	    echo "SARAH is installed and up-to-date."
	    echo "Set-up complete!"
	    rm -f "${sarahtest}" "${userbasedirtest}"
	    exit 0
	fi
    else
	echo "ERROR: cannot check SARAH version."
	rm -f "${sarahtest}" "${userbasedirtest}"
	exit 1
    fi
else
    echo "WARNING: SARAH is not installed correctly."
    echo "Install SARAH? [y/n]"
    read sarahresponse
    while [ ! "${sarahresponse}" = "y" -a ! "${sarahresponse}" = "n" ] ; do
	echo "Please enter y or n:"
	read sarahresponse
    done
    if [ "${sarahresponse}" = "y" ] ; then
	echo "Installing SARAH-${sarahversion}"
	if [ ! "${sarahdir}" ] ; then
	    sarahinstalldir="${userbasedir}/Applications"
	else
	    # Check the requested directory exists and get absolute path
	    if (! cd -- "${sarahdir}" 2> /dev/null ) ; then
		echo "WARNING: ${sarahdir} does not exist. Create it? [y/n]"
		read response
		while [ ! "${response}" = "y" -a ! "${response}" = "n" ] ; do
		    echo "Please enter y or n:"
		    read response
		done
		
		if [ "${response}" = "y" ] ; then
		    mkdir -p -- "${sarahdir}"
		    # Extra check to make sure that creating the directory worked.
		    if (! cd -- "${sarahdir}") ; then
			echo "Error creating new directory. Exiting set-up script."
			rm -f "${sarahtest}" "${userbasedirtest}"
			exit 1
		    fi
		else
		    echo "Exiting set-up script. Try again with a valid location."
		    rm -f "${sarahtest}" "${userbasedirtest}"
		    exit 0
		fi
	    fi
	    
	    sarahdir=$(cd -- "${sarahdir}" ; pwd)
	    sarahinstalldir="${sarahdir}"
	fi
	# Install to Mathematica base directory
	if [ ! -e "${sarahinstalldir}/SARAH-${sarahversion}" ] ; then
	    wget "${sarahurl}" -O "${sarahinstalldir}/SARAH-${sarahversion}.tar.gz"
	    if [ $? -eq 0 ] ; then
		cd -- "${sarahinstalldir}"
		gunzip "SARAH-${sarahversion}.tar.gz"
		tar -xf "SARAH-${sarahversion}.tar"
		rm "SARAH-${sarahversion}.tar"
		# Also append the location of this directory to init.m
		sarahload="AppendTo[\$Path, FileNameJoin[{\"${sarahinstalldir}\", \"SARAH-${sarahversion}\"}]]"
		cat "${userbasedir}/Kernel/init.m" | sed '$a\'"${sarahload}" > "${userbasedir}/Kernel/init2.m"
		mv "${userbasedir}/Kernel/init2.m" "${userbasedir}/Kernel/init.m"	    
		cd "${CURRENTDIR}"
		rm -f "${sarahtest}" "${userbasedirtest}"
		echo "SARAH-${sarahversion} installed in ${sarahinstalldir}"
		echo "Set-up complete."
		exit 0
	    else
		echo "Error downloading SARAH-${sarahversion}. Exiting set-up script."
		rm -f "${sarahtest}" "${userbasedirtest}"
		exit 1
	    fi
	else
	    echo "ERROR: ${sarainstalldir}/SARAH-${sarahversion} already exists."
	    echo "Check that Mathematica is correctly loading SARAH."
	    echo "Exiting set-up script."
	    rm -f "${sarahtest}" "${userbasedirtest}"
	    exit 1
	fi
    else
	echo "Exiting set-up script."
	echo "Use the configure option --disable-meta to run without SARAH."
	rm -f "${sarahtest}" "${userbasedirtest}"
	exit 0
    fi
fi


