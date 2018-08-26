PREFIX?=/usr/local
INSTALL_NAME = swiff

install: build install_bin

build:
	swiftc -o swiff main.swift

install_bin:
	mkdir -p $(PREFIX)/bin
	install ./$(INSTALL_NAME) $(PREFIX)/bin
	rm ./$(INSTALL_NAME)

uninstall:
	rm -f $(INSTALL_PATH)