  unit Language;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

const
  LANG_GERMAN = 0;
  LANG_ENGLISH = 1;

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
  TXT_SOURCE_PARTITION = 18;
  TXT_TARGET_PARTITION = 19;
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
  TXT_TARGET_DRIVE = 76;
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
  TXT_CANCELLED=115;




type
  TLanguageTexts = array[1..115,0..1] of string;


const
  LanguageTexts: TLanguageTexts = (
    ('ETA %d:%2.2d:%2.2d','ETA %d:%2.2d:%2.2d'),
    ('ETA %2.2d:%2.2d','ETA %2.2d:%2.2d'),
    ('Partition nicht ausgewählt','Partition not selected'),
    ('Erzeuge differenzielles Image: %s','Creating differential image: %s'),
    ('Differenz-Image erfolgreich erstellt.','Differential image created successfully.'),
    ('Fehler beim Erstellen des Differenz-Images.','Error creating differential image.'),
    ('Basisimage erfolgreich erstellt.','Base image created successfully.'),
    ('Fehler beim Erstellen des Basisimages.','Error creating base image.'),
    ('ZSTD-Dateien','ZSTD files'),
    ('existiert nicht - Wiederherstellung abgebrochen','does not exist - restore suspended'),
    ('ist auf / gemountet - Wiederherstellung abgebrochen','is mounted on / - restore suspended'),
    ('wird wiederhergestellt.','will be restored.'),
    ('Alle vorhandenen Daten gehen verloren.','All existing data will be lost.'),
    ('Image erfolgreich wiederhergestellt.','Image restored successfully.'),
    ('Fehler bei der Wiederherstellung des Images.','Error restoring image.'),
    ('Image erstellen','Create image'),
    ('Image wiederherstellen','Restore image'),
    ('Quellpartition','Source partition'),
    ('Zielpartition','Target partition'),
    ('Image-Ordner','Image folder'),
    ('Image-Datei','Image file'),
    ('Kompressionsstufe','Compression level'),
    ('Ermittle Ext4-Belegung...','Determining Ext4 usage...'),
    ('Fehler: Ext4-Dateisystem konnte nicht gelesen werden.','Error: Could not read Ext4 filesystem.'),
    ('Fehler: Sektorgröße konnte nicht ermittelt werden.','Error: Could not determine sector size.'),
    ('Fehler: Ext4-Blockgröße ist kein Vielfaches der Sektorgröße.','Error: Ext4 block size is not a multiple of sector size.'),
    ('Fehler: Devicegröße konnte nicht ermittelt werden.','Error: Could not determine device size.'),
    ('Fehler: Devicegröße ist kein Vielfaches der Sektorgröße.','Error: Device size is not a multiple of sector size.'),
    ('Fehler beim Erstellen der Belegungs-Bitmap.','Error creating usage bitmap.'),
    ('Fehler: Bitmapgröße stimmt nicht.','Error: Bitmap size does not match.'),
    ('Partitionsgröße: %.2f GiB','Partition size: %.2f GiB'),
    ('Belegte Sektoren: %d','Used sectors: %d'),
    ('Nur belegte Daten werden gespeichert: %.2f GiB','Only used data is stored: %.2f GiB'),
    ('Fehler: Device konnte nicht geöffnet werden: errno=%d','Error: Could not open device: errno=%d'),
    ('Fehler: Basisimage konnte nicht erstellt werden: errno=%d','Error: Could not create base image: errno=%d'),
    ('Fehler beim Schreiben des Headers: errno=%d','Error writing header: errno=%d'),
    ('Fehler beim Schreiben der Bitmap: errno=%d','Error writing bitmap: errno=%d'),
    ('Fehler: ZSTD_createCCtx fehlgeschlagen.','Error: ZSTD_createCCtx failed.'),
    ('ZSTD-Kompressionsfehler: %s','ZSTD compression error: %s'),
    ('ZSTD-Finalisierungsfehler: %s','ZSTD finalization error: %s'),
    ('Fehler beim Schreiben des Basisimages: errno=%d','Error writing base image: errno=%d'),
    ('Set compression level failed','Set compression level failed'),
    ('Set thread count failed','Set thread count failed'),
    ('Enable long mode failed','Enable long mode failed'),
    ('ZSTD: Level %d, --long, %d Threads','ZSTD: Level %d, --long, %d threads'),
    ('Operation abgebrochen.','Operation cancelled.'),
    ('Fehler beim Lesen bei Offset %d: errno=%d','Error reading at offset %d: errno=%d'),
    ('Fehler bei fsync: errno=%d','Error during fsync: errno=%d'),
    ('Basisimage erfolgreich erstellt: %.2f MiB','Base image created successfully: %.2f MiB'),
    ('Fehler: Basisimage konnte nicht geöffnet werden: errno=%d','Error: Could not open base image: errno=%d'),
    ('Fehler beim Lesen des Basisimage-Headers.','Error reading base image header.'),
    ('Fehler: Ungültiges Basisimage.','Error: Invalid base image.'),
    ('Fehler: Nicht unterstützte Basisimage-Version.','Error: Unsupported base image version.'),
    ('Fehler: Sektorgrößen stimmen nicht überein.','Error: Sector sizes do not match.'),
    ('Fehler: Devicegröße und Basisimagegröße stimmen nicht überein.','Error: Device size and base image size do not match.'),
    ('Fehler beim Lesen der Basis-Bitmap.','Error reading base bitmap.'),
    ('Fehler beim Erstellen der aktuellen Belegungs-Bitmap.','Error creating current usage bitmap.'),
    ('Fehler: Aktuelle Bitmapgröße stimmt nicht.','Error: Current bitmap size does not match.'),
    ('Fehler: Differenzimage konnte nicht erstellt werden: errno=%d','Error: Could not create differential image: errno=%d'),
    ('Fehler beim Schreiben der komprimierten Diffdaten: errno=%d','Error writing compressed differential data: errno=%d'),
    ('Fehler beim Schreiben des Diff-Headers.','Error writing diff header.'),
    ('Fehler beim Schreiben der Diff-Bitmap.','Error writing diff bitmap.'),
    ('Fehler beim Aktualisieren der Diff-Bitmap.','Error updating diff bitmap.'),
    ('Fehler: Anzahl gelesener Basisdaten stimmt nicht.','Error: Amount of base data read does not match.'),
    ('Unerwartetes EOF des Basisimages.','Unexpected EOF of base image.'),
    ('Fehler beim Lesen des Basisimages: errno=%d','Error reading base image: errno=%d'),
    ('Fehler: Diffdaten enden zu früh.','Error: Differential data ends too early.'),
    ('Unerwartetes EOF des Differenzimages.','Unexpected EOF of differential image.'),
    ('Fehler beim Lesen des Differenzimages: errno=%d','Error reading differential image: errno=%d'),
    ('ZSTD-Dekompressionsfehler im Differenzimage: %s','ZSTD decompression error in differential image: %s'),
    ('Differenzimage erfolgreich erstellt.','Differential image successfully created.'),
    ('Geänderte Sektoren: %d','Changed sectors: %d'),
    ('Komprimierte Differenzdaten: %.2f MiB','Compressed differential data: %.2f MiB'),
    ('Fehler: Zielpartition konnte nicht ermittelt werden.','Error: Could not determine target partition.'),
    ('Restore-Zielpartition: %s','Restore target partition: %s'),
    ('Ziellaufwerk: %s','Target drive: %s'),
    ('Partitionsstart: %d Bytes','Partition start: %d bytes'),
    ('Partitionsgröße: %d Bytes','Partition size: %d bytes'),
    ('Fehler: Zielpartition ist %d Bytes groß, Image erwartet %d Bytes.','Error: Target partition is %d bytes, image expects %d bytes.'),
    ('Fehler: Ziellaufwerk konnte nicht geöffnet werden: errno=%d','Error: Could not open target drive: errno=%d'),
    ('Fehler: Zielposition konnte nicht gesetzt werden: errno=%d','Error: Could not set target position: errno=%d'),
    ('Fehler: Ungültige Basisimage-Headergröße.','Error: Invalid base image header size.'),
    ('Fehler: Ungültige Sektorgröße.','Error: Invalid sector size.'),
    ('Fehler: Ungültige Bitmapgröße.','Error: Invalid bitmap size.'),
    ('Fehler: Anzahl belegter Sektoren stimmt nicht.','Error: Number of used sectors does not match.'),
    ('Fehler beim Lesen des Diff-Headers.','Error reading diff header.'),
    ('Fehler: Ungültiges Differenzimage.','Error: Invalid differential image.'),
    ('Fehler: Nicht unterstützte Diff-Version.','Error: Unsupported differential image version.'),
    ('Fehler: Ungültige Diff-Headergröße.','Error: Invalid diff header size.'),
    ('Fehler: Sektoranzahl stimmt nicht überein.','Error: Sector count does not match.'),
    ('Fehler beim Lesen der Diff-Bitmap.','Error reading diff bitmap.'),
    ('Restore: %d Diff-Sektoren, komprimierter ZSTD-Stream.','Restore: %d differential sectors, compressed ZSTD stream.'),
    ('Fehler: Basis-ZSTD-Dekoder konnte nicht erstellt werden.','Error: Could not create base ZSTD decoder.'),
    ('Fehler: Diff-ZSTD-Dekoder konnte nicht erstellt werden.','Error: Could not create differential ZSTD decoder.'),
    ('Fehler: Basis-ZSTD-Stream enthält zu wenig Daten.','Error: Base ZSTD stream contains insufficient data.'),
    ('Fehler: Diff-ZSTD-Stream enthält zu wenig Daten.','Error: Differential ZSTD stream contains insufficient data.'),
    ('Fehler: Anzahl gelesener Basisdaten stimmt nicht.','Error: Amount of base data read does not match.'),
    ('Fehler: Anzahl gelesener Diffdaten stimmt nicht.','Error: Amount of differential data read does not match.'),
    ('Restore des Basis-/Differenzimages erfolgreich abgeschlossen.','Base/differential image restore completed successfully.'),
    ('Geschriebene Daten: %.2f GiB','Data written: %.2f GiB'),
    ('Ziel: %s, Partitionsstart: %d Bytes','Target: %s, partition start: %d bytes'),
    ('Fehler beim Restore: %s','Restore error: %s'),
      ('Fehler: ZSTD-Dekoder konnte nicht erstellt werden.','Error: Could not create ZSTD decoder.'),
  ('Fehler: Basisdaten enden zu früh.','Error: Base data ends too early.'),
  ('Fehler: Diffdaten enden zu früh.','Error: Differential data ends too early.'),
     ('Fehler: Diff-Puffer ist kein Vielfaches der Sektorgröße.','Error: Differential buffer size is not a multiple of the sector size.'),
    ('Fehler: Zielgröße konnte nicht ermittelt werden.','Error: Could not determine target size.'),
    ('Fehler beim Schreiben bei Partitionsoffset %d: errno=%d','Error writing at partition offset %d: errno=%d.'),
    ('Sektoren: %d','Sectors: %d'),
    ('Bitmapgröße: %.2f MiB','Bitmap size: %.2f MiB'),
    ('Fehler beim Erstellen der Bitmap-Datei: errno=%d','Error creating bitmap file: errno=%d'),
    ('Bitmap erfolgreich erstellt: %s','Bitmap created successfully: %s'),
    ('Komprimierungsfehler: %s','Compression error: %s'),
    ('Geschwindigkeit: %.2f MB/s  Restzeit: %s  Verhältnis: %.2f:1','Speed: %.2f MB/s  ETA: %s  Ratio: %.2f:1'),
    ('Prozess durch Benutzer abgebrochen','Process cancelled by user')
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
