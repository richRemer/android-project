include app.mk
include mk/build.mk

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
	$(aapt) package -fmJ $(gen) -S $(res) -M $< -I $(PLATFORM_JAR)

$(obj)/%.class: $(src)/%.java $(R.java)
	$(javac) -d $(obj) -g $^

$(classes): $(objects)
	$(dx) --dex --output $@ $(obj)

$(unaligned_apk): AndroidManifest.xml $(classes)
	$(aapt) package -fM $< -S $(res) -I $(PLATFORM_JAR) -F $@ $(dex)

$(aligned_apk): $(unaligned_apk)
	$(zipalign) -fp 4 $< $@

$(signed_apk): $(aligned_apk) $(keystore)
	$(apksigner) sign -ks $(keystore) --ks-key-alias androidkey --out $(signed_apk) $<

.PHONY: default build sign install clean distclean
