PREFIX?=/usr/local
INSTALL_NAME = swiff
SOURCE_FILE="Sources/swiff/main.swift"

install: build install_bin

build:
	xcrun swiftc -o swiff ${SOURCE_FILE}

install_bin:
	mkdir -p $(PREFIX)/bin
	install ./$(INSTALL_NAME) $(PREFIX)/bin
	rm ./$(INSTALL_NAME)

uninstall:
	rm -f $(INSTALL_PATH)
