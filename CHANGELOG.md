# Changelog

All notable changes to this project are documented in this file.

## [v2.0.3] – 2026-09-30

- improved update notifications.
- more translations

 
## [v2.0.2] – 2026-09-29

- Fixed missing update notifications.
- Fixed an issue where the wrong application was restarted after an update.


## [v2.0.0] – 2026-09-28

* changed backup concept from individual partitions to complete drives
* added complete drive backup and restore
* added separate MBR backup and restore
* added complete boot partition backup and restore
* added system partition backup and restore
* added Base Image and Differential Image support
* Differential Images are created directly from the Base Image
* added automatic image file naming
* added automatic detection of boot and system partitions
* improved restore workflow for complete drives
* added restore selection for MBR, boot and system
* added safety confirmation showing the selected target drive and restore components
* improved handling of mounted partitions during restore
* added automatic creation of the destination folder
* simplified CLI interface
* CLI now uses only source drive and destination folder
* CLI usage: `sudo piext <drive> <destination-folder>`
* CLI automatically starts the backup and exits when finished
* added CLI exit codes (`0` = success, `1` = error)
* GUI and CLI now explicitly require root privileges
* removed obsolete CLI options and parameters
* improved user interface and backup/restore workflow
* various bug fixes and improvements

## [v1.2.1] – 2026-09-26

* added CLI interface
* fixed automatic update

## [v1.0.0] – 2026-09-24

* Initial public release.

