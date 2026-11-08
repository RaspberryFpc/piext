  unit Language;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

const
  LANG_GERMAN = 0;
  Lang_English =1;


  TXT_ETA_HOURS = 1;
  TXT_ETA_MINUTES = 2;
  TXT_PARTITION_NOT_SELECTED = 3;
  TXT_CREATING_DIFF_IMAGE = 4;
  TXT_DIFF_IMAGE_CREATED = 5;
  TXT_DIFF_IMAGE_ERROR = 6;
  TXT_BASE_IMAGE_CREATED = 7;
  TXT_BASE_IMAGE_ERROR = 8;
  TXT_ZSTD_FILES = 9;
  TXT_DOES_NOT_EXIST_RESTORE_SUSPENDED = 10;
  TXT_ROOT_RESTORE_SUSPENDED = 11;
  TXT_WILL_BE_RESTORED = 12;
  TXT_ALL_DATA_WILL_BE_LOST = 13;
  TXT_IMAGE_RESTORED = 14;
  TXT_RESTORE_ERROR = 15;
  TXT_CREATE_IMAGE = 16;
  TXT_RESTORE_IMAGE = 17;
  TXT_SOURCE_partition = 18;
  TXT_TARGET_partition = 19;
  TXT_IMAGE_FOLDER = 20;
  TXT_IMAGE_FILE = 21;
  TXT_COMPRESSION_LEVEL = 22;
  TXT_EXT4_DETECTING = 23;
  TXT_EXT4_READ_ERROR = 24;
  TXT_SECTOR_SIZE_ERROR = 25;
  TXT_EXT4_BLOCK_SIZE_ERROR = 26;
  TXT_DEVICE_SIZE_ERROR = 27;
  TXT_DEVICE_SECTOR_SIZE_ERROR = 28;
  TXT_BITMAP_CREATE_ERROR = 29;
  TXT_BITMAP_SIZE_ERROR = 30;
  TXT_PARTITION_SIZE = 31;
  TXT_USED_SECTORS = 32;
  TXT_USED_DATA = 33;
  TXT_DEVICE_OPEN_ERROR = 34;
  TXT_BASE_IMAGE_CREATE_ERROR = 35;
  TXT_HEADER_WRITE_ERROR = 36;
  TXT_BITMAP_WRITE_ERROR = 37;
  TXT_ZSTD_CONTEXT_ERROR = 38;
  TXT_ZSTD_COMPRESSION_ERROR = 39;
  TXT_ZSTD_FINALIZATION_ERROR = 40;
  TXT_BASE_IMAGE_WRITE_ERROR = 41;
  TXT_ZSTD_LEVEL_ERROR = 42;
  TXT_ZSTD_THREADS_ERROR = 43;
  TXT_ZSTD_LONG_ERROR = 44;
  TXT_ZSTD_INFO = 45;
  TXT_OPERATION_CANCELLED = 46;
  TXT_DEVICE_READ_ERROR = 47;
  TXT_FSYNC_ERROR = 48;
  TXT_BASE_IMAGE_SIZE = 49;
  TXT_BASE_IMAGE_OPEN_ERROR = 50;
  TXT_BASE_IMAGE_HEADER_ERROR = 51;
  TXT_INVALID_BASE_IMAGE = 52;
  TXT_UNSUPPORTED_BASE_VERSION = 53;
  TXT_SECTOR_SIZE_MISMATCH = 54;
  TXT_DEVICE_BASE_SIZE_MISMATCH = 55;
  TXT_BASE_BITMAP_READ_ERROR = 56;
  TXT_CURRENT_BITMAP_ERROR = 57;
  TXT_CURRENT_BITMAP_SIZE_ERROR = 58;
  TXT_DIFF_IMAGE_CREATE_ERROR = 59;
  TXT_DIFF_IMAGE_WRITE_ERROR = 60;
  TXT_DIFF_HEADER_WRITE_ERROR = 61;
  TXT_DIFF_BITMAP_WRITE_ERROR = 62;
  TXT_DIFF_BITMAP_UPDATE_ERROR = 63;
  TXT_BASE_DATA_TOO_SHORT = 64;
  TXT_BASE_EOF = 65;
  TXT_BASE_READ_ERROR = 66;
  TXT_DIFF_DATA_TOO_SHORT = 67;
  TXT_DIFF_EOF = 68;
  TXT_DIFF_READ_ERROR = 69;
  TXT_DIFF_ZSTD_ERROR = 70;
  TXT_DIFF_CREATED = 71;
  TXT_CHANGED_SECTORS = 72;
  TXT_COMPRESSED_DIFF_DATA = 73;
  TXT_PARTITION_TARGET_ERROR = 74;
  TXT_RESTORE_TARGET_PARTITION = 75;
  TXT_TARGET_drive = 76;
  TXT_PARTITION_START = 77;
  TXT_PARTITION_SIZE_INFO = 78;
  TXT_TARGET_PARTITION_SIZE_ERROR = 79;
  TXT_TARGET_DRIVE_OPEN_ERROR = 80;
  TXT_TARGET_POSITION_ERROR = 81;
  TXT_BASE_HEADER_SIZE_ERROR = 82;
  TXT_INVALID_SECTOR_SIZE = 83;
  TXT_INVALID_BITMAP_SIZE = 84;
  TXT_USED_SECTORS_COUNT_ERROR = 85;
  TXT_DIFF_HEADER_READ_ERROR = 86;
  TXT_INVALID_DIFF_IMAGE = 87;
  TXT_UNSUPPORTED_DIFF_VERSION = 88;
  TXT_DIFF_HEADER_SIZE_ERROR = 89;
  TXT_SECTOR_COUNT_ERROR = 90;
  TXT_DIFF_BITMAP_READ_ERROR = 91;
  TXT_DIFF_INFO = 92;
  TXT_BASE_DECODER_ERROR = 93;
  TXT_DIFF_DECODER_ERROR = 94;
  TXT_BASE_ZSTD_STREAM_ERROR = 95;
  TXT_DIFF_ZSTD_STREAM_ERROR = 96;
  TXT_BASE_DATA_COUNT_ERROR = 97;
  TXT_DIFF_DATA_COUNT_ERROR = 98;
  TXT_RESTORE_SUCCESS = 99;
  TXT_WRITTEN_DATA = 100;
  TXT_RESTORE_TARGET = 101;
  TXT_RESTORE_ERROR_MESSAGE = 102;
  TXT_ZSTD_DECODER_ERROR = 103;
  TXT_BASE_DATA_END_ERROR = 104;
  TXT_DIFF_DATA_END_ERROR = 105;
  TXT_DIFF_BUFFER_SIZE_ERROR = 106;
  TXT_TARGET_SIZE_ERROR = 107;
  TXT_TARGET_WRITE_ERROR = 108;
  TXT_SECTOR_COUNT = 109;
  TXT_BITMAP_SIZE = 110;
  TXT_BITMAP_CREATE_FILE_ERROR = 111;
  TXT_BITMAP_CREATED = 112;
  TXT_ZSTD_COMPRESS_ERROR = 113;
  TXT_ZSTD_SPEED_ETA_RATIO = 114;
  TXT_CANCELLED = 115;
  TXT_Drive_NOT_SELECTED = 116;
  TXT_abort = 117;
  TXT_lang = 118;
  TXT_lang_create = 119;
  TXT_lang_restore = 120;
  txt_sourcedrive = 121;
  txt_targetdrive = 122;
  txt_imagefolder = 123;
  txt_help = 124;
  TXT_NO_DESTINATION_FOLDER = 125;
  TXT_DESTINATION_NOT_EXIST = 126;
  TXT_DESTINATION_CREATE_ERROR = 127;
  TXT_NO_DEVICE_SPECIFIED = 128;
  TXT_NOT_COMPLETE_DISK = 129;
  TXT_SOURCE_DRIVE = 130;
  TXT_SYSTEM_PARTITION = 131;
  TXT_SYSTEM_PARTITION_NOT_FOUND = 132;
  TXT_BASE_IMAGE_EXISTS = 133;
  TXT_CREATING_DIFFERENTIAL = 134;
  TXT_MBR_CREATING = 135;
  TXT_MBR_CREATE_ERROR = 136;
  TXT_MBR_CREATED = 137;
  TXT_BOOT_PARTITION = 138;
  TXT_BOOT_PARTITION_NOT_FOUND = 139;
  TXT_CREATING_FULL_BOOT_IMAGE = 140;
  TXT_BOOT_IMAGE_CREATE_ERROR = 141;
  TXT_BOOT_IMAGE_CREATED = 142;
  TXT_ALL_IMAGES_CREATED = 143;
  TXT_PLEASE_SELECT_RESTORE_OPTION = 144;
  TXT_SECURITY_QUERY = 145;
  TXT_WARNING = 146;
  TXT_TARGET_DRIVE_INFO = 147;
  TXT_DATA_WRITTEN_TO_DRIVE = 148;
  TXT_MBR = 149;
  TXT_BOOT_PARTITION_NAME = 150;
  TXT_SYSTEM_PARTITION_NAME = 151;
  TXT_EXISTING_DATA_OVERWRITTEN = 152;
  TXT_CONFIRM_CONTINUE = 153;
  TXT_COMPLETE_DISK_RESTORE = 154;
  TXT_IMAGE_FILE_NOT_SELECTED = 155;
  TXT_IMAGE_FILE_NOT_EXIST = 156;
  TXT_NO_MBR_IMAGE = 157;
  TXT_MBR_IMAGE_NOT_EXIST = 158;
  TXT_NO_BOOT_IMAGE = 159;
  TXT_BOOT_IMAGE_NOT_EXIST = 160;
  TXT_NO_BASE_IMAGE = 161;
  TXT_BASE_IMAGE_NOT_EXIST = 162;
  TXT_UNMOUNTING = 163;
  TXT_RESTORING_MBR = 164;
  TXT_MBR_RESTORE_ERROR = 165;
  TXT_MBR_RESTORED = 166;
  TXT_RESTORING_BOOT = 167;
  TXT_BOOT_RESTORE_ERROR = 168;
  TXT_BOOT_RESTORED = 169;
  TXT_RESTORING_SYSTEM = 170;
  TXT_SYSTEM_RESTORE_SUCCESS = 171;
  TXT_ALL_SELECTED_RESTORED = 172;
  TXT_MBR_NOT_FOUND = 173;
  TXT_MBR_RESTORE_SUCCESS = 174;
  TXT_DEVICE_NOT_COMPLETE_DISK = 175;
  TXT_NO_BASE_IMAGE_RESTORE = 176;
  TXT_ALL_IMAGES_SUCCESS = 177;
  TXT_DESTINATION_FOLDER = 178;
  TXT_SYSTEM_IMAGE = 179;
  TXT_SYNCING=180;
  txt_invalid_part_detected=181;
  txt_invalid_remove=182;

type
  TLanguageTexts = array[1..182, 0..1] of string;

const
  LanguageTexts: TLanguageTexts = (
    ('ETA %d:%2.2d:%2.2d', 'ETA %d:%2.2d:%2.2d'), // 1 TXT_ETA_HOURS
    ('ETA %2.2d:%2.2d', 'ETA %2.2d:%2.2d'), // 2 TXT_ETA_MINUTES
    ('Partition nicht ausgewählt', 'Partition not selected'), // 3 TXT_PARTITION_NOT_SELECTED
    ('Erzeuge differenzielles Image: %s', 'Creating differential image: %s'), // 4 TXT_CREATING_DIFF_IMAGE
    ('Differenz-Image erfolgreich erstellt.', 'Differential image created successfully.'), // 5 TXT_DIFF_IMAGE_CREATED
    ('Fehler beim Erstellen des Differenz-Images.', 'Error creating differential image.'), // 6 TXT_DIFF_IMAGE_ERROR
    ('Basisimage erfolgreich erstellt.', 'Base image created successfully.'), // 7 TXT_BASE_IMAGE_CREATED
    ('Fehler beim Erstellen des Basisimages.', 'Error creating base image.'), // 8 TXT_BASE_IMAGE_ERROR
    ('ZSTD-Dateien', 'ZSTD files'), // 9 TXT_ZSTD_FILES
    ('existiert nicht - Wiederherstellung abgebrochen', 'does not exist - restore suspended'), // 10 TXT_DOES_NOT_EXIST_RESTORE_SUSPENDED
    ('ist auf / gemountet - Wiederherstellung abgebrochen', 'is mounted on / - restore suspended'), // 11 TXT_ROOT_RESTORE_SUSPENDED
    ('wird wiederhergestellt.', 'will be restored.'), // 12 TXT_WILL_BE_RESTORED
    ('Alle vorhandenen Daten gehen verloren.', 'All existing data will be lost.'), // 13 TXT_ALL_DATA_WILL_BE_LOST
    ('Image erfolgreich wiederhergestellt.', 'Image restored successfully.'), // 14 TXT_IMAGE_RESTORED
    ('Fehler bei der Wiederherstellung des Images.', 'Error restoring image.'), // 15 TXT_RESTORE_ERROR
    ('Image erstellen', 'Create image'), // 16 TXT_CREATE_IMAGE
    ('Wiederherstellung', 'Restore image'), // 17 TXT_RESTORE_IMAGE
    ('Quelllaufwerk', 'Source drive'), // 18 TXT_SOURCE_partition
    ('Ziellaufwerk', 'Target drive'), // 19 TXT_TARGET_partition
    ('Image-Ordner', 'Image folder'), // 20 TXT_IMAGE_FOLDER
    ('Image-Datei', 'Image file'), // 21 TXT_IMAGE_FILE
    ('Kompressionsstufe', 'Compression level'), // 22 TXT_COMPRESSION_LEVEL
    ('Ermittle Ext4-Belegung...', 'Determining Ext4 usage...'), // 23 TXT_EXT4_DETECTING
    ('Fehler: Ext4-Dateisystem konnte nicht gelesen werden.', 'Error: Could not read Ext4 filesystem.'), // 24 TXT_EXT4_READ_ERROR
    ('Fehler: Sektorgröße konnte nicht ermittelt werden.', 'Error: Could not determine sector size.'), // 25 TXT_SECTOR_SIZE_ERROR
    ('Fehler: Ext4-Blockgröße ist kein Vielfaches der Sektorgröße.', 'Error: Ext4 block size is not a multiple of sector size.'), // 26 TXT_EXT4_BLOCK_SIZE_ERROR
    ('Fehler: Devicegröße konnte nicht ermittelt werden.', 'Error: Could not determine device size.'), // 27 TXT_DEVICE_SIZE_ERROR
    ('Fehler: Devicegröße ist kein Vielfaches der Sektorgröße.', 'Error: Device size is not a multiple of sector size.'), // 28 TXT_DEVICE_SECTOR_SIZE_ERROR
    ('Fehler beim Erstellen der Belegungs-Bitmap.', 'Error creating usage bitmap.'), // 29 TXT_BITMAP_CREATE_ERROR
    ('Fehler: Bitmapgröße stimmt nicht.', 'Error: Bitmap size does not match.'), // 30 TXT_BITMAP_SIZE_ERROR
    ('Partitionsgröße: %.2f GiB', 'Partition size: %.2f GiB'), // 31 TXT_PARTITION_SIZE
    ('Belegte Sektoren: %d', 'Used sectors: %d'), // 32 TXT_USED_SECTORS
    ('Nur belegte Daten werden gespeichert: %.2f GiB', 'Only used data is stored: %.2f GiB'), // 33 TXT_USED_DATA
    ('Fehler: Device konnte nicht geöffnet werden: errno=%d', 'Error: Could not open device: errno=%d'), // 34 TXT_DEVICE_OPEN_ERROR
    ('Fehler: Basisimage konnte nicht erstellt werden: errno=%d', 'Error: Could not create base image: errno=%d'), // 35 TXT_BASE_IMAGE_CREATE_ERROR
    ('Fehler beim Schreiben des Headers: errno=%d', 'Error writing header: errno=%d'), // 36 TXT_HEADER_WRITE_ERROR
    ('Fehler beim Schreiben der Bitmap: errno=%d', 'Error writing bitmap: errno=%d'), // 37 TXT_BITMAP_WRITE_ERROR
    ('Fehler: ZSTD_createCCtx fehlgeschlagen.', 'Error: ZSTD_createCCtx failed.'), // 38 TXT_ZSTD_CONTEXT_ERROR
    ('ZSTD-Kompressionsfehler: %s', 'ZSTD compression error: %s'), // 39 TXT_ZSTD_COMPRESSION_ERROR
    ('ZSTD-Finalisierungsfehler: %s', 'ZSTD finalization error: %s'), // 40 TXT_ZSTD_FINALIZATION_ERROR
    ('Fehler beim Schreiben des Basisimages: errno=%d', 'Error writing base image: errno=%d'), // 41 TXT_BASE_IMAGE_WRITE_ERROR
    ('Set compression level failed', 'Set compression level failed'), // 42 TXT_ZSTD_LEVEL_ERROR
    ('Set thread count failed', 'Set thread count failed'), // 43 TXT_ZSTD_THREADS_ERROR
    ('Enable long mode failed', 'Enable long mode failed'), // 44 TXT_ZSTD_LONG_ERROR
    ('ZSTD: Level %d, --long, %d Threads', 'ZSTD: Level %d, --long, %d threads'), // 45 TXT_ZSTD_INFO
    ('Operation abgebrochen.', 'Operation cancelled.'), // 46 TXT_OPERATION_CANCELLED
    ('Fehler beim Lesen bei Offset %d: errno=%d', 'Error reading at offset %d: errno=%d'), // 47 TXT_DEVICE_READ_ERROR
    ('Fehler bei fsync: errno=%d', 'Error during fsync: errno=%d'), // 48 TXT_FSYNC_ERROR
    ('Basisimage erfolgreich erstellt: %.2f MiB', 'Base image created successfully: %.2f MiB'), // 49 TXT_BASE_IMAGE_SIZE
    ('Fehler: Basisimage konnte nicht geöffnet werden: errno=%d', 'Error: Could not open base image: errno=%d'), // 50 TXT_BASE_IMAGE_OPEN_ERROR
    ('Fehler beim Lesen des Basisimage-Headers.', 'Error reading base image header.'), // 51 TXT_BASE_IMAGE_HEADER_ERROR
    ('Fehler: Ungültiges Basisimage.', 'Error: Invalid base image.'), // 52 TXT_INVALID_BASE_IMAGE
    ('Fehler: Nicht unterstützte Basisimage-Version.', 'Error: Unsupported base image version.'), // 53 TXT_UNSUPPORTED_BASE_VERSION
    ('Fehler: Sektorgrößen stimmen nicht überein.', 'Error: Sector sizes do not match.'), // 54 TXT_SECTOR_SIZE_MISMATCH
    ('Fehler: Devicegröße und Basisimagegröße stimmen nicht überein.', 'Error: Device size and base image size do not match.'), // 55 TXT_DEVICE_BASE_SIZE_MISMATCH
    ('Fehler beim Lesen der Basis-Bitmap.', 'Error reading base bitmap.'), // 56 TXT_BASE_BITMAP_READ_ERROR
    ('Fehler beim Erstellen der aktuellen Belegungs-Bitmap.', 'Error creating current usage bitmap.'), // 57 TXT_CURRENT_BITMAP_ERROR
    ('Fehler: Aktuelle Bitmapgröße stimmt nicht.', 'Error: Current bitmap size does not match.'), // 58 TXT_CURRENT_BITMAP_SIZE_ERROR
    ('Fehler: Differenzimage konnte nicht erstellt werden: errno=%d', 'Error: Could not create differential image: errno=%d'), // 59 TXT_DIFF_IMAGE_CREATE_ERROR
    ('Fehler beim Schreiben der komprimierten Diffdaten: errno=%d', 'Error writing compressed differential data: errno=%d'), // 60 TXT_DIFF_IMAGE_WRITE_ERROR
    ('Fehler beim Schreiben des Diff-Headers.', 'Error writing diff header.'), // 61 TXT_DIFF_HEADER_WRITE_ERROR
    ('Fehler beim Schreiben der Diff-Bitmap.', 'Error writing diff bitmap.'), // 62 TXT_DIFF_BITMAP_WRITE_ERROR
    ('Fehler beim Aktualisieren der Diff-Bitmap.', 'Error updating diff bitmap.'), // 63 TXT_DIFF_BITMAP_UPDATE_ERROR
    ('Fehler: Anzahl gelesener Basisdaten stimmt nicht.', 'Error: Amount of base data read does not match.'), // 64 TXT_BASE_DATA_TOO_SHORT
    ('Unerwartetes EOF des Basisimages.', 'Unexpected EOF of base image.'), // 65 TXT_BASE_EOF
    ('Fehler beim Lesen des Basisimages: errno=%d', 'Error reading base image: errno=%d'), // 66 TXT_BASE_READ_ERROR
    ('Fehler: Diffdaten enden zu früh.', 'Error: Differential data ends too early.'), // 67 TXT_DIFF_DATA_TOO_SHORT
    ('Unerwartetes EOF des Differenzimages.', 'Unexpected EOF of differential image.'), // 68 TXT_DIFF_EOF
    ('Fehler beim Lesen des Differenzimages: errno=%d', 'Error reading differential image: errno=%d'), // 69 TXT_DIFF_READ_ERROR
    ('ZSTD-Dekompressionsfehler im Differenzimage: %s', 'ZSTD decompression error in differential image: %s'), // 70 TXT_DIFF_ZSTD_ERROR
    ('Differenzimage erfolgreich erstellt.', 'Differential image successfully created.'), // 71 TXT_DIFF_CREATED
    ('Geänderte Sektoren: %d', 'Changed sectors: %d'), // 72 TXT_CHANGED_SECTORS
    ('Komprimierte Differenzdaten: %.2f MiB', 'Compressed differential data: %.2f MiB'), // 73 TXT_COMPRESSED_DIFF_DATA
    ('Fehler: Zielpartition konnte nicht ermittelt werden.', 'Error: Could not determine target partition.'), // 74 TXT_PARTITION_TARGET_ERROR
    ('Restore-Zielpartition: %s', 'Restore target partition: %s'), // 75 TXT_RESTORE_TARGET_PARTITION
    ('Ziellaufwerk: %s', 'Target drive: %s'), // 76 TXT_TARGET_drive
    ('Partitionsstart: %d Bytes', 'Partition start: %d bytes'), // 77 TXT_PARTITION_START
    ('Partitionsgröße: %d Bytes', 'Partition size: %d bytes'), // 78 TXT_PARTITION_SIZE_INFO
    ('Fehler: Zielpartition ist %d Bytes groß, Image erwartet %d Bytes.', 'Error: Target partition is %d bytes, image expects %d bytes.'), // 79 TXT_TARGET_PARTITION_SIZE_ERROR
    ('Fehler: Ziellaufwerk konnte nicht geöffnet werden: errno=%d', 'Error: Could not open target drive: errno=%d'), // 80 TXT_TARGET_DRIVE_OPEN_ERROR
    ('Fehler: Zielposition konnte nicht gesetzt werden: errno=%d', 'Error: Could not set target position: errno=%d'), // 81 TXT_TARGET_POSITION_ERROR
    ('Fehler: Ungültige Basisimage-Headergröße.', 'Error: Invalid base image header size.'), // 82 TXT_BASE_HEADER_SIZE_ERROR
    ('Fehler: Ungültige Sektorgröße.', 'Error: Invalid sector size.'), // 83 TXT_INVALID_SECTOR_SIZE
    ('Fehler: Ungültige Bitmapgröße.', 'Error: Invalid bitmap size.'), // 84 TXT_INVALID_BITMAP_SIZE
    ('Fehler: Anzahl belegter Sektoren stimmt nicht.', 'Error: Number of used sectors does not match.'), // 85 TXT_USED_SECTORS_COUNT_ERROR
    ('Fehler beim Lesen des Diff-Headers.', 'Error reading diff header.'), // 86 TXT_DIFF_HEADER_READ_ERROR
    ('Fehler: Ungültiges Differenzimage.', 'Error: Invalid differential image.'), // 87 TXT_INVALID_DIFF_IMAGE
    ('Fehler: Nicht unterstützte Diff-Version.', 'Error: Unsupported differential image version.'), // 88 TXT_UNSUPPORTED_DIFF_VERSION
    ('Fehler: Ungültige Diff-Headergröße.', 'Error: Invalid diff header size.'), // 89 TXT_DIFF_HEADER_SIZE_ERROR
    ('Fehler: Sektoranzahl stimmt nicht überein.', 'Error: Sector count does not match.'), // 90 TXT_SECTOR_COUNT_ERROR
    ('Fehler beim Lesen der Diff-Bitmap.', 'Error reading diff bitmap.'), // 91 TXT_DIFF_BITMAP_READ_ERROR
    ('Restore: %d Diff-Sektoren, komprimierter ZSTD-Stream.', 'Restore: %d differential sectors, compressed ZSTD stream.'), // 92 TXT_DIFF_INFO
    ('Fehler: Basis-ZSTD-Dekoder konnte nicht erstellt werden.', 'Error: Could not create base ZSTD decoder.'), // 93 TXT_BASE_DECODER_ERROR
    ('Fehler: Diff-ZSTD-Dekoder konnte nicht erstellt werden.', 'Error: Could not create differential ZSTD decoder.'), // 94 TXT_DIFF_DECODER_ERROR
    ('Fehler: Basis-ZSTD-Stream enthält zu wenig Daten.', 'Error: Base ZSTD stream contains insufficient data.'), // 95 TXT_BASE_ZSTD_STREAM_ERROR
    ('Fehler: Diff-ZSTD-Stream enthält zu wenig Daten.', 'Error: Differential ZSTD stream contains insufficient data.'), // 96 TXT_DIFF_ZSTD_STREAM_ERROR
    ('Fehler: Anzahl gelesener Basisdaten stimmt nicht.', 'Error: Amount of base data read does not match.'), // 97 TXT_BASE_DATA_COUNT_ERROR
    ('Fehler: Anzahl gelesener Diffdaten stimmt nicht.', 'Error: Amount of differential data read does not match.'), // 98 TXT_DIFF_DATA_COUNT_ERROR
    ('Restore des Basis-/Differenzimages erfolgreich abgeschlossen.', 'Base/differential image restore completed successfully.'), // 99 TXT_RESTORE_SUCCESS
    ('Geschriebene Daten: %.2f GiB', 'Data written: %.2f GiB'), // 100 TXT_WRITTEN_DATA
    ('Ziel: %s, Partitionsstart: %d Bytes', 'Target: %s, partition start: %d bytes'), // 101 TXT_RESTORE_TARGET
    ('Fehler beim Restore: %s', 'Restore error: %s'), // 102 TXT_RESTORE_ERROR_MESSAGE
    ('Fehler: ZSTD-Dekoder konnte nicht erstellt werden.', 'Error: Could not create ZSTD decoder.'), // 103 TXT_ZSTD_DECODER_ERROR
    ('Fehler: Basisdaten enden zu früh.', 'Error: Base data ends too early.'), // 104 TXT_BASE_DATA_END_ERROR
    ('Fehler: Diffdaten enden zu früh.', 'Error: Differential data ends too early.'), // 105 TXT_DIFF_DATA_END_ERROR
    ('Fehler: Diff-Puffer ist kein Vielfaches der Sektorgröße.', 'Error: Differential buffer size is not a multiple of the sector size.'), // 106 TXT_DIFF_BUFFER_SIZE_ERROR
    ('Fehler: Zielgröße konnte nicht ermittelt werden.', 'Error: Could not determine target size.'), // 107 TXT_TARGET_SIZE_ERROR
    ('Fehler beim Schreiben bei Partitionsoffset %d: errno=%d', 'Error writing at partition offset %d: errno=%d.'), // 108 TXT_TARGET_WRITE_ERROR
    ('Sektoren: %d', 'Sectors: %d'), // 109 TXT_SECTOR_COUNT
    ('Bitmapgröße: %.2f MiB', 'Bitmap size: %.2f MiB'), // 110 TXT_BITMAP_SIZE
    ('Fehler beim Erstellen der Bitmap-Datei: errno=%d', 'Error creating bitmap file: errno=%d'), // 111 TXT_BITMAP_CREATE_FILE_ERROR
    ('Bitmap erfolgreich erstellt: %s', 'Bitmap created successfully: %s'), // 112 TXT_BITMAP_CREATED
    ('Komprimierungsfehler: %s', 'Compression error: %s'), // 113 TXT_ZSTD_COMPRESS_ERROR
    ('Geschwindigkeit: %.2f MB/s  Restzeit: %s  Verhältnis: %.2f:1', 'Speed: %.2f MB/s  ETA: %s  Ratio: %.2f:1'), // 114 TXT_ZSTD_SPEED_ETA_RATIO
    ('Prozess durch Benutzer abgebrochen', 'Process cancelled by user'), // 115 TXT_CANCELLED
    ('Kein Laufwerk ausgewählt', 'No drive selected'), // 116 TXT_Drive_NOT_SELECTED
    ('abbrechen', 'abort'), // 117 TXT_abort
    ('EN', 'DE'), // 118 TXT_lang
    ('Image erstellen', 'create image'), // 119 TXT_lang_create
    ('Wiederherstellung', 'restore target'), // 120 TXT_lang_restore
    ('Quelllaufwerk', 'source drive'), // 121 txt_sourcedrive
    ('Ziellaufwerk', 'target drive'), // 122 txt_targetdrive
    ('Image-Ordner', 'image folder'), // 123 txt_imagefolder
    ('Hilfe', 'help'), // 124 txt_help
    ('Kein Zielordner angegeben.', 'No destination folder specified.'), // 125 TXT_NO_DESTINATION_FOLDER
    ('Zielordner existiert nicht: %s', 'Destination folder does not exist: %s'), // 126 TXT_DESTINATION_NOT_EXIST
    ('Zielordner konnte nicht erstellt werden: %s', 'Could not create destination folder: %s'), // 127 TXT_DESTINATION_CREATE_ERROR
    ('Kein Laufwerk angegeben.', 'No device specified.'), // 128 TXT_NO_DEVICE_SPECIFIED
    ('Das ausgewählte Laufwerk ist kein vollständiges Laufwerk: %s', 'The selected device is not a complete disk: %s'), // 129 TXT_NOT_COMPLETE_DISK
    ('Quelllaufwerk: %s', 'Source drive: %s'), // 130 TXT_SOURCE_DRIVE
    ('Systempartition: %s', 'System partition: %s'), // 131 TXT_SYSTEM_PARTITION
    ('Systempartition nicht gefunden: %s', 'System partition not found: %s'), // 132 TXT_SYSTEM_PARTITION_NOT_FOUND
    ('Basisimage existiert bereits.', 'Base image already exists.'), // 133 TXT_BASE_IMAGE_EXISTS
    ('Erstelle Differenzimage...', 'Creating differential image...'), // 134 TXT_CREATING_DIFFERENTIAL
    ('Erstelle MBR-Image...', 'Creating MBR image...'), // 135 TXT_MBR_CREATING
    ('Erstellen des MBR-Images fehlgeschlagen.', 'MBR image creation failed.'), // 136 TXT_MBR_CREATE_ERROR
    ('MBR-Image erstellt: %s', 'MBR image created: %s'), // 137 TXT_MBR_CREATED
    ('Bootpartition: %s', 'Boot partition: %s'), // 138 TXT_BOOT_PARTITION
    ('Bootpartition nicht gefunden: %s', 'Boot partition not found: %s'), // 139 TXT_BOOT_PARTITION_NOT_FOUND
    ('Erstelle vollständiges Bootimage...', 'Creating full boot image...'), // 140 TXT_CREATING_FULL_BOOT_IMAGE
    ('Erstellen des Bootimages fehlgeschlagen.', 'Boot image creation failed.'), // 141 TXT_BOOT_IMAGE_CREATE_ERROR
    ('Bootimage erstellt: %s', 'Boot image created: %s'), // 142 TXT_BOOT_IMAGE_CREATED
    ('Alle Images erfolgreich erstellt.', 'All images created successfully.'), // 143 TXT_ALL_IMAGES_CREATED
    ('Bitte mindestens eine Wiederherstellungsoption auswählen.', 'Please select at least one restore option.'), // 144 TXT_PLEASE_SELECT_RESTORE_OPTION
    ('Sicherheitsabfrage', 'Security confirmation'), // 145 TXT_SECURITY_QUERY
    ('ACHTUNG!', 'WARNING!'), // 146 TXT_WARNING
    ('Ziellaufwerk:', 'Target drive:'), // 147 TXT_TARGET_DRIVE_INFO
    ('Folgende Daten werden auf dieses Laufwerk geschrieben:', 'The following data will be written to this drive:'), // 148 TXT_DATA_WRITTEN_TO_DRIVE
    ('MBR', 'MBR'), // 149 TXT_MBR
    ('Boot-Partition', 'Boot partition'), // 150 TXT_BOOT_PARTITION_NAME
    ('System-Partition', 'System partition'), // 151 TXT_SYSTEM_PARTITION_NAME
    ('Die vorhandenen Daten in den ausgewählten Bereichen', 'The existing data in the selected areas'), // 152 TXT_EXISTING_DATA_OVERWRITTEN
    ('werden dabei unwiderruflich überschrieben.', 'will be irreversibly overwritten.'), // 153 TXT_CONFIRM_CONTINUE
    ('Möchten Sie wirklich fortfahren?', 'Do you really want to continue?'), // 154 TXT_COMPLETE_DISK_RESTORE
    ('Bitte ein vollständiges Laufwerk für die Wiederherstellung auswählen.', 'Please select a complete disk for restore.'), // 155 TXT_IMAGE_FILE_NOT_SELECTED
    ('Keine Image-Datei ausgewählt.', 'No image file selected.'), // 156 TXT_IMAGE_FILE_NOT_EXIST
    ('Image-Datei existiert nicht: %s', 'Image file does not exist: %s'), // 157 TXT_NO_MBR_IMAGE
    ('Kein MBR-Image gefunden in: %s', 'No MBR image found in: %s'), // 158 TXT_MBR_IMAGE_NOT_EXIST
    ('MBR-Image existiert nicht: %s', 'MBR image does not exist: %s'), // 159 TXT_NO_BOOT_IMAGE
    ('Kein Bootimage gefunden in: %s', 'No boot image found in: %s'), // 160 TXT_BOOT_IMAGE_NOT_EXIST
    ('Bootimage existiert nicht: %s', 'Boot image does not exist: %s'), // 161 TXT_NO_BASE_IMAGE
    ('Kein Basisimage gefunden in: %s', 'No base image found in: %s'), // 162 TXT_BASE_IMAGE_NOT_EXIST
    ('Basisimage existiert nicht: %s', 'Base image does not exist: %s'), // 163 TXT_UNMOUNTING
    ('Stelle MBR wieder her...', 'Restoring MBR...'), // 164 TXT_RESTORING_MBR
    ('Wiederherstellung des MBR fehlgeschlagen.', 'MBR restore failed.'),  // 165 TXT_MBR_RESTORE_ERROR
    ('MBR erfolgreich wiederhergestellt.', 'MBR restored successfully.'),  // 166 TXT_MBR_RESTORED
    ('Stelle Bootpartition wieder her: %s', 'Restoring boot partition: %s'), // 167 TXT_RESTORING_BOOT
    ('Wiederherstellung des Bootimages fehlgeschlagen.', 'Boot restore failed.'), // 168 TXT_BOOT_RESTORE_ERROR
    ('Bootpartition erfolgreich wiederhergestellt.', 'Boot partition restored successfully.'), // 169 TXT_BOOT_RESTORED
    ('Stelle Systempartition wieder her: %s', 'Restoring system partition: %s'),   // 170 TXT_RESTORING_SYSTEM
    ('Systemimage erfolgreich wiederhergestellt.', 'System image restored successfully.'),  // 171 TXT_SYSTEM_RESTORE_SUCCESS
    ('Alle ausgewählten Images erfolgreich wiederhergestellt.', 'All selected images restored successfully.'),  // 172 TXT_ALL_SELECTED_RESTORED
    ('Kein MBR-Image gefunden.', 'MBR image not found.'),  // 173 TXT_MBR_NOT_FOUND
    ('MBR erfolgreich wiederhergestellt.', 'MBR restored.'), // 174 TXT_MBR_RESTORE_SUCCESS
    ('Das ausgewählte Laufwerk ist kein vollständiges Laufwerk.', 'The selected device is not a complete disk.'), // 175 TXT_DEVICE_NOT_COMPLETE_DISK
    ('Kein Basisimage für die Wiederherstellung gefunden.', 'No base image found for restore.'),// 176 TXT_NO_BASE_IMAGE_RESTORE
    ('Alle Images erfolgreich erstellt.', 'All images created successfully.'),// 177 TXT_ALL_IMAGES_SUCCESS
    ('Zielordner', 'Destination folder'),   // 178 TXT_DESTINATION_FOLDER
    ('Systemimage', 'System image'), // 179 TXT_SYSTEM_IMAGE
    ('Bitte warten, bis alle Daten auf das Laufwerk geschrieben wurden...','Please wait until all data has been written to the drive...'),
    ('The following partitions extend beyond the end of the target drive:', 'Die folgenden Partitionen reichen über das Ziellaufwerk hinaus'),
    ('These invalid partition entries will be removed from the MBR before it is restored.', 'Diese ungültigen Partitionseinträge werden vor der Wiederherstellung aus dem MBR entfernt.')
  );


var
  CurrentLanguage: Integer = LANG_GERMAN;

function _(ID: Integer): string;

implementation

function _(ID: Integer): string;
begin
  if (ID >= Low(LanguageTexts)) and (ID <= High(LanguageTexts)) then
    Result := LanguageTexts[ID,CurrentLanguage]
  else
    Result := '';
end;

end.





