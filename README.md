# PiExt

PiExt is a backup and restore tool for **Raspberry Pi systems** that creates and restores compressed images of Linux **EXT2, EXT3 and EXT4 partitions**.

PiExt can be used either through its **graphical user interface (GUI)** or from the **command line (CLI)**.

Instead of storing the complete partition, PiExt stores only the sectors currently used by the filesystem. The data is compressed on the fly using **Zstandard (ZSTD)**.

The first image created in an image folder automatically becomes a **Base Image**. Further images are created as **Differential Images** based directly on the Base Image.

## Features

* Supports EXT2, EXT3 and EXT4 partitions
* Supports both **GUI and CLI operation**
* Stores only used filesystem sectors
* Compresses image data on the fly using Zstandard
* Automatically creates a Base Image
* Creates Differential Images based directly on the Base Image
* Create Differential Images with one click in the GUI
* Differential Images can be restored independently
* Only one Base Image is allowed per image folder
* Image filenames are generated automatically
* Images are stored as `.zst` files
* CLI operation can be fully automated
* CLI returns an exit code indicating success or failure

## Installation

PiExt is distributed as a Debian package (`.deb`) for Raspberry Pi systems.

Download the latest release from the **Releases** section of this repository and install the package with:

```bash
sudo apt install ./piext.deb
```

After installation, PiExt can be started either from the desktop application menu using the **GUI** or from a terminal using the command:

```bash
piext
```

PiExt requires appropriate permissions to access source and target partitions.

## Graphical User Interface (GUI)

When PiExt is started without command-line parameters, it starts in **GUI mode**.

The GUI provides functions for:

* Selecting Source and Target Partitions
* Selecting image folders
* Creating Base Images
* Creating Differential Images
* Selecting images for restoration
* Configuring the Zstandard compression level
* Starting and cancelling image operations
* Displaying operation progress and messages

## Command-Line Interface (CLI)

PiExt also provides a **command-line interface (CLI)** in the same executable.

When PiExt is started with one or more command-line parameters, it automatically switches to **CLI mode**.

In CLI mode:

* The graphical user interface is not displayed.
* The operation can be started automatically.
* No GUI interaction is required.
* PiExt exits automatically when the operation has finished.
* Exit code `0` indicates success.
* Exit code `1` indicates an error.

The CLI is useful for scripts, automated backups and scheduled operations.

### Create Image

The following parameters are available for creating images:

| Parameter             | Description                                                                  |
| --------------------- | ---------------------------------------------------------------------------- |
| `--create`            | Automatically start image creation                                           |
| `--sourcepartition`   | Source EXT2/EXT3/EXT4 partition                                              |
| `--createdestination` | Destination folder for the image; the folder is created if it does not exist |
| `--destination`       | Destination folder for the image; the folder must already exist              |
| `--compressionlevel`  | Zstandard compression level                                                  |
| `--lastsettings`      | Use the saved GUI settings                                                   |

Example:

```bash
sudo piext --create --sourcepartition /dev/sda2 --createdestination "/media/pi/hzg2/Diff_image"
```

With a specific compression level:

```bash
sudo piext --create --sourcepartition /dev/sda2 --createdestination "/media/pi/hzg2/Diff_image" --compressionlevel 5
```

If the destination folder already exists:

```bash
sudo piext --create --sourcepartition /dev/sda2 --destination "/media/pi/hzg2/Diff_image"
```

The saved settings can also be used:

```bash
sudo piext --lastsettings --create
```

The parameters can be specified either with a space or with `=`:

```bash
sudo piext --create --sourcepartition /dev/sda2
```

or:

```bash
sudo piext --create --sourcepartition=/dev/sda2
```

### Restore Image

The following parameters are available for restoring an image:

| Parameter           | Description                                     |
| ------------------- | ----------------------------------------------- |
| `--restore`         | Automatically start image restoration           |
| `--sourceimage`     | Image file to restore                           |
| `--targetpartition` | Target partition to which the image is restored |

Example:

```bash
sudo piext --restore --sourceimage "/media/pi/hzg2/Diff_image/base_image_sda2_2026-09-21.zst" --targetpartition /dev/sdd2
```

A Differential Image can be restored in the same way. The corresponding Base Image must be available in the same image folder.

### CLI Exit Codes

| Exit code | Meaning                          |
| --------- | -------------------------------- |
| `0`       | Operation completed successfully |
| `1`       | Operation failed                 |

## Source and Target Partitions

For image creation, a **Source Partition** must be selected.

The Source Partition is the EXT2, EXT3 or EXT4 partition from which the image is created.

For restoring an image, a **Target Partition** must be selected.

The Target Partition is the partition to which the selected image is restored.

The folder used to store the image files is selected separately from the Source or Target Partition.

## Image Folder

PiExt uses a folder to store the image files.

When creating an image, an existing image folder can be selected or a new folder can be created.

When restoring an image, the folder containing the required image files must be selected.

Only one **Base Image** can exist in an image folder.

PiExt automatically generates the filenames for the created images.

## Image Storage

PiExt does not store the complete partition.

Only sectors currently used by the EXT filesystem are included in the image. Unused sectors are omitted.

This can significantly reduce the amount of data that has to be read, processed and stored, especially when the partition contains a large amount of free space.

Image data is compressed during creation using **Zstandard (ZSTD)**.

All PiExt image files use the `.zst` extension.

## Base Image

The first image created in an empty image folder automatically becomes the **Base Image**.

The Base Image contains the initial state of the EXT partition.

Example:

```text
base_image_sda2_2026-09-21.zst
```

The filename contains the source partition and the creation date.

Only one Base Image can exist in an image folder.

## Differential Images

Every additional image created in the same image folder becomes a **Differential Image**.

A Differential Image contains the changes relative to the Base Image.

Each Differential Image is based directly on the Base Image and does not depend on any other Differential Image.

Examples:

```text
diff-image_2026-09-21_1.zst
diff-image_2026-09-21_2.zst
diff-image_2026-09-21_3.zst
```

Each Differential Image can be restored independently.

## Image Structure

The relationship between the Base Image and the Differential Images is:

```text
Base Image
     |
     +-- Diff Image 1
     +-- Diff Image 2
     +-- Diff Image 3
```

Each Differential Image uses the same Base Image.

The Base Image must remain available for every Differential Image that is still required.

## Restoring Images

Every image can be selected individually for restoration.

Restoring a Base Image requires only the Base Image itself.

Restoring a Differential Image requires the corresponding Base Image to be present in the same image folder.

For example:

```text
base_image_sda2_2026-09-21.zst
diff-image_2026-09-21_1.zst
```

When `diff-image_2026-09-21_1.zst` is selected for restoration, PiExt combines the Base Image and the selected Differential Image:

```text
Base Image + Diff Image 1
            |
            v
     Restored Partition
```

Other Differential Images are not required and can be deleted if they are no longer needed.

## Independent Differential Images

Differential Images do not depend on each other.

For example:

```text
Base Image
     |
     +-- Diff Image 1
     +-- Diff Image 2
     +-- Diff Image 3
```

Diff Image 3 does not require Diff Image 1 or Diff Image 2.

Only the Base Image and the selected Differential Image are required for restoration.

## Image Compatibility

PiExt uses its own program-specific image format.

Images created by PiExt can currently only be restored using PiExt.

The `.zst` files are **not standard disk images** and cannot be written directly to a partition using tools such as `dd`.

## Typical Workflow

### Creating Images

1. Select the **Source Partition**.
2. Select or create an **Image Folder**.
3. Create the first image.
4. The first image automatically becomes the **Base Image**.
5. Make changes to the system or partition.
6. Create another image.
7. The new image becomes a **Differential Image**.
8. Repeat the process as required.
9. Delete Differential Images that are no longer needed.

### Restoring an Image

1. Select the **Target Partition**.
2. Select the **Image Folder**.
3. Select the desired image.
4. Start the restore operation.
5. If a Differential Image is selected, the corresponding Base Image must also be present.

The selected image is restored directly to the Target Partition.

## Restoring the Active Root Partition

The currently running root partition cannot be restored while the system is running from that partition.

To restore the active system partition, boot the Raspberry Pi from another system or boot medium first.

A separate SD card or USB drive with a minimal Linux system, a minimal desktop environment and PiExt installed can be used for this purpose.

After booting from the separate system, the original system partition is no longer the active root partition and can be restored.

The PiExt image files can be stored on another USB drive, network storage or another accessible storage device.

After the restore operation is complete, shut down the system and boot from the restored partition.

## Requirements

* Raspberry Pi system
* Linux
* EXT2, EXT3 or EXT4 source and target partitions
* Zstandard (ZSTD)
* Appropriate permissions to access the source and target partitions
* A terminal when using the CLI

## Important

* PiExt supports both **GUI and CLI operation**.
* Without CLI parameters, PiExt starts in GUI mode.
* With CLI parameters, PiExt automatically switches to CLI mode.
* The GUI is not displayed in CLI mode.
* A Source Partition is required when creating an image.
* A Target Partition is required when restoring an image.
* Only used filesystem sectors are stored.
* Image data is compressed on the fly using Zstandard.
* The first image in an empty folder automatically becomes the Base Image.
* Only one Base Image can exist per image folder.
* All subsequent images are Differential Images.
* Differential Images are based directly on the Base Image.
* A Differential Image requires its Base Image for restoration.
* The Base Image must remain available as long as required Differential Images are needed.
* Differential Images can be deleted individually when they are no longer required.
* Image filenames are generated automatically.
* PiExt images use the `.zst` file extension.
* PiExt images can currently only be restored using PiExt.
* CLI exit code `0` indicates success.
* CLI exit code `1` indicates an error.
