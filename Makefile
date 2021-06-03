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

R.java = $(gen)/$(subst .,/,$(ns))/R.java
sources = $(shell find $(src) -type f -name \*.java)
objects = $(patsubst $(src)/%.java,$(obj)/%.class,$(sources))
resources = $(shell find $(res) -type f)
classes = $(dex)/classes.dex
unaligned_apk = $(build)/$(app_name).unaligned.apk
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

build: $(unaligned_apk)

sign: $(signed_apk)

install: $(signed_apk)
	$(adb) install -r $<

clean:
	rm -rf $(dex)/* $(gen)/* $(obj)/* $(build)/*.apk

distclean: clean
	rm -rf $(sig)/*

$(keystore):
	$(keytool) -genkeypair \
		-keystore $@ -alias androidkey \
		-validity 10000 -keyalg RSA -keysize 2048

$(R.java): AndroidManifest.xml $(resources)
	$(aapt) package -fmJ $(gen) -S $(res) -M $< -I $(ANDROID_JAR)

$(obj)/%.class: $(src)/%.java $(R.java)
	$(javac) -d $(obj) -g $^

$(classes): $(objects)
	$(dx) --dex --output $@ $(obj)

$(unaligned_apk): AndroidManifest.xml $(classes)
	$(aapt) package -fM $< -S $(res) -I $(ANDROID_JAR) -F $@ $(dex)

$(aligned_apk): $(unaligned_apk)
	$(zipalign) -fp 4 $< $@

$(signed_apk): $(aligned_apk) $(keystore)
	$(apksigner) sign -ks $(keystore) --ks-key-alias androidkey --out $(signed_apk) $<

.PHONY: default build clean distclean install sign
