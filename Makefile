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
	rm -rf build/dmg $(DMG_NAME)
	mkdir -p build/dmg
	cp -R $(BUILD_DIR)/$(APP_NAME).app build/dmg/
	ln -s /Applications build/dmg/Applications
	hdiutil create -volname $(APP_NAME) -srcfolder build/dmg -ov -format UDZO $(DMG_NAME)
	rm -rf build/dmg
	@echo "Created $(DMG_NAME)"
	@shasum -a 256 $(DMG_NAME)

release: dmg
	@echo "Creating release v$(VERSION)..."
	gh release create v$(VERSION) $(DMG_NAME) --title "Sideboard v$(VERSION)" --generate-notes
	@echo "Released v$(VERSION)"
	@shasum -a 256 $(DMG_NAME)

clean:
	rm -rf build $(DMG_NAME)
