# Phase 10 — Storage and Filesystems

**Goal of this phase:** Load files from disk. Execute them.

## 10.1 Initial ramdisk (start here)

- [ ] **Study initrd and the TAR/USTAR format**
  - **Why:** Asking the bootloader to load a TAR file into memory is the easiest "filesystem".
  - **Study:** USTAR header layout. Limine's "modules" mechanism.
  - **Verify:** You can describe the USTAR header fields.
  - **Notes:**

- [ ] **Add a module request**
  - **What:** Ask Limine to load `initrd.tar` alongside your kernel.
  - **Verify:** Print the module's address and size at boot.
  - **Notes:**

- [ ] **Parse the TAR**
  - **What:** Walk the headers; list filenames + sizes to serial.
  - **Verify:** `ls /` command (typed at your keyboard) lists every file you put in the TAR.
  - **Notes:**

## 10.2 The Virtual File System (VFS)

- [ ] **Study VFS concepts**
  - **Why:** Decouples "open/read/write/close" from the underlying storage.
  - **Study:** Inodes, dentries, file descriptors, vfs vtables.
  - **Verify:** You can sketch the relationship between an `Inode` and a `File`.
  - **Notes:**

- [ ] **Define VFS interfaces**
  - **What:** `Inode`, `File`, `Mount`, with vtables (`read`, `write`, `lookup`, `readdir`).
  - **Verify:** Multiple filesystem types can implement the same vtable.
  - **Notes:**

- [ ] **Mount the initrd as a TARFS**
  - **What:** Implement the vtable on top of your TAR parser.
  - **Verify:** `cat /hello.txt` (typed at your keyboard) prints the file's content.
  - **Notes:**

- [ ] **Add VFS syscalls**
  - **What:** `sys_open`, `sys_read`, `sys_write`, `sys_close`, `sys_lseek`.
  - **Verify:** User program reads a file from initrd and prints it.
  - **Notes:**

## 10.3 Real disk I/O

- [ ] **Pick a disk protocol**
  - **Why:** ATA PIO is dead simple but slow; AHCI (SATA) is more realistic. Start with ATA PIO.
  - **Study:** ATA PIO command set, ports `0x1F0-0x1F7`. OSDev Wiki: "ATA PIO Mode".
  - **Verify:** You can describe the read-sector command sequence.
  - **Notes:**

- [ ] **Configure QEMU with a disk**
  - **What:** Add `-drive file=disk.img,format=raw` to your QEMU args. Create a 64 MiB raw image.
  - **Verify:** QEMU boots and you can see disk via `info block` in the monitor.
  - **Notes:**

- [ ] **ATA PIO read driver**
  - **What:** Implement `readSector(lba, buf)`. Identify the drive first.
  - **Verify:** Read sector 0 and print as hex. Matches what `hexdump disk.img | head` shows on your host.
  - **Notes:**

- [ ] **Add a block device layer**
  - **What:** Generic `BlockDevice` interface with `read`/`write`. Wraps ATA.
  - **Verify:** Read sector via the block device interface; result matches direct ATA read.
  - **Notes:**

## 10.4 FAT32 read-only

- [ ] **Study FAT32**
  - **Why:** Simple, universal, well-documented. Read-only is enough to start.
  - **Study:** BPB (BIOS Parameter Block), FAT chains, directory entries (8.3 + LFN).
  - **Verify:** You can describe how to find the first cluster of a file.
  - **Notes:**

- [ ] **Format and populate `disk.img`**
  - **What:** On host: `mkfs.fat -F32 disk.img`, mount with loopback, copy files in.
  - **Verify:** `file disk.img` reports a FAT32 filesystem.
  - **Notes:**

- [ ] **Parse the BPB**
  - **What:** Read sector 0, verify signature, extract sectors-per-cluster, FAT location, root directory cluster.
  - **Verify:** Logged values match `fsck.fat` output on the host.
  - **Notes:**

- [ ] **Walk the root directory**
  - **What:** Read directory entries cluster by cluster following the FAT chain.
  - **Verify:** Listing shows the files you put on disk.
  - **Notes:**

- [ ] **Read a file**
  - **What:** Follow the cluster chain, return data.
  - **Verify:** Contents of `/test.txt` on disk match what you wrote on the host.
  - **Notes:**

- [ ] **Mount FAT32 in the VFS**
  - **What:** Implement the vtable.
  - **Verify:** Same `cat /file` command works on both initrd and FAT32 mounts.
  - **Notes:**

## Phase 10 Milestone

Your kernel reads files from a real disk through a real filesystem, exposed through a real VFS, accessed by real user programs.

## Phase 10 Debug Checkpoint

- [ ] Add `mount`, `ls`, `cat`, `xxd` debug commands.
- [ ] Cross-verify every file you read against the host (`md5sum`).
- [ ] Write up: "The full path of `cat /test.txt` from keystroke to pixel."

---
