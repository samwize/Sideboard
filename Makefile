APP_NAME = Sideboard
BUILD_DIR = .build/release
APP_BUNDLE = .build/$(APP_NAME).app
INSTALL_DIR = $(HOME)/Applications

.PHONY: build bundle install uninstall run clean

build:
	swift build -c release

bundle: build
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Resources/Info.plist $(APP_BUNDLE)/Contents/

install: bundle
	-@killall $(APP_NAME) 2>/dev/null || true
	mkdir -p $(INSTALL_DIR)
	cp -R $(APP_BUNDLE) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"

uninstall:
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Uninstalled $(APP_NAME).app"

run: bundle
	open $(APP_BUNDLE)

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)
