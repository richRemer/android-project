include env.mk

app_name = SomeApp
ns = us.remer.some
build = build
res = res
src = src

javac_opts = -source $(JAVA_VERSION) -target $(JAVA_VERSION) \
	-classpath $(ANDROID_JAR) -bootclasspath $(JAVA_HOME)/lib/jrt-fs.jar

dex = $(build)/dex
gen = $(build)/gen
obj = $(build)/obj
sig = $(build)/sig

nsdir = $(subst .,/,$(ns))
sources = $(shell find $(src) -type f -name \*.java)
objects = $(patsubst $(src)/%.java,$(obj)/%.class,$(sources))
resources = $(shell find $(res) -type f)
classes = $(dex)/classes.dex
unsigned_apk = $(build)/$(app_name).unsigned.apk
aligned_apk = $(build)/$(app_name).aligned.apk
signed_apk = $(build)/$(app_name).apk
keystore = $(sig)/keystore.jks

javac = $(JAVA_HOME)/bin/javac $(javac_opts)
keytool = $(JAVA_HOME)/bin/keytool
adb = $(ANDROID_TOOLS)/adb
aapt = $(SDK_TOOLS)/aapt
apksigner = $(SDK_TOOLS)/apksigner.jar
dx = $(SDK_TOOLS)/dx
zipalign = $(SDK_TOOLS)/zipalign

default: build

build: $(unsigned_apk)

clean:
	rm -rf $(dex)/* $(gen)/* $(obj)/* $(build)/*.apk

distclean: clean
	rm -rf $(sig)/*

install: $(signed_apk)
	$(adb) install -r $<

sign: $(signed_apk)

$(keystore):
	$(keytool) -genkeypair \
	  -keystore $@ -alias androidkey \
		-validity 10000 -keyalg RSA -keysize 2048

$(gen)/$(nsdir)/R.java: AndroidManifest.xml $(resources)
	$(aapt) package -fmJ $(gen) -S $(res) -M $< -I $(ANDROID_JAR)

$(obj)/%.class: $(src)/%.java $(gen)/$(nsdir)/R.java
	$(javac) -d $(obj) -g $^

$(classes): $(objects)
	$(dx) --dex --output $@ $(obj)

$(unsigned_apk): AndroidManifest.xml $(classes)
	$(aapt) package -fM $< -S $(res) -I $(ANDROID_JAR) -F $@ $(dex)

$(aligned_apk): $(unsigned_apk)
	$(zipalign) -fp 4 $< $@

$(signed_apk): $(aligned_apk) $(keystore)
	$(apksigner) sign -ks $(keystore) --ks-key-alias androidkey --out $(signed_apk) $<

.PHONY: default build clean distclean install sign
