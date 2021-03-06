#!/bin/bash

basedir=$(dirname $(dirname $(readlink -fm $0)))

source $basedir/bin/java-config.sh

# convert the jar files from an existing I2P build into modules suitable for use with jlink
$basedir/bin/convert-jars-to-modules.sh

# compile the Main class that starts the I2P router and SAM listener
echo "*** Compiling Main class"
$JAVA_HOME/bin/javac --module-path import/lib -d target/classes $(find src -name '*.java')

# package as a modular jar
echo "*** Packaging as a modular jar"
$JAVA_HOME/bin/jar --create --file target/org.getmonero.i2p.embedded.jar --main-class org.getmonero.i2p.embedded.Main -C target/classes .

rm -fr $basedir/dist
mkdir -p $basedir/dist/linux $basedir/dist/mac $basedir/dist/win

# create OS specific launchers which will bundle together the code and a minimal JVM
echo "*** Performing jlink (Linux)"
$JAVA_HOME/bin/jlink --module-path $basedir/import/jdks/linux/jdk-${JDK_VERSION}/jmods:target/modules:target/org.getmonero.i2p.embedded.jar --add-modules org.getmonero.i2p.embedded --output dist/linux/router --strip-debug --compress 2 --no-header-files --no-man-pages

echo "*** Performing jlink (Mac)"
$JAVA_HOME/bin/jlink --module-path $basedir/import/jdks/mac/jdk-${JDK_VERSION}.jdk/Contents/Home/jmods:target/modules:target/org.getmonero.i2p.embedded.jar --add-modules org.getmonero.i2p.embedded --output dist/mac/router --strip-debug --compress 2 --no-header-files --no-man-pages

echo "*** Performing jlink (Windows)"
$JAVA_HOME/bin/jlink --module-path $basedir/import/jdks/win/jdk-${JDK_VERSION}/jmods:target/modules:target/org.getmonero.i2p.embedded.jar --add-modules org.getmonero.i2p.embedded --output dist/win/router --strip-debug --compress 2 --no-header-files --no-man-pages


cp $basedir/resources/launch.sh $basedir/dist/linux/router/bin/
cp $basedir/resources/launch.sh $basedir/dist/mac/router/bin/
cp $basedir/resources/launch.bat $basedir/dist/win/router/bin/

for i in linux mac win; do cp -r $basedir/import/i2p.base $basedir/dist/$i/router/; done
for i in linux mac win; do mkdir -p $basedir/dist/$i/router/i2p.config; done

# remove unnecessary native libs from jbigi.jar
for i in linux mac win; do
  for j in freebsd linux mac win; do
    if [ "$i" != "$j" ]; then
      if [ "$j" = "mac" ]; then j="osx"; fi
      if [ "$j" = "win" ]; then j="windows"; fi
      zip -d $basedir/dist/$i/router/i2p.base/jbigi.jar *-${j}-*
    fi
  done
done

du -sk dist/* | awk '{printf "%.1f MB %s\n",$1/1024,$2}'

echo "*** Done ***"
echo "To run, type: dist/linux/router/bin/launch.sh"
