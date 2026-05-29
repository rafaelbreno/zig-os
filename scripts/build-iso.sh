#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LIMINE_DIR="$PROJECT_ROOT/../../limine-bootloader/limine"
KERNEL_ELF="$PROJECT_ROOT/build/kernel.elf"
LIMINE_CONF="$PROJECT_ROOT/kernel/limine.conf"
STAGING_DIR="$PROJECT_ROOT/build/iso_root"
ISO_OUTPUT="$PROJECT_ROOT/build/os.iso"

# Clean and create staging directories
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR/boot/limine"
mkdir -p "$STAGING_DIR/EFI/BOOT"

# Copy kernel
cp "$KERNEL_ELF" "$STAGING_DIR/boot/limine/"

# Copy Limine config to all search locations
cp "$LIMINE_CONF" "$STAGING_DIR/boot/limine/"
cp "$LIMINE_CONF" "$STAGING_DIR/boot/limine.conf"
mkdir -p "$STAGING_DIR/limine"
cp "$LIMINE_CONF" "$STAGING_DIR/limine/limine.conf"
cp "$LIMINE_CONF" "$STAGING_DIR/limine.conf"

# Copy Limine bootloader files
cp "$LIMINE_DIR/limine-bios.sys" "$STAGING_DIR/boot/limine/"
cp "$LIMINE_DIR/limine-bios-cd.bin" "$STAGING_DIR/boot/limine/"
cp "$LIMINE_DIR/limine-uefi-cd.bin" "$STAGING_DIR/boot/limine/"
cp "$LIMINE_DIR/BOOTX64.EFI" "$STAGING_DIR/EFI/BOOT/"

# Create ISO with xorriso
xorriso -as mkisofs -iso-level 4 \
  -b boot/limine/limine-bios-cd.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  --efi-boot boot/limine/limine-uefi-cd.bin \
  -efi-boot-part --efi-boot-image --protective-msdos-label \
  -o "$ISO_OUTPUT" "$STAGING_DIR"

# Make it BIOS bootable
"$LIMINE_DIR/limine" bios-install "$ISO_OUTPUT"

echo "✓ ISO created: $ISO_OUTPUT"
