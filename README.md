# PiExt

PiExt is a backup and restore tool for **Raspberry Pi systems**. It creates and restores images of Linux **EXT2, EXT3 and EXT4 partitions** and can also save and restore the **MBR** and the **boot partition** of a complete drive.

PiExt can be used through its **graphical user interface (GUI)** or from the **command line (CLI)**.

For the system partition, PiExt stores only the sectors currently used by the EXT filesystem. The image data is compressed on the fly using **Zstandard (ZSTD)**.

When creating a complete Raspberry Pi image, PiExt saves:

* the MBR as a separate image file
* the boot partition as a complete compressed image
* the system partition as a Base Image or Differential Image

The first system image created in an image folder automatically becomes the **Base Image**. Further system images created in the same folder are **Differential Images** based directly on the Base Image.

## Features

* Designed for Raspberry Pi systems
* Supports EXT2, EXT3 and EXT4 system partitions
* Supports complete drive backup and restore
* Supports MBR backup and restore
* Supports boot partition backup and restore
* Supports both **GUI and CLI operation**
* Stores only used filesystem sectors for system images
* Compresses system image data on the fly using Zstandard
* Stores the MBR separately without compression
* Stores the boot partition as a complete compressed image
* Automatically creates a Base Image
* Creates Differential Images based directly on the Base Image
* Create Differential Images with one click in the GUI
* Differential Images can be restored independently
* Only one Base Image is allowed per image folder
* Image filenames are generated automatically
* System and boot images use the `.zst` file extension
* MBR images use the `.img` file extension
* CLI operation can be fully automated
* CLI does not display the graphical interface
* CLI returns an exit code indicating success or failure

## Installation

PiExt is distributed as a Debian package (`.deb`) for Raspberry Pi systems.

Download the latest release from the **Releases** section of this repository and install the package with:

```bash
sudo apt install ./piext.deb
```

After installation, PiExt can be started from the desktop application menu using the **GUI** or from a terminal.

## Graphical User Interface (GUI)

When PiExt is started without command-line parameters, it starts in **GUI mode**.

The GUI provides functions for:

* Selecting the source drive for image creation
* Selecting the target drive for restoration
* Selecting an image folder
* Selecting an image for restoration
* Creating complete drive images
* Creating Differential Images
* Restoring the MBR
* Restoring the boot partition
* Restoring the system partition
* Configuring the Zstandard compression level
* Starting and cancelling image operations
* Displaying operation progress and messages

### Creating an Image

For image creation, PiExt requires a **complete drive** as the source.

For example:

```text
/dev/mmcblk0
/dev/sda
/dev/nvme0n1
```

PiExt automatically determines the first and second partition of the selected drive.

A typical Raspberry Pi drive contains:

```text
Drive
 |
 +-- Partition 1  -> Boot
 |
 +-- Partition 2  -> System
```

When creating the first image in an image folder, PiExt creates:

```text
mbr_image_YYYY-MM-DD.img
boot_image_YYYY-MM-DD.zst
base_image_<drive>_YYYY-MM-DD.zst
```

The MBR, boot partition and system partition are therefore stored separately.

If a Base Image already exists in the selected image folder, PiExt creates a new Differential Image for the system partition instead of creating another Base Image.

## Command-Line Interface (CLI)

PiExt provides a simplified command-line interface for automated **image creation**.

The CLI is intentionally limited to image creation. The command line requires exactly two parameters:

1. The source drive
2. The destination folder

The graphical interface is not displayed.

### Create an Image

The syntax is:

```bash
sudo piext <drive> <destination-folder>
```

Example:

```bash
sudo piext /dev/sda /backup/piext
```

Another example using an SD card:

```bash
sudo piext /dev/mmcblk0 /backup/piext
```

The destination folder is automatically created if it does not already exist.

### CLI Requirements

The CLI must be executed with **root privileges** because PiExt needs direct access to the source drive.

Therefore, use:

```bash
sudo piext /dev/sda /backup/piext
```

Running the command without `sudo` results in an error.

### CLI Operation

When PiExt is started with command-line parameters:

* The graphical interface is not displayed.
* Exactly two parameters are expected.
* The first parameter specifies the complete source drive.
* The second parameter specifies the destination folder.
* Image creation starts automatically.
* No GUI interaction is required.
* The destination folder is created automatically if necessary.
* PiExt exits automatically after the operation.
* Exit code `0` indicates success.
* Exit code `1` indicates an error.

The CLI is useful for scripts, automated backups and scheduled operations.

### CLI Syntax

```bash
sudo piext <drive> <destination-folder>
```

Example:

```bash
sudo piext /dev/sda "/media/pi/backup/piext"
```

There are currently **no additional CLI options** for compression level, restore operations or saved GUI settings.

## CLI Exit Codes

| Exit code | Meaning                          |
| --------- | -------------------------------- |
| `0`       | Operation completed successfully |
| `1`       | Operation failed                 |

## Source Drive and Target Drive

### Source Drive

For image creation, a **complete drive** must be selected.

Examples:

```text
/dev/sda
/dev/sdb
/dev/mmcblk0
/dev/nvme0n1
```

A single partition such as:

```text
/dev/sda2
```

is **not** used as the source for complete image creation.

PiExt automatically determines the boot and system partitions belonging to the selected drive.

### Target Drive

For restoration, a **complete target drive** must be selected.

PiExt restores the selected components to the corresponding partitions of that drive.

## Image Folder

PiExt uses a folder to store all image files belonging to a backup.

When creating an image, an existing folder can be selected or a new folder can be created.

A typical image folder contains:

```text
mbr_image_2026-09-28.img
boot_image_2026-09-28.zst
base_image_sda_2026-09-28.zst
diff-image_2026-09-29_1.zst
diff-image_2026-09-30_2.zst
```

Only one Base Image can exist in an image folder.

Further system images are created as Differential Images.

## Image Types

PiExt currently uses three different types of image files.

### MBR Image

The MBR is stored separately as an uncompressed `.img` file.

Example:

```text
mbr_image_2026-09-28.img
```

The MBR image is intentionally not compressed because it is very small.

### Boot Image

The boot partition is stored as a complete compressed image.

Example:

```text
boot_image_2026-09-28.zst
```

Unlike the system Base Image and Differential Images, the boot image is a complete partition image.

### System Base Image

The system partition is stored using PiExt's filesystem-aware image format.

Only sectors currently used by the EXT filesystem are stored.

Example:

```text
base_image_sda_2026-09-28.zst
```

## Base Image

The first system image created in an empty image folder automatically becomes the **Base Image**.

The Base Image contains the initial state of the system partition.

Example:

```text
base_image_sda_2026-09-28.zst
```

Only one Base Image can exist in an image folder.

The Base Image is required when restoring a Differential Image.

## Differential Images

When a Base Image already exists in the selected image folder, the next system image is created as a **Differential Image**.

A Differential Image contains the changes relative to the Base Image.

Each Differential Image is based directly on the Base Image.

Examples:

```text
diff-image_2026-09-28_1.zst
diff-image_2026-09-29_2.zst
diff-image_2026-09-30_3.zst
```

The Differential Images do not depend on each other.

The relationship is:

```text
Base Image
     |
     +-- Diff Image 1
     +-- Diff Image 2
     +-- Diff Image 3
```

Diff Image 3 does not require Diff Image 1 or Diff Image 2.

Only the Base Image and the selected Differential Image are required for restoration.

## Image Storage

For the system partition, PiExt does not store the complete partition.

Only sectors currently used by the EXT filesystem are included in the Base and Differential Images.

Unused filesystem sectors are omitted.

This can significantly reduce the amount of data that has to be processed and stored, especially when the system partition contains a large amount of free space.

System image data is compressed during creation using **Zstandard (ZSTD)**.

The boot partition is stored separately as a complete compressed image.

The MBR is stored separately as a small uncompressed `.img` file.

## Image Structure

A complete image folder can therefore contain:

```text
Image Folder
 |
 +-- mbr_image_2026-09-28.img
 |
 +-- boot_image_2026-09-28.zst
 |
 +-- base_image_sda_2026-09-28.zst
 |
 +-- diff-image_2026-09-29_1.zst
 +-- diff-image_2026-09-30_2.zst
 +-- diff-image_2026-10-01_3.zst
```

The MBR and boot image belong to the complete drive backup.

The Base Image and Differential Images belong to the system partition.

## Restoring Images

PiExt restores the selected components independently.

The GUI provides three restore options:

* **MBR**
* **Boot partition**
* **System partition**

One or more of these components can be selected before starting the restore.

### MBR Restore

When MBR restoration is selected, PiExt searches the selected image folder for the MBR image:

```text
mbr_image_*.img
```

The MBR image is restored directly to the selected target drive.

After restoring the MBR, PiExt requests that Linux reread the partition table.

### Boot Restore

When boot restoration is selected, PiExt searches the image folder for:

```text
boot_image_*.zst
```

The complete boot partition image is decompressed and restored to the first partition of the selected target drive.

### System Restore

When system restoration is selected, PiExt requires a Base Image.

If the selected image is the Base Image:

```text
Base Image
    |
    v
Restored System Partition
```

If a Differential Image is selected:

```text
Base Image + Selected Differential Image
                  |
                  v
        Restored System Partition
```

Other Differential Images are not required.

## Restoring a Differential Image

For example, an image folder may contain:

```text
base_image_sda_2026-09-28.zst
diff-image_2026-09-30_1.zst
diff-image_2026-10-02_2.zst
```

If:

```text
diff-image_2026-10-02_2.zst
```

is selected, PiExt requires only:

```text
base_image_sda_2026-09-28.zst
diff-image_2026-10-02_2.zst
```

The first Differential Image is not required.

## Restoring the Active Root Partition

The currently running root partition cannot be restored while the system is running from that partition.

If the active root partition is selected for restoration, PiExt stops the restore operation.

To restore the active system partition, boot the Raspberry Pi from another system or boot medium first.

A separate SD card or USB drive with a minimal Linux system and PiExt installed can be used for this purpose.

After booting from the separate system, the original system partition is no longer the active root partition and can be restored.

The PiExt image folder can be located on another USB drive, network storage or another accessible storage device.

After the restore operation is complete, shut down the system and boot from the restored drive.

## Image Compatibility

PiExt uses its own program-specific image format for system images.

PiExt system images can currently only be restored using PiExt.

The `.zst` files are **not standard disk images** and cannot be written directly to a partition using tools such as `dd`.

The MBR `.img` file is a separate PiExt backup file and is intended to be restored through PiExt.

## Typical Workflow

### Creating the First Image

1. Select the complete **Source Drive**.
2. Select or create an **Image Folder**.
3. Start image creation.
4. PiExt saves the MBR.
5. PiExt creates a complete compressed image of the boot partition.
6. PiExt creates the system **Base Image**.
7. The image folder now contains the complete backup components.

### Creating a Differential Image

1. Select the same complete source drive.
2. Select the existing Image Folder.
3. Start image creation.
4. PiExt detects the existing Base Image.
5. PiExt creates a new Differential Image for the system partition.
6. The MBR and boot image are not recreated as part of the Differential Image operation.

### Restoring

1. Select the complete **Target Drive**.
2. Select the image file/folder containing the required images.
3. Select one or more restore options:

   * MBR
   * Boot partition
   * System partition
4. Start the restore operation.
5. PiExt restores the selected components.

When restoring a Differential Image, the corresponding Base Image must be present in the same image folder.

## Requirements

* Raspberry Pi system
* Linux
* EXT2, EXT3 or EXT4 system partition
* Zstandard (ZSTD)
* Appropriate permissions to access drives and partitions
* Root privileges for operations requiring direct drive access
* A terminal when using the CLI

## Important

* PiExt supports both **GUI and CLI operation**.
* Without command-line parameters, PiExt starts in GUI mode.
* With command-line parameters, PiExt automatically switches to CLI mode.
* The GUI is not displayed in CLI mode.
* CLI image creation requires exactly two parameters: source drive and destination folder.
* CLI image creation must be started using `sudo`.
* The CLI automatically starts the image creation operation.
* The destination folder is created automatically if it does not exist.
* A complete drive must be specified for image creation.
* A complete drive must be selected as the target for restoration.
* The MBR is stored separately as an uncompressed `.img` file.
* The boot partition is stored as a complete compressed `.zst` image.
* System Base and Differential Images store only sectors currently used by the EXT filesystem.
* System image data is compressed using Zstandard.
* The first system image in an empty folder automatically becomes the Base Image.
* Only one Base Image can exist per image folder.
* Subsequent system images are Differential Images.
* Differential Images are based directly on the Base Image.
* Differential Images do not depend on each other.
* A Differential Image requires its Base Image for restoration.
* The Base Image must remain available as long as required Differential Images are needed.
* Differential Images can be deleted individually when they are no longer required.
* Image filenames are generated automatically.
* System and boot images use the `.zst` extension.
* MBR images use the `.img` extension.
* PiExt system images can currently only be restored using PiExt.
* The active root partition cannot be restored while it is in use.
* CLI exit code `0` indicates success.
* CLI exit code `1` indicates an error.
