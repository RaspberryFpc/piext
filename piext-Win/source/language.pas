unit Language;

{$mode objfpc}{$H+}

interface

const
  LANG_GERMAN = 0;
  LANG_ENGLISH = 1;

  TXT_ETA_HOURS = 1;
  TXT_PLEASE_SELECT_RESTORE_OPTION = 2;
  TXT_DRIVE_NOT_SELECTED = 3;
  TXT_SECURITY_QUERY = 4;
  TXT_WARNING = 5;
  TXT_TARGET_DRIVE_INFO = 6;
  TXT_DATA_WRITTEN_TO_DRIVE = 7;
  TXT_MBR = 8;
  TXT_BOOT_PARTITION_NAME = 9;
  TXT_SYSTEM_PARTITION_NAME = 10;
  TXT_INVALID_PART_DETECTED = 11;
  TXT_INVALID_REMOVE = 12;
  TXT_EXISTING_DATA_OVERWRITTEN = 13;
  TXT_CONFIRM_CONTINUE = 14;
  TXT_CANCELLED = 15;
  TXT_NO_BOOT_IMAGE = 16;
  TXT_NO_BASE_IMAGE = 17;
  TXT_RESTORING_BOOT = 18;
  TXT_BOOT_RESTORE_ERROR = 19;
  TXT_BOOT_RESTORED = 20;
  TXT_RESTORING_SYSTEM = 21;
  TXT_RESTORE_ERROR = 22;
  TXT_SYSTEM_RESTORE_SUCCESS = 23;
  TXT_ALL_SELECTED_RESTORED = 24;
  TXT_INVALID_PHYSICAL_DRIVE = 25;
  TXT_LOCK_PARTITIONS_FAILED = 26;
  TXT_LOCK_PARTITIONS = 27;
  TXT_PARTITIONS_LOCKED = 28;
  TXT_IMAGE_INVALID = 29;
  TXT_OPEN_IMAGE_FILTER = 30;
  TXT_LABEL_IMAGE = 31;
  TXT_LABEL_DEVICE = 32;
  TXT_CHECK_MBR = 33;
  TXT_CHECK_BOOT = 34;
  TXT_CHECK_SYSTEM = 35;
  TXT_BUTTON_BROWSE = 36;
  TXT_BUTTON_START = 37;
  TXT_BUTTON_CANCEL = 38;
  TXT_INVALID_DISK_SIZE = 39;
  TXT_PARTITION = 40;

  TXT_BASE_BITMAP_READ_ERROR = 41;
  TXT_BASE_DATA_COUNT_ERROR = 42;
  TXT_BASE_DATA_TOO_SHORT = 43;
  TXT_BASE_DECODER_ERROR = 44;
  TXT_BASE_EOF = 45;
  TXT_BASE_HEADER_SIZE_ERROR = 46;
  TXT_BASE_IMAGE_HEADER_ERROR = 47;
  TXT_BASE_IMAGE_OPEN_ERROR = 48;
  TXT_BASE_READ_ERROR = 49;
  TXT_BASE_ZSTD_STREAM_ERROR = 50;
  TXT_DEVICE_BASE_SIZE_MISMATCH = 51;
  TXT_DIFF_BITMAP_READ_ERROR = 52;
  TXT_DIFF_DATA_COUNT_ERROR = 53;
  TXT_DIFF_DATA_TOO_SHORT = 54;
  TXT_DIFF_DECODER_ERROR = 55;
  TXT_DIFF_EOF = 56;
  TXT_DIFF_HEADER_READ_ERROR = 57;
  TXT_DIFF_HEADER_SIZE_ERROR = 58;
  TXT_DIFF_IMAGE_CREATE_ERROR = 59;
  TXT_DIFF_INFO = 60;
  TXT_DIFF_READ_ERROR = 61;
  TXT_DIFF_ZSTD_ERROR = 62;
  TXT_DIFF_ZSTD_STREAM_ERROR = 63;
  TXT_FSYNC_ERROR = 64;
  TXT_INVALID_BASE_IMAGE = 65;
  TXT_INVALID_BITMAP_SIZE = 66;
  TXT_INVALID_DIFF_IMAGE = 67;
  TXT_INVALID_SECTOR_SIZE = 68;
  TXT_OPERATION_CANCELLED = 69;
  TXT_PARTITION_SIZE_INFO = 70;
  TXT_PARTITION_START = 71;
  TXT_RESTORE_ERROR_MESSAGE = 72;
  TXT_RESTORE_SUCCESS = 73;
  TXT_RESTORE_TARGET = 74;
  TXT_RESTORE_TARGET_PARTITION = 75;
  TXT_SECTOR_COUNT_ERROR = 76;
  TXT_SECTOR_SIZE_MISMATCH = 77;
  TXT_TARGET_DRIVE = 78;
  TXT_TARGET_DRIVE_OPEN_ERROR = 79;
  TXT_TARGET_POSITION_ERROR = 80;
  TXT_UNSUPPORTED_BASE_VERSION = 81;
  TXT_UNSUPPORTED_DIFF_VERSION = 82;
  TXT_USED_SECTORS_COUNT_ERROR = 83;
  TXT_WRITTEN_DATA = 84;
  TXT_ZSTD_COMPRESSION_ERROR = 85;
  TXT_RESTORE_SPEED = 86;
  TXT_ETA_DAYS = 87;
  TXT_ETA_TIME = 88;
  TXT_BASE_ONLY_RESTORE = 89;
  TXT_BASE_RESTORE_SUCCESS = 90;
  TXT_MBR_IMAGE_OPEN_ERROR = 91;
  TXT_MBR_IMAGE_TOO_SHORT = 92;
  TXT_MBR_DEVICE_OPEN_ERROR = 93;
  TXT_MBR_WRITE_ERROR = 94;
  TXT_MBR_RESTORE_SUCCESS = 95;
  TXT_MBR_RESTORE_ERROR = 96;
  TXT_VOLUME_LETTERS_ERROR = 97;
  TXT_VOLUME_LOCK_ERROR = 98;
  TXT_VOLUME_DISMOUNT_ERROR = 99;
  TXT_INVALID_PARTITION_OFFSET_SIZE = 100;
  TXT_IMAGE_FILE_OPEN_ERROR = 101;
  TXT_DRIVE_GEOMETRY_ERROR = 102;
  TXT_SECTOR_SIZE_QUERY_ERROR = 103;
  TXT_INVALID_LOGICAL_SECTOR_SIZE = 104;
  TXT_TARGET_DRIVE_OPEN_ERROR2 = 105;
  TXT_PARTITION_OFFSET_SET_ERROR = 106;
  TXT_PARTITION_OFFSET_ALIGNMENT = 107;
  TXT_IMAGE_READ_ERROR = 108;
  TXT_IMAGE_TOO_LARGE = 109;
  TXT_WRITE_ERROR_DETAIL = 110;
  TXT_NO_DATA_WRITTEN = 111;
  TXT_INCOMPLETE_SECTOR_WRITE = 112;
  TXT_INCOMPLETE_FINAL_SECTOR = 113;
  TXT_IMAGE_PARTITION_SIZE_MISMATCH = 114;
  TXT_FLUSH_FAILED = 115;
  TXT_BOOT_PARTITION_WRITTEN = 116;
  TXT_BOOT_RESTORE_ERROR_DETAIL = 117;
  TXT_MBR_IMAGE_TOO_SMALL = 118;
  TXT_MBR_IMAGE_TOO_SMALL_DE = 119;
  TXT_CANNOT_OPEN_TARGET_DRIVE = 120;
  TXT_ERROR_WRITING_MBR = 121;
  TXT_MBR_INCOMPLETE_WRITE = 122;
  TXT_CANNOT_OPEN_TARGET_DRIVE_DE = 123;
  TXT_ERROR_WRITING_MBR_DE = 124;
  TXT_MBR_INCOMPLETE_WRITE_DE = 125;
  TXT_NO_DRIVE_LETTERS = 126;
  TXT_CANNOT_OPEN_PHYSICAL_DRIVE = 127;
  TXT_DRIVE_SIZE_CREATEFILE_ERROR = 128;
  TXT_DRIVE_SIZE_IOCTL_ERROR = 129;
  TXT_Restore_of = 130;
 //  = 131;
 //  = 132;
 //  = 133;
  TXT_ZSTD_CONTEXT_CREATE_ERROR = 134;
  TXT_ZSTD_DECOMPRESSION_ERROR = 135;
  TXT_ZSTD_INCOMPLETE_FILE = 136;
  TXT_ZSTD_PROGRESS = 137;
type
  TLanguageTexts = array[1..137, 0..1] of string;

const
  LanguageTexts: TLanguageTexts = (
  ('ETA %d:%2.2d:%2.2d', 'ETA %d:%2.2d:%2.2d'), // 1
  ('Bitte mindestens eine Wiederherstellungsoption auswählen.', 'Please select at least one restore option.'), // 2
  ('Kein Ziellaufwerk ausgewählt.', 'No target drive selected.'), // 3
  ('Sicherheitsabfrage', 'Security confirmation'), // 4
  ('WARNUNG!', 'WARNING!'), // 5
  ('Ziel-Laufwerk:', 'Target drive:'), // 6
  ('Folgende Daten werden auf das Laufwerk geschrieben:', 'The following data will be written to the drive:'), // 7
  ('MBR', 'MBR'), // 8
  ('Boot-Partition', 'Boot partition'), // 9
  ('System-Partition', 'System partition'), // 10
  ('Ungültige Partitionen wurden erkannt:', 'Invalid partitions have been detected:'), // 11
  ('Diese Partitionen werden entfernt.', 'These partitions will be removed.'), // 12
  ('Vorhandene Daten auf dem Ziellaufwerk werden überschrieben!', 'Existing data on the target drive will be overwritten!'), // 13
  ('Möchten Sie wirklich fortfahren?', 'Do you really want to continue?'), // 14
  ('Vorgang abgebrochen.', 'Operation cancelled.'), // 15
  ('Keine Boot-Image-Datei im Verzeichnis gefunden:'#13#10'%s', 'No boot image file found in directory:'#13#10'%s'), // 16
  ('Keine Base-Image-Datei im Verzeichnis gefunden:'#13#10'%s', 'No base image file found in directory:'#13#10'%s'), // 17
  ('Boot-Image wird auf %s wiederhergestellt ...', 'Restoring boot image to %s ...'), // 18
  ('Fehler beim Wiederherstellen des Boot-Images.', 'Error restoring boot image.'), // 19
  ('Boot-Image erfolgreich wiederhergestellt.', 'Boot image restored successfully.'), // 20
  ('System-Image wird auf %s wiederhergestellt ...', 'Restoring system image to %s ...'), // 21
  ('Fehler beim Wiederherstellen des System-Images.', 'Error restoring system image.'), // 22
  ('System-Image erfolgreich wiederhergestellt.', 'System image restored successfully.'), // 23
  ('Alle ausgewählten Bereiche wurden wiederhergestellt.', 'All selected items have been restored.'), // 24
  ('Ungültiges physisches Laufwerk: %s', 'Invalid physical drive: %s'), // 25
  ('Partitionen konnten nicht vollständig gesperrt werden.', 'Could not lock all partitions.'), // 26
  ('Partitionen auf dem Ziellaufwerk werden gesperrt ...', 'Locking partitions on target drive ...'), // 27
  ('Partitionen gesperrt.', 'Partitions locked.'), // 28
  ('Die ausgewählte Datei ist kein gültiges PiExt-Image.', 'The selected file is not a valid PiExt image.'), // 29
  ('PiExt-Images (*.zst)|*.zst|Alle Dateien (*.*)|*.*', 'PiExt images (*.zst)|*.zst|All files (*.*)|*.*'), // 30
  ('Image-Datei:', 'Image file:'), // 31
  ('Ziellaufwerk:', 'Target drive:'), // 32
  ('MBR wiederherstellen', 'Restore MBR'), // 33
  ('Boot-Partition wiederherstellen', 'Restore boot partition'), // 34
  ('System-Partition wiederherstellen', 'Restore system partition'), // 35
  ('Durchsuchen ...', 'Browse ...'), // 36
  ('Start', 'Start'), // 37
  ('Abbrechen', 'Cancel'), // 38
  ('Größe des Ziellaufwerks kann nicht ermittelt werden: %s', 'Cannot determine target disk size: %s'), // 39
  ('Partition', 'Partition'), // 40
  ('Fehler beim Lesen der Base-Bitmap.', 'Error reading base bitmap.'), // 41
  ('Die Anzahl der gelesenen Base-Daten stimmt nicht mit dem Image-Header überein.', 'The amount of base data read does not match the image header.'), // 42
  ('Die Base-Image-Daten sind unvollständig.', 'Base image data is incomplete.'), // 43
  ('Der Base-Image-Dekompressor konnte nicht erstellt werden.', 'Could not create the base image decompressor.'), // 44
  ('Unerwartetes Dateiende im Base-Image.', 'Unexpected end of file in base image.'), // 45
  ('Ungültige Größe des Base-Image-Headers.', 'Invalid base image header size.'), // 46
  ('Der Base-Image-Header konnte nicht gelesen werden.', 'Could not read the base image header.'), // 47
  ('Das Base-Image konnte nicht geöffnet werden. Windows-Fehler: %d', 'Could not open base image. Windows error: %d'), // 48
  ('Fehler beim Lesen des Base-Images. Windows-Fehler: %d', 'Error reading base image. Windows error: %d'), // 49
  ('Fehlerhafter oder unvollständiger ZSTD-Datenstrom im Base-Image.', 'Invalid or incomplete ZSTD stream in base image.'), // 50
  ('Die Größe der Systempartition stimmt nicht mit der Größe des Base-Images überein.', 'The system partition size does not match the base image size.'), // 51
  ('Fehler beim Lesen der Differential-Bitmap.', 'Error reading differential bitmap.'), // 52
  ('Die Anzahl der gelesenen Differentialdaten stimmt nicht mit dem Image überein.', 'The amount of differential data read does not match the image.'), // 53
  ('Die Differentialdaten sind unvollständig.', 'Differential data is incomplete.'), // 54
  ('Der Differential-Image-Dekompressor konnte nicht erstellt werden.', 'Could not create the differential image decompressor.'), // 55
  ('Unerwartetes Dateiende im Differential-Image.', 'Unexpected end of file in differential image.'), // 56
  ('Der Header des Differential-Images konnte nicht gelesen werden.', 'Could not read the differential image header.'), // 57
  ('Ungültige Größe des Differential-Image-Headers.', 'Invalid differential image header size.'), // 58
  ('Das Differential-Image konnte nicht geöffnet werden. Windows-Fehler: %d', 'Could not open differential image. Windows error: %d'), // 59
  ('Differential-Image: %d geänderte Sektoren.', 'Differential image: %d changed sectors.'), // 60
  ('Fehler beim Lesen des Differential-Images. Windows-Fehler: %d', 'Error reading differential image. Windows error: %d'), // 61
  ('ZSTD-Dekomprimierungsfehler im Differential-Image', 'ZSTD decompression error in differential image'), // 62
  ('Fehlerhafter oder unvollständiger ZSTD-Datenstrom im Differential-Image.', 'Invalid or incomplete ZSTD stream in differential image.'), // 63
  ('Die Daten auf dem Ziellaufwerk konnten nicht synchronisiert werden. Windows-Fehler: %d', 'Could not flush data to target drive. Windows error: %d'), // 64
  ('Ungültiges Base-Image.', 'Invalid base image.'), // 65
  ('Ungültige Bitmap-Größe im Base-Image.', 'Invalid bitmap size in base image.'), // 66
  ('Ungültiges Differential-Image.', 'Invalid differential image.'), // 67
  ('Ungültige Sektorgröße im Base-Image.', 'Invalid sector size in base image.'), // 68
  ('Wiederherstellung wurde vom Anwender abgebrochen.','Restore operation was cancelled by the user.'), // 69
  ('Größe der Zielpartition: %d Bytes', 'Target partition size: %d bytes'), // 70
  ('Startposition der Zielpartition: %d Bytes', 'Target partition start offset: %d bytes'), // 71
  ('Wiederherstellungsfehler: %s', 'Restore error: %s'), // 72
  ('System-Image erfolgreich wiederhergestellt.', 'System image restored successfully.'), // 73
  ('Wiederherstellung auf %s ab Offset %d abgeschlossen.', 'Restore to %s completed at offset %d.'), // 74
  ('Wiederherstellung der Systempartition auf %s.', 'Restoring system partition on %s.'), // 75
  ('Die Sektoranzahl im Differential-Image stimmt nicht mit dem Base-Image überein.', 'Sector count in differential image does not match base image.'), // 76
  ('Die Sektorgröße im Differential-Image stimmt nicht mit dem Base-Image überein.', 'Sector size in differential image does not match base image.'), // 77
  ('Ziellaufwerk: %s', 'Target drive: %s'), // 78
  ('Das Ziellaufwerk konnte nicht geöffnet werden. Windows-Fehler: %d', 'Could not open target drive. Windows error: %d'), // 79
  ('Die Position auf dem Ziellaufwerk konnte nicht gesetzt werden. Windows-Fehler: %d', 'Could not set position on target drive. Windows error: %d'), // 80
  ('Nicht unterstützte Version des Base-Images.', 'Unsupported base image version.'), // 81
  ('Nicht unterstützte Version des Differential-Images.', 'Unsupported differential image version.'), // 82
  ('Die Anzahl belegter Sektoren stimmt nicht mit der Base-Bitmap überein.', 'Used sector count does not match base bitmap.'), // 83
  ('Geschriebene Daten: %.2f GiB', 'Data written: %.2f GiB'), // 84
  ('ZSTD-Dekomprimierungsfehler im Base-Image', 'ZSTD decompression error in base image'), // 85
  ('%.2f MiB/s | Restzeit: %s', '%.2f MiB/s | ETA: %s'), // 86
  ('%d T %2.2d:%2.2d:%2.2d', '%d d %2.2d:%2.2d:%2.2d'), // 87
  ('%2.2d:%2.2d:%2.2d', '%2.2d:%2.2d:%2.2d'), // 88
  ('Wiederherstellung des Base-Images ohne Differential-Image.', 'Base image restore without differential image.'), // 89
  ('Base-Image erfolgreich wiederhergestellt.', 'Base image restored successfully.'), // 90
  ('MBR-Image kann nicht geöffnet werden: %s', 'Cannot open MBR image: %s'), // 91
  ('MBR-Image ist kürzer als 512 Bytes.', 'MBR image is shorter than 512 bytes.'), // 92
  ('Physisches Laufwerk kann nicht geöffnet werden: %s', 'Cannot open physical drive: %s'), // 93
  ('MBR konnte nicht vollständig geschrieben werden.', 'Could not write the complete MBR.'), // 94
  ('MBR erfolgreich wiederhergestellt.', 'MBR restored successfully.'), // 95
  ('Fehler bei RestoreMBR: %s', 'RestoreMBR error: %s'), // 96
  ('Laufwerksbuchstaben konnten nicht ermittelt werden: %s', 'Could not determine drive letters: %s'), // 97
  ('Volume %s konnte nicht gesperrt werden: %s', 'Could not lock volume %s: %s'), // 98
  ('Volume %s konnte nicht ausgehängt werden: %s', 'Could not dismount volume %s: %s'), // 99
  ('Ungültiger Partitionsoffset oder ungültige Partitionsgröße.', 'Invalid partition offset or partition size.'), // 100
  ('Image-Datei kann nicht geöffnet werden: %s: %s', 'Cannot open image file: %s: %s'), // 101
  ('Laufwerksgeometrie kann nicht abgefragt werden: %s', 'Could not query drive geometry: %s'), // 102
  ('Fehler beim Ermitteln der Sektorgröße: %s', 'Error retrieving sector size: %s'), // 103
  ('Ungültige logische Sektorgröße des Ziellaufwerks.', 'Invalid logical sector size of target drive.'), // 104
  ('Ziellaufwerk kann nicht geöffnet werden: %s: %s', 'Cannot open target drive: %s: %s'), // 105
  ('Partitionsoffset kann nicht gesetzt werden: %s', 'Could not set partition offset: %s'), // 106
  ('Der Partitionsoffset ist nicht sektorausgerichtet.', 'Partition offset is not sector-aligned.'), // 107
  ('Fehler beim Lesen der Image-Datei: %s', 'Error reading image file: %s'), // 108
  ('Das dekomprimierte Image ist größer als die Zielpartition.', 'The decompressed image is larger than the target partition.'), // 109
  ('Schreibfehler: %d - %s (Gerät: %s, Offset: %d, Bytes: %d)', 'Write error: %d - %s (Device: %s, offset: %d, bytes: %d)'), // 110
  ('Es wurden keine Daten auf das Ziellaufwerk geschrieben.', 'No data was written to the target drive.'), // 111
  ('Der Schreibvorgang lieferte keine vollständige Anzahl Sektoren.', 'The write operation did not return a whole number of sectors.'), // 112
  ('Fehler: Das Image endet mit einem unvollständigen Sektor.', 'Error: the image ends with an incomplete sector.'), // 113
  ('Fehler: Imagegröße (%d Bytes) stimmt nicht mit der Partitionsgröße (%d Bytes) überein.', 'Error: image size (%d bytes) does not match partition size (%d bytes).'), // 114
  ('FlushFileBuffers fehlgeschlagen: %s', 'FlushFileBuffers failed: %s'), // 115
  ('Bootpartition erfolgreich geschrieben: %s', 'Boot partition successfully written: %s'), // 116
  ('Fehler beim Wiederherstellen des Boot-Images: %s', 'Error restoring boot image: %s'), // 117
  ('MBR image is too small: %s', 'MBR image is too small: %s'), // 118
  ('MBR-Image ist zu klein: %s', 'MBR image is too small: %s'), // 119
  ('Ziellaufwerk %s kann nicht geöffnet werden: %s', 'Cannot open target drive %s: %s'), // 120
  ('Fehler beim Schreiben des MBR: %s', 'Error writing MBR: %s'), // 121
  ('MBR could not be written completely.', 'MBR could not be written completely.'), // 122
  ('Ziellaufwerk %s kann nicht geöffnet werden: %s', 'Cannot open target drive %s: %s'), // 123
  ('Fehler beim Schreiben des MBR: %s', 'Error writing MBR: %s'), // 124
  ('MBR konnte nicht vollständig geschrieben werden.', 'MBR could not be written completely.'), // 125
  ('keine', 'none'), // 126
  ('Physisches Laufwerk kann nicht geöffnet werden: %s', 'Cannot open physical drive: %s'), // 127
  ('%s: CreateFile fehlgeschlagen: %s', '%s: CreateFile failed: %s'), // 128
  ('%s: DeviceIoControl fehlgeschlagen: %s', '%s: DeviceIoControl failed: %s'), // 129
  ('Wiederherstellung von:','Restore of:'), // 130
  ('',''), // 131
  ('',''), // 132
  ('',''), // 133
  ('Fehler beim Erstellen des ZSTD-Dekomprimierungskontexts.', 'Failed to create the ZSTD decompression context.'), // 134
  ('ZSTD: %s', 'ZSTD: %s'), // 135
  ('ZSTD: Unvollständige oder beschädigte komprimierte Datei.', 'ZSTD: Incomplete or corrupted compressed file.'), // 136
  ('%.2f MB/s - Restzeit: %s', '%.2f MB/s - Remaining time: %s') // 137
  );

var
  CurrentLanguage: Integer = LANG_GERMAN;

function _(ID: Integer): string;

implementation

function _(ID: Integer): string;
begin
  if (ID >= Low(LanguageTexts)) and (ID <= High(LanguageTexts)) then
  begin
    if (CurrentLanguage < LANG_GERMAN) or (CurrentLanguage > LANG_ENGLISH) then
      CurrentLanguage := LANG_GERMAN;
    Result := LanguageTexts[ID, CurrentLanguage];
  end
  else
    Result := '';
end;



end.

