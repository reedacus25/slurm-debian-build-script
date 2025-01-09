#!/bin/bash

#exit on error
set -e

SLURMVER="23.11.10"
SLURMURL="https://download.schedmd.com/slurm/slurm-$SLURMVER.tar.bz2"
SLURMMD5="https://download.schedmd.com/slurm/MD5"
WORKDIR="/tmp"
CODENAME="$(lsb_release -c | awk '{print $2}' | xargs)"

#array vars for cuda versioning and urls based on the release
declare -A OSVER
OSVER[focal]="2004"
OSVER[jammy]="2204"
OSVER[noble]="2404"

declare -A CUDAVER
CUDAVER[focal]="11.8.1"
CUDAVER[jammy]="12.4.1"
CUDAVER[noble]="12.6.3"

declare -A CUDAVER2
CUDAVER2[focal]="11-8"
CUDAVER2[jammy]="12-4"
CUDAVER2[noble]="12-6"

#nvidia repo
curl -s -o /tmp/nvidia.pub https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${OSVER[$CODENAME]}/x86_64/3bf863cc.pub
echo "deb [signed-by=/etc/apt/trusted.gpg.d/nvidia.pub]  http://developer.download.nvidia.com/compute/cuda/repos/ubuntu${OSVER[$CODENAME]}/x86_64/ ./" > /tmp/nvidia.list
sudo mv /tmp/nvidia.pub /etc/apt/trusted.gpg.d/nvidia.pub
sudo mv /tmp/nvidia.list /etc/apt/sources.list.d/nvidia.list

#install base dependencies, including nvidia nvml
#protip: cuda-cudart-dev-${CUDAVER2[$CODENAME]} cuda-nvml-dev-${CUDAVER2[$CODENAME]} are the secret sauce to getting nvml working in the packages
sudo apt-get update
sudo apt-get -y install build-essential fakeroot devscripts equivs automake checkinstall libhwloc-dev liblua5.3-dev libmunge-dev libmysqlclient-dev libnuma-dev libssl-dev libbpf-dev libdbus-1-dev cuda-cudart-dev-${CUDAVER2[$CODENAME]} cuda-nvml-dev-${CUDAVER2[$CODENAME]} bzip2

#Download slurm tarball from web
cd $WORKDIR
curl -s -o slurm-$SLURMVER.tar.bz2 $SLURMURL

#verify md5 to make sure no corruption in transit
TARMD5="$(md5sum slurm-$SLURMVER.tar.bz2 | awk '{print $1}' | xargs)"
WEBMD5="$(curl -s $SLURMMD5 | grep $SLURMVER | awk '{print $1}' | xargs)"
if [[ "$TARMD5" == "$WEBMD5" ]] ; then
	echo "MD5 matches"
else
	echo "MD5 mismatch! Exiting..."
	exit 1
fi

#decompress tarball
tar -xaf slurm-$SLURMVER.tar.bz2
cd $WORKDIR/slurm-$SLURMVER

#add debian/ubuntu codename to version control file so that it is appended to the deb name so that multiple dists can be uploaded to aptly
sed -i -e "s/$SLURMVER-1/$SLURMVER-1$CODENAME/g" $WORKDIR/slurm-$SLURMVER/debian/changelog

sudo mk-build-deps -i --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' debian/control
sudo debuild -b -uc -us

#show built packages on exit
ls -lh $WORKDIR/*.deb
