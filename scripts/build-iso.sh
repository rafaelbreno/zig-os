#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LIMINE_DIR="$PROJECT_ROOT/../../limine-bootloader/limine"
KERNEL_ELF="$PROJECT_ROOT/build/kernel.elf"
LIMINE_CONF="$PROJECT_ROOT/kernel/limine.conf"
STAGING_DIR="$PROJECT_ROOT/build/iso_root"
ISO_OUTPUT="$PROJECT_ROOT/build/os.iso"

# Clean and create staging directory
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR/boot/EFI/BOOT"

# Copy kernel
cp "$KERNEL_ELF" "$STAGING_DIR/boot/"

# Copy Limine config
cp "$LIMINE_CONF" "$STAGING_DIR/boot/"

# Copy Limine bootloader files
cp "$LIMINE_DIR/limine-bios.sys" "$STAGING_DIR/boot/"
cp "$LIMINE_DIR/limine-uefi-cd.bin" "$STAGING_DIR/boot/EFI/BOOT/BOOTX64.EFI"

# Create ISO with xorriso
xorriso -as mkisofs -b boot/limine-bios.sys \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  --efi-boot boot/EFI/BOOT/BOOTX64.EFI \
  -efi-boot-part --efi-boot-image --protective-msdos-label \
  -o "$ISO_OUTPUT" "$STAGING_DIR"

# Make it BIOS bootable
"$LIMINE_DIR/limine" bios-install "$ISO_OUTPUT"

echo "✓ ISO created: $ISO_OUTPUT"
