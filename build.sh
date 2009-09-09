#! /bin/bash

LINK="http://downloads.sourceforge.net/project/pdfsam/pdfsam-enhanced/2.0.0e/pdfsam-2.0.0e-out-src.zip?use_mirror=garr"

cat <<EOD
Building pdfsam 2.0 enhanced from source:
 -> $LINK

Written in 2009 by Igor Kolar <igor.kolar@gmail.com>
Licensed under the EU Public License

EOD

# download
ZIP=$(echo "$LINK" | sed -re 's/\?.*//;' | xargs basename)
if [[ ! -f "$ZIP" ]]; then
	wget "$LINK"
else
	echo "Source already downloaded; remove '$ZIP' to force redownload"
fi

# unzip at both levels
WORKDIR="src"

MARK="$WORKDIR/__unzipping_done"
if [[ ! -f "$MARK" ]]; then
	rm -fr "$WORKDIR"
	mkdir -p "$WORKDIR"

	unzip "$ZIP" -d "$WORKDIR"
	for Z in $(find "$WORKDIR" -iname "*.zip"); do
		unzip $Z -d "$WORKDIR"
		rm -f "$Z"
	done
	touch $MARK
else
	echo "Source already unzipped; remove '$MARK' to force re-unzipping"	
fi

OUTDIR="out"
echo "Compiling sources to '$OUTDIR' .."
rm -fr "$OUTDIR"
mkdir -p "$OUTDIR"
find "$WORKDIR" -iname "*.java" > SOURCES
CP=$(find "$WORKDIR" -iname "*.jar" | tr '\n' ':')
javac -nowarn -cp "$CP" @SOURCES -d "$OUTDIR"
rm -f SOURCES
echo "  done"

# copy over resources (.properties files and such)
for R in $(find src -path "*src/java/*" -type f ! -name "*.java"); do
	RDEST="$OUTDIR/"$(echo "$R" | sed -re 's@.*src/java/@@' | xargs dirname)
	mkdir -p $RDEST
	cp $R "$RDEST" 	
done

# initial log4j, with warn threshold
cat > "$OUTDIR/log4j.xml" <<EOD
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE log4j:configuration SYSTEM "log4j.dtd">

<log4j:configuration xmlns:log4j="http://jakarta.apache.org/log4j/">
  <appender name="console" class="org.apache.log4j.ConsoleAppender"> 
    <param name="Target" value="System.out"/> 
    <layout class="org.apache.log4j.PatternLayout"> 
      <param name="ConversionPattern" value="%-5p %c{1} - %m%n"/> 
    </layout> 
  </appender> 

  <root> 
    <priority value ="warn" /> 
    <appender-ref ref="console" /> 
  </root>
  
</log4j:configuration>
EOD

# make jar
DISTDIR="dist"
rm -fr "$DISTDIR"; mkdir -p "$DISTDIR"

JAR="$DISTDIR/"$(echo "$ZIP" | sed -re 's/(zip)?$/jar/i')
cd $OUTDIR
echo "Building jar '$(dirname $0)/$JAR' .."
jar cf "../$JAR" *
cd ..

# deps
find "$WORKDIR" -name "*.jar" -exec cp {} "$DISTDIR/" \;
echo "All deps are now in '$DISTDIR'"

# test
echo "Running test: org.pdfsam.console.ConsoleClient -version .."
java -cp $(find . -name "*.jar" | tr '\n' ':'):. org.pdfsam.console.ConsoleClient -version

