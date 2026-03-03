#!/usr/bin/env bash
set -euo pipefail

source dependencies.sh

mkdir -p ~/.byond/bin

# Сборка из форка BlueMoon (auxmos-bluemoon) с фичей bluemoon_reactions
if [ -n "${AUXMOS_REPO:-}" ]; then
	if ! command -v cargo &>/dev/null; then
		echo "Installing Rust for auxmos build..."
		curl -sSf https://sh.rustup.rs | sh -s -- -y
		source "$HOME/.cargo/env"
	fi
	rustup target add i686-unknown-linux-gnu 2>/dev/null || true
	export PKG_CONFIG_ALLOW_CROSS=1
	if [ ! -d auxmos ]; then
		git clone --depth 1 -b "${AUXMOS_VERSION}" "${AUXMOS_REPO}" auxmos
	fi
	cd auxmos
	git fetch origin "${AUXMOS_VERSION}" 2>/dev/null || true
	git checkout "${AUXMOS_VERSION}"
	cargo build --release --target=i686-unknown-linux-gnu --features "bluemoon_reactions"
	cp -f target/i686-unknown-linux-gnu/release/libauxmos.so ~/.byond/bin/libauxmos.so
	cd ..
else
	wget -O ~/.byond/bin/libauxmos.so "https://github.com/Putnam3145/auxmos/releases/download/${AUXMOS_VERSION}/libauxmos.so"
fi

chmod +x ~/.byond/bin/libauxmos.so
ldd ~/.byond/bin/libauxmos.so
