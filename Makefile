APP_NAME = Sideboard
BUILD_DIR = build/Release
INSTALL_DIR = $(HOME)/Applications
DMG_NAME = $(APP_NAME).dmg
SIGN_IDENTITY = Developer ID Application: Just2us Pte Ltd (DNGV8KJAPW)
NOTARY_PROFILE = sideboard-notary

VERSION = $(shell xcodebuild -project $(APP_NAME).xcodeproj -scheme $(APP_NAME) -showBuildSettings 2>/dev/null | grep MARKETING_VERSION | tr -d ' ' | cut -d= -f2)

.PHONY: build install uninstall run clean sign notarize dmg release

build:
	xcodebuild -project $(APP_NAME).xcodeproj -scheme $(APP_NAME) -configuration Release build SYMROOT=build

install: build
	-@killall $(APP_NAME) 2>/dev/null || true
	mkdir -p $(INSTALL_DIR)
	cp -R $(BUILD_DIR)/$(APP_NAME).app $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"

uninstall:
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Uninstalled $(APP_NAME).app"

run: build
	open $(BUILD_DIR)/$(APP_NAME).app

sign: build
	codesign --force --deep --options runtime --sign "$(SIGN_IDENTITY)" $(BUILD_DIR)/$(APP_NAME).app
	codesign --verify --deep --strict $(BUILD_DIR)/$(APP_NAME).app
	@echo "Signed"

notarize: sign
	ditto -c -k --keepParent $(BUILD_DIR)/$(APP_NAME).app build/$(APP_NAME).zip
	xcrun notarytool submit build/$(APP_NAME).zip --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple $(BUILD_DIR)/$(APP_NAME).app
	rm build/$(APP_NAME).zip
	@echo "Notarized and stapled"

dmg: notarize
	rm -f $(DMG_NAME)
	create-dmg \
		--volname "$(APP_NAME)" \
		--background "Resources/dmg-background.png" \
		--window-pos 200 120 \
		--window-size 600 450 \
		--icon-size 128 \
		--text-size 14 \
		--hide-extension "$(APP_NAME).app" \
		--icon "$(APP_NAME).app" 150 200 \
		--app-drop-link 450 200 \
		$(DMG_NAME) \
		$(BUILD_DIR)/$(APP_NAME).app || true
	@test -f $(DMG_NAME) && echo "Created $(DMG_NAME)" || (echo "Failed to create DMG" && exit 1)

release: dmg
	@echo "Creating release v$(VERSION)..."
	gh release create v$(VERSION) $(DMG_NAME) --title "Sideboard v$(VERSION)" --generate-notes
	@echo "Released v$(VERSION)"

bump:
ifdef v
	agvtool new-marketing-version $(v)
endif
	agvtool next-version -all
	@echo "Version: $$(agvtool what-marketing-version -terse1) Build: $$(agvtool what-version -terse)"

clean:
	rm -rf build $(DMG_NAME)
