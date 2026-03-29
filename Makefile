ADDON_NAME := MythicLootMap
VERSION := $(shell sed -n 's/\#\# Version: //p' MythicLootMap.toc)
ARCHIVE := $(ADDON_NAME)-$(VERSION).zip

.PHONY: archive clean

archive: clean
	cd .. && zip -r $(ADDON_NAME)/$(ARCHIVE) $(ADDON_NAME) -x "$(ADDON_NAME)/.*" "$(ADDON_NAME)/.*/***" "$(ADDON_NAME)/$(ADDON_NAME)-*.zip"

clean:
	rm -f $(ARCHIVE)
