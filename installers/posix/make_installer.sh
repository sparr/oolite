#!/bin/sh


# 
# Original by Konstantinos Sykas <ksykas@gmail.com> (26-Mar-2011)
#
#        Type: shell script
#  Parameters: $1 - architecture (i.e. x86 or x86_64)
#              $2 - version with format maj.min.rev.svnrevision (e.g. 1.75.2.4492)
#              $3 - build mode (e.g. release, release-snapshot etc.)
#              $4 - (optional) defines a nightly build. All optional parameters 
#                   must follow after the mandatory parameters
# Description: Wrapper script for "makeself.sh". Prepares a clean build and 
#              generates the tarballs (e.g. docs, icons, libraries) to be 
#              packaged by "makeself.sh".
# 


make_rc=0
build_mode=$3
if [ "$build_mode" = "release-deployment" ] 
then
  make -f Makefile distclean   # force libraries clean build
else
  make -f Makefile clean
fi
make -f Makefile deps-$build_mode
make_rc=$?
if [ $make_rc -ne 0 ]
then
   exit $make_rc
fi

cpu_architecture=$1
oolite_version_extended=$2
if [ "$4" = "nightly" ]
then
  trunk="-trunk"
  oolite_version=$oolite_version_extended
else
  oolite_version=`echo $oolite_version_extended | awk -F"\." '{print $1"."$2}'`
  ver_rev=`echo $oolite_version_extended | cut -d '.' -f 3`
  if [ $ver_rev -ne 0 ]
  then
    oolite_version=${oolite_version}"."${ver_rev}
  fi
fi
oolite_app=oolite.app
setup_root=${oolite_app}/oolite.installer.tmp


echo
echo "Starting \"makeself\" packager..."
mkdir -p ${setup_root}

echo "Generating version info..."
echo ${oolite_version_extended} > ${setup_root}/release.txt

if [ "$build_mode" != "release-deployment" ]
then
  echo "Packing AddOns..."
  tar zcf ${setup_root}/addons.tar.gz AddOns/ --exclude .svn
fi

echo "Packing desktop menu files..."
cd installers/
tar zcf ../${setup_root}/freedesktop.tar.gz FreeDesktop/ --exclude .svn

echo "Packing $cpu_architecture architecture library dependencies..."
cd ../deps/Linux-deps/${cpu_architecture}/
tar zcf ../../../${setup_root}/oolite.deps.tar.gz lib/ --exclude .svn

echo "Packing documentation..."
cd ../../../Doc/
tar cf ../${setup_root}/oolite.doc.tar AdviceForNewCommanders.pdf OoliteReadMe.pdf OoliteRS.pdf CHANGELOG.TXT
cd ../deps/Linux-deps/
tar rf ../../${setup_root}/oolite.doc.tar README.TXT
gzip ../../${setup_root}/oolite.doc.tar

echo "Packing wrapper scripts and startup README..."
tar zcf ../../${setup_root}/oolite.wrap.tar.gz oolite.src oolite-update.src 

echo "Packing GNUstep DTDs..."
cd ../Cross-platform-deps/
tar zcf ../../${setup_root}/oolite.dtd.tar.gz DTDs --exclude .svn

echo "Copying setup script..."
cd ../../installers/posix/
cat setup.header > setup
if [ $trunk ] 
then
  echo "TRUNK=\"$trunk\"" >> setup
fi
cat setup.body >> setup
chmod +x setup
cp -p setup ../../${oolite_app}/.
cp -p uninstall.source ../../${oolite_app}/.


echo
./makeself.sh ../../${oolite_app} oolite${trunk}-${oolite_version}.${cpu_architecture}.run "Oolite${trunk} ${oolite_version} " ./setup $oolite_version
ms_rc=$?
if [ $ms_rc -eq 0 ] 
then 
  echo "It is located in the \"installers/posix/\" folder."
fi

exit $ms_rc