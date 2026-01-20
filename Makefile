.PHONY: build build-wallet deploy-wallet

AMALG ?= /usr/local/bin/amalg.lua

build: build-wallet

build-wallet:
	mkdir -p build build-lua build-lua/wallet
	tl gen -o build-lua/wallet/main.lua src/wallet/main.tl
	for f in src/wallet/*.tl src/shared/*.tl; do \
		[ -e "$$f" ] || continue; \
		out="build-lua/$${f#src/}"; \
		out="$${out%.tl}.lua"; \
		mkdir -p "$$(dirname "$$out")"; \
		tl gen -o "$$out" "$$f"; \
	done
	LUA_PATH="build-lua/?.lua;build-lua/?/init.lua;;" \
	$(AMALG) -s build-lua/wallet/main.lua -o build/wallet.lua \
		wallet.main \
		wallet.types wallet.helpers wallet.getters wallet.codec wallet.handlers wallet.internal wallet.patch \
		shared.types shared.deps shared.helpers shared.constants

deploy-wallet:
	node scripts/deploy-wallet.js
