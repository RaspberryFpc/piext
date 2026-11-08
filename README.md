# PiExt

**PiExt – Raspberry Pi Imaging and Backup Solution**

PiExt is a tool for creating and restoring Raspberry Pi drive backups. It saves the Master Boot Record (MBR), boot partition and system partition while leaving other partitions outside the backup scope.

By combining filesystem-aware image creation, Zstandard compression and differential imaging, PiExt reduces storage requirements while providing a straightforward restoration process.

PiExt supports image creation and restoration under Linux. For Windows users, the separate **PiExtRestorer** application provides image restoration without requiring a Linux environment.

Both applications are distributed together in a single release package.

## Why PiExt?

Traditional drive imaging tools often create copies of entire drives, including unused filesystem space. PiExt takes a different approach.

It focuses on the essential components required for a Raspberry Pi system:

- The MBR, including the partition table.
- The complete boot partition.
- The system partition.

For supported EXT filesystems, only sectors currently in use are included in the system image.

Subsequent backups can be created as Differential Images, storing only changes relative to the original Base Image.

The MBR and boot partition images are automatically recreated with every image creation operation.

Other partitions are not included in the backup and are preserved during restoration whenever possible.

This provides several advantages:

- Reduced storage requirements through filesystem-aware image creation.
- Efficient backups through differential imaging.
- Separate backup of MBR, boot and system partition.
- Automatic updating of MBR and boot images.
- Zstandard compression for system and boot images.
- Flexible restoration under Linux or Windows.
- Preservation of other partitions whenever possible.

## Key Features

- Create and restore MBR, boot and system partition images.
- Filesystem-aware image creation.
- Support for EXT2, EXT3 and EXT4 filesystems.
- Support for MBR-partitioned drives.
- Base and Differential Images.
- Zstandard (ZSTD) compression.
- Separate MBR and boot partition images.
- Graphical user interface for image creation and restoration.
- Independent selection of restoration components.
- Command-line interface for image creation.
- Image restoration under Linux and Windows.
- Preservation of other partitions during restoration whenever possible.

**Important:** Only MBR-partitioned drives are supported. GPT-partitioned drives are not supported.

## How PiExt Works

PiExt operates on physical drives but only backs up and restores three components:

1. **MBR:** The first sector of the physical drive, including the partition table.
2. **Boot partition:** The complete boot partition.
3. **System partition:** The EXT-based Linux system partition.

Other partitions are not included in the image files.

During restoration, the user can independently select which components should be restored. Other partitions are preserved whenever possible.

The expected Raspberry Pi partition layout is:

- **Partition 1:** Boot partition.
- **Partition 2:** System partition.

## Applications

PiExt consists of two applications for different operating systems.

### PiExt – Linux

PiExt runs under Linux on the Raspberry Pi.

It provides:

- Creating Base Images.
- Creating Differential Images.
- Creating MBR images.
- Creating boot partition images.
- Restoring MBR images.
- Restoring boot partition images.
- Restoring system images.

Image creation and restoration are available through the graphical interface.

PiExt also provides a command-line interface for image creation.

### PiExtRestorer – Windows

PiExtRestorer is the separate Windows application for restoring images created with PiExt.

It supports:

- Restoring the MBR.
- Restoring the boot partition.
- Restoring the system partition.
- Independently selecting the components required for restoration.

Image creation is not available under Windows.

PiExtRestorer provides a graphical interface and does not require a Linux environment to restore PiExt images.

## Image Concept

PiExt uses different image types to combine efficient storage with flexible restoration.

### MBR Image

The MBR image contains the first sector of the physical drive.

It includes:

- MBR boot code.
- MBR partition table.

The MBR image:

- Is stored as an uncompressed `.img` file.
- Represents the drive's MBR, not an individual partition.
- Is recreated during every image creation operation.
- Replaces the previous MBR image.

Filename:

```text
mbr_image_YYYY-MM-DD.img
```

### Boot Image

The boot image contains the complete boot partition.

It is:

- Stored as a compressed image.
- Compressed using Zstandard (ZSTD).
- Recreated during every image creation operation.
- Replaced by the newly created boot image.

Filename:

```text
boot_image_YYYY-MM-DD.zst
```

### Base Image

The Base Image contains the initial system image.

PiExt uses filesystem-aware image creation. Only sectors currently in use by the EXT filesystem are stored.

The Base Image:

- Contains the initial system partition image.
- Is compressed using Zstandard (ZSTD).
- Serves as the reference for all subsequent Differential Images.
- Is not overwritten when new images are created.

The first system image created in an image folder is always the Base Image.

Filename:

```text
base_image_<drive>_YYYY-MM-DD.zst
```

Example:

```text
base_image_sda_2026-09-28.zst
```

### Differential Image

Subsequent system images are created as Differential Images.

Each Differential Image is based directly on the original Base Image, not on another Differential Image.

Only changes relative to the Base Image are stored.

Differential Images:

- Are compressed using Zstandard (ZSTD).
- Store changes relative to the Base Image.
- Do not depend on other Differential Images.
- Are not overwritten when new images are created.

Filename:

```text
diff-image_YYYY-MM-DD_<number>.zst
```

Examples:

```text
diff-image_2026-09-29_1.zst
diff-image_2026-11-05_2.zst
```

The number is assigned sequentially.

## Image Storage and Management

All images belonging to a drive are stored together in one destination folder.

The folder contains:

- One current MBR image.
- One current boot partition image.
- One Base Image.
- Zero or more Differential Images.

During every image creation operation:

- The previous MBR image is deleted and replaced.
- The previous boot image is deleted and replaced.
- The Base Image remains unchanged.
- Existing Differential Images remain unchanged.
- A new Base Image or Differential Image is created as required.

The MBR and boot image filenames contain the date of the latest image creation.

Base and Differential Images retain their original filenames and dates.

This means that the folder always contains the latest MBR and boot images together with the available system image history.

## Image Folder Structure

Example of an image folder:

```text
Image Folder
 |
 +-- mbr_image_2026-11-05.img
 |
 +-- boot_image_2026-11-05.zst
 |
 +-- base_image_sda_2026-09-28.zst
 |
 +-- diff-image_2026-09-29_1.zst
 |
 +-- diff-image_2026-11-05_2.zst
```

The dates of the MBR and boot images indicate the most recent image creation.

The Base and Differential Images retain the dates from their original creation.

## Creating Images

PiExt creates images from selected components of a physical drive, not from the entire drive.

The source drive must use an MBR partition table and contain the expected partition layout:

- Partition 1: Boot partition.
- Partition 2: System partition.

### Graphical Interface

The graphical interface provides the following functions:

- Selecting the source drive.
- Selecting the destination folder.
- Creating Base Images.
- Creating Differential Images.
- Selecting images for restoration.
- Selecting the components to restore.
- Restoring MBR, boot and system images.

The source drive and destination drive must be different physical drives to avoid overwriting source data.

### Command-Line Interface

PiExt also provides a command-line interface for image creation.

**Syntax:**

```bash
sudo piext <drive> <destination-folder>
```

Example:

```bash
sudo piext /dev/sda /media/pi/backup
```

**Requirements:**

- Root privileges are required.
- The source must be a complete physical drive, for example `/dev/sda`.
- Exactly two parameters must be supplied.
- The destination folder is created automatically if it does not exist.

**Operation:**

The command-line interface supports image creation only.

Image restoration is not available through the command line. To restore images under Linux, use the PiExt graphical interface.

Alternatively, images can be restored under Windows using PiExtRestorer.

The CLI does not provide command-line options for restoration, compression level selection or saved GUI settings.

**Exit Codes:**

| Exit code | Meaning |
|---|---|
| `0` | Image creation completed successfully |
| `1` | An error occurred |

## Restoring Images

Images can be restored using either application:

- **PiExt** under Linux.
- **PiExtRestorer** under Windows.

The restoration process allows the user to select which components should be restored:

- MBR.
- Boot partition.
- System partition.

Each component can be selected independently according to the restoration requirements.

Other partitions are not part of the backup and are preserved during restoration whenever possible.

The MBR and boot image files are identified using these filename patterns:

```text
mbr_image_*.img
boot_image_*.zst
```

The required system image files depend on whether a Base Image or Differential Image is being restored.

### Restoring a Base Image

To restore a Base Image, the following files are required:

- The current MBR image.
- The current boot image.
- The selected Base Image.

Only the components selected by the user are restored.

### Restoring a Differential Image

Each Differential Image is based directly on the original Base Image.

To restore a Differential Image, the following files are required:

- The current MBR image.
- The current boot image.
- The corresponding Base Image.
- The selected Differential Image.

Other Differential Images are not required.

Only the components selected by the user are restored.

This makes it possible to restore a specific backup state without processing a chain of previous Differential Images.

### Restoring the Active Root Partition

A running Linux system cannot restore its own active root partition.

To restore the system partition under Linux, boot the Raspberry Pi from another system or boot medium first.

Alternatively, use PiExtRestorer under Windows.

## Source Drive and Target Drive

PiExt uses complete physical drives as source and target references, but only processes the MBR, boot partition and system partition.

Example:

```text
/dev/sda
```

The destination is a folder in which all image files are stored.

The source drive and destination drive must be different physical drives to avoid overwriting source data.

During restoration, only the components selected by the user are restored.

Other partitions are preserved whenever possible. Their preservation cannot be guaranteed in every partition layout or restoration scenario.

## Compatibility

PiExt supports:

- MBR-partitioned drives.
- EXT2 filesystems.
- EXT3 filesystems.
- EXT4 filesystems.

The following limitations apply:

- GPT-partitioned drives are not supported.
- Image creation is supported under Linux only.
- Image restoration is supported under Linux and Windows.
- The system partition cannot be restored while it is the active root partition.

PiExt system images use a program-specific format and cannot be restored directly with standard tools such as `dd`.

## Installation

PiExt and PiExtRestorer are distributed together in a single release package.

Download the latest release from the **Releases** section of this repository.

The release contains two installation files:

### Linux – PiExt

Install the Debian package on your Raspberry Pi:

```bash
sudo apt install ./piext.deb
```

### Windows – PiExtRestorer

Run the Windows installer:

```text
PiExtRestorer_setup.exe
```

Follow the installation instructions.

## Requirements

### PiExt

- Raspberry Pi running Linux.
- MBR-partitioned source drive.
- EXT2, EXT3 or EXT4 system filesystem.
- Sufficient storage space for the image files.
- Root privileges for image creation and restoration.

### PiExtRestorer

- Windows.
- A drive containing the required PiExt image files.
- A target drive with sufficient capacity for restoration.
- Administrator privileges for drive restoration.

## Typical Workflow

### Creating a Backup

1. Connect the source drive and backup drive.
2. Start PiExt.
3. Select the source drive.
4. Select the destination folder.
5. Start image creation.
6. PiExt creates or updates the MBR and boot images.
7. PiExt creates a Base Image or a new Differential Image.

### Restoring a Backup

1. Connect the target drive.
2. Start PiExt or PiExtRestorer.
3. Select the image folder.
4. Select the required Base Image or Differential Image.
5. Select the components to restore: MBR, boot partition and/or system partition.
6. Start the restoration process.

For Differential Image restoration, make sure that the corresponding Base Image is available.

## Important Notes

- Always verify the selected source and destination drives before starting an operation.
- The source drive and backup drive should be physically different drives.
- Restoring a component overwrites the corresponding data on the target drive.
- Other partitions are preserved whenever possible, but this cannot be guaranteed in every situation.
- Make sure that all required image files are available before starting restoration.
- Keep the Base Image together with its corresponding Differential Images.
- MBR and boot images are updated with every image creation operation.
- Restoring the MBR also restores the saved partition table.

**Always keep an additional copy of important backups on another storage device.**

## License

See the repository for license information.