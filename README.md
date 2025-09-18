# SonicWall Cloud Backup Report

PowerShell script to query the SonicWall API and export **Cloud Backup** information for one or more devices.  

This was created in response to the [SonicWall Cloud Backup Incident](https://www.sonicwall.com/support/knowledge-base/mysonicwall-cloud-backup-file-incident/250915160910330) to help admins quickly audit their backups.

## Features

- Reads serial numbers from a text file (one per line).
- Queries the SonicWall API for each device.
- Exports the **latest backup info** for each device to CSV.
- Handles devices with **no backups** or **API errors** gracefully.
- Includes firmware version, backup file info, size, and timestamps.

## Requirements

- PowerShell 5.1+ (Windows)
- Access to [mysonicwall.com](https://www.mysonicwall.com) with valid credentials.

## Getting the Bearer Token

1. Log in to [https://www.mysonicwall.com](https://www.mysonicwall.com) in your browser.  
2. Press `F12` to open Developer Tools.  
3. Go to the **Network** tab.  
4. Click on the **Cloud Backups** tab for any device (this triggers the API call).  
5. Look for a request to `https://api.mysonicwall.com/...`  
6. Under **Headers**, copy the full value from `Authorization: Bearer ...`  
7. Use this value when running the script.

⚠️ **Note on Excel:** Serial numbers may contain leading zeros. If you open the CSV directly in Excel, Excel may strip them.  
To avoid this, import via **Data → Get Data → From Text/CSV** and set the `SerialNumber` column to **Text**.

## Usage

```powershell
# Default usage (prompts for token, uses default file paths)
# When prompted, paste the full string including the word "Bearer", e.g.:
#   Bearer abc123...
.\Get-SonicWallBackupReport.ps1

# Pass token inline
.\Get-SonicWallBackupReport.ps1 -Token "Bearer abc123..."

# Custom serials file and output path
.\Get-SonicWallBackupReport.ps1 -Token "Bearer abc123..." `
    -SerialFile "D:\Work\serials.txt" `
    -OutputFile "D:\Work\Backups.csv"
```
## Example Output

The script generates a CSV with backup details.  
Here’s a sample (with placeholder values):

```csv
SerialNumber,FirmwareVersion,FileCount,IsGoldStandard,PrefFileID,FileName,FileType,Description,CreatedOn,CreatedTimeInSec,FileSize,PinIt,GoldStandard,Comments,FirmwareAvailable,ReleaseNotesUri,BackupUsername,FirmwareBuildDatetime,LatestBackup
ABC123XYZ789,7.3.0-7012-R8150,3,FALSE,FILE123456,sonicwall-ABC123XYZ789-YYYYMMDDHHMMSS.exp.gz,automatic,Automated Backup,01-Jan-23,1234567890,442396,0,0,Automated Backup,,,"System",987654321,YES
TESTDEVICE01,,,,,,,,,,,,,,,,,NoBackup
DEVICEERROR99,,,,,,,,,,,,,,,,,Error
