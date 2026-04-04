APP_NAME = Sideboard
BUILD_DIR = build/Release
INSTALL_DIR = $(HOME)/Applications

.PHONY: build install uninstall run clean

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

clean:
	rm -rf build
