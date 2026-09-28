# PiExt

**PiExt is a backup and restore tool for Raspberry Pi drives.**

PiExt can create complete drive backups containing the **MBR, boot partition and system partition**. The system partition is handled specifically for **EXT2, EXT3 and EXT4** filesystems and compressed using **Zstandard**.

PiExt provides both a **graphical user interface (GUI)** and a simple **command-line mode**.

![PiExt](docs/piext.png)

## Features

* Complete Raspberry Pi drive backup
* MBR backup
* Boot partition backup
* EXT2 / EXT3 / EXT4 system partition backup
* Zstandard compression
* Base Images
* Differential Images
* Differential backups are based directly on the Base Image
* Restore MBR, boot and system independently
* Graphical user interface
* Simple command-line operation
* Progress display with speed and ETA
* Automatic image filenames
* Designed for Raspberry Pi and Linux

## How it works

PiExt works with a complete drive.

A typical Raspberry Pi drive contains:

```text
Drive
├── MBR
├── Partition 1 → Boot
└── Partition 2 → System
```

When the first backup is created, PiExt creates a Base Image together with the MBR and boot image.

Example:

```text
backup/
├── mbr_image_2026-09-28.img
├── boot_image_2026-09-28.zst
└── base_image_sda_2026-09-28.zst
```

A later backup creates a Differential Image:

```text
backup/
├── mbr_image_2026-09-28.img
├── boot_image_2026-09-28.zst
├── base_image_sda_2026-09-28.zst
└── diff-image_2026-09-29_1.zst
```

Further backups create additional differential images:

```text
diff-image_2026-09-30_2.zst
diff-image_2026-10-01_3.zst
```

Each Differential Image is based directly on the Base Image and can be restored independently together with the Base Image.

## Installation

Download the latest `piext.deb` package from the GitHub Releases page and install it with:

```bash
sudo apt install piext.deb
```

PiExt requires **root privileges** because it directly reads from and writes to complete drives and partitions.

Start the graphical interface with:

```bash
sudo piext
```

## Graphical interface

The GUI allows you to select the source drive, destination folder and compression level.

For restoration, MBR, boot and system can be selected independently.

> **Important:** PiExt must always be started with `sudo`.

For example:

```bash
sudo piext
```

### Restoring the active system

A running Raspberry Pi cannot restore its active root partition while it is mounted as `/`.

For restoring the root partition, boot the Raspberry Pi from another Linux system, for example a separate SD card or USB drive.

## Command line

PiExt can also be used without the graphical interface.

```bash
sudo piext <drive> <destination-folder>
```

Example:

```bash
sudo piext /dev/sda /backup/piext
```

Another example for an SD card:

```bash
sudo piext /dev/mmcblk0 /backup/piext
```

The command-line mode:

* requires root privileges
* does not open the GUI
* automatically starts the backup
* creates the destination folder if necessary
* exits automatically when the backup is finished

Exit codes:

```text
0 = successful
1 = error
```

## Restore

PiExt can restore the individual parts of a backup:

* **MBR**
* **Boot partition**
* **System partition**

This allows, for example, only the system partition to be restored without overwriting the MBR or boot partition.

For a system restore, the corresponding Base Image is required. A Differential Image can optionally be selected to restore the state represented by that differential backup.

## Image types

### MBR

The MBR is stored separately as an uncompressed `.img` file.

Example:

```text
mbr_image_2026-09-28.img
```

The MBR is intentionally stored without compression because it is very small.

### Boot

The boot partition is stored as a complete compressed image:

```text
boot_image_2026-09-28.zst
```

### System

The system partition is stored using PiExt's filesystem-aware image format and compressed with Zstandard.

Base and Differential Images use:

```text
base_image_*.zst
diff-image_*.zst
```

## Requirements

PiExt is designed for:

* Raspberry Pi
* Linux
* EXT2
* EXT3
* EXT4
* Zstandard

**Root privileges are required.**

## Important

**Always verify the selected source and target drive before starting a backup or restore.**

Restoring an image writes data directly to the selected drive or partition and can overwrite existing data.

## Project

PiExt is developed by **RaspberryFpc** for Raspberry Pi and Linux.

## License

See the repository for license information.
