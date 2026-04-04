APP_NAME = Sideboard
BUILD_DIR = build/Release
INSTALL_DIR = $(HOME)/Applications
DMG_NAME = $(APP_NAME).dmg

.PHONY: build install uninstall run clean dmg

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

dmg: build
	rm -rf build/dmg $(DMG_NAME)
	mkdir -p build/dmg
	cp -R $(BUILD_DIR)/$(APP_NAME).app build/dmg/
	ln -s /Applications build/dmg/Applications
	hdiutil create -volname $(APP_NAME) -srcfolder build/dmg -ov -format UDZO $(DMG_NAME)
	rm -rf build/dmg
	@echo "Created $(DMG_NAME)"

clean:
	rm -rf build $(DMG_NAME)
