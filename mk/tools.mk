javac_opts = -source $(JAVA_VERSION) -target $(JAVA_VERSION) \
	-classpath $(PLATFORM_JAR) -bootclasspath $(JAVA_HOME)/lib/jrt-fs.jar

javac = $(JAVA_HOME)/bin/javac $(javac_opts)
keytool = $(JAVA_HOME)/bin/keytool
adb = $(PLATFORM_TOOLS)/adb
aapt = $(SDK_TOOLS)/aapt
apksigner = $(SDK_TOOLS)/apksigner.jar
dx = $(SDK_TOOLS)/dx
zipalign = $(SDK_TOOLS)/zipalign
