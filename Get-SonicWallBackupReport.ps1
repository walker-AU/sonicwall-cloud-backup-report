<#
.SYNOPSIS
    Pulls the latest SonicWall cloud backup info for a list of devices and exports results to CSV.

.DESCRIPTION
    - Reads serial numbers from a text file (one per line).
    - Calls the SonicWall API to get backup preferences.
    - Filters to include only the latest backup for each device.
    - If no latest backup is found, writes a row with "NoBackup".
    - If the API call fails, writes a row with "Error".
    - Exports all results to CSV.

.NOTES
    How to get the Bearer token:
    1. Log in to https://www.mysonicwall.com in your browser.
    2. Press F12 to open Developer Tools.
    3. Go to the "Network" tab.
    4. In the portal, click on the "Cloud Backups" tab for any device.
       (this triggers the API request that includes your token).
    5. Look for a request to https://api.mysonicwall.com/...
    6. Under the "Headers" tab, copy the full value from the "Authorization: Bearer ..." header.
    7. When running this script, provide it via the -Token parameter or paste when prompted.
       Be sure to include the word "Bearer" at the start, for example:
           Bearer abc123...

    IMPORTANT:
    - Serial numbers may include leading zeros. If you open the CSV directly in Excel,
      Excel may drop them (e.g. "0012345" → "12345").
    - To preserve the serials, import the CSV into Excel using:
      Data > Get Data > From Text/CSV
      and set the "SerialNumber" column to Text.
    - Alternatively, open the CSV in Notepad or another text editor to confirm values.

..EXAMPLE
    .\Get-SonicWallBackups.ps1
    Prompts for a Bearer token. When prompted, paste the full string including the word "Bearer",
    for example: 
        Bearer abc123...
    Uses the default serials file (C:\Temp\serials.txt) and outputs results to 
    C:\Temp\SonicWall_LatestBackups.csv.

.EXAMPLE
    .\Get-SonicWallBackupReport.ps1 -Token "Bearer abc123..."
    Passes the Bearer token inline instead of being prompted. 
    Uses the default serials and output paths.

.EXAMPLE
    .\Get-SonicWallBackupReport.ps1 -Token "Bearer abc123..." `
        -SerialFile "D:\Work\MySerials.txt" `
        -OutputFile "D:\Work\Backups.csv"
    Runs with a custom serials input file and custom output path.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$Token,

    [string]$SerialFile = "C:\Temp\serials.txt",
    [string]$OutputFile = "C:\Temp\SonicWall_LatestBackups.csv"
)

# Load serial numbers
$serials = Get-Content -Path $SerialFile

# Store results
$results = @()

foreach ($serial in $serials) {
    Write-Host "Fetching serial: $serial ..."

    try {
        $url = "https://api.mysonicwall.com/api/product/backupprefs?serial=$serial"
        $response = Invoke-RestMethod -Uri $url -Headers @{
            "Accept"        = "application/json"
            "Authorization" = $Token
        } -ErrorAction Stop

        $content = $response.content

        $foundLatest = $false

        foreach ($fw in $content.prefFileVerList) {
            foreach ($pf in $fw.prefFileList) {
                if ($pf.latestBackUp -eq "YES") {
                    $results += [PSCustomObject]@{
                        SerialNumber          = $content.serialNumber
                        FirmwareVersion       = $fw.firmwareVersion
                        FileCount             = $fw.pFileCnt
                        IsGoldStandard        = $fw.isGoldStandard
                        PrefFileID            = $pf.prefFileID
                        FileName              = $pf.fileName
                        FileType              = $pf.fileType
                        Description           = $pf.description
                        CreatedOn             = $pf.createdOn
                        CreatedTimeInSec      = $pf.createdTimeInSec
                        FileSize              = $pf.fileSize
                        PinIt                 = $pf.pinIt
                        GoldStandard          = $pf.goldStandard
                        Comments              = $pf.comments
                        FirmwareAvailable     = $pf.firmwareAvailable
                        ReleaseNotesUri       = $pf.releaseNotesUri
                        BackupUsername        = $pf.backupUsername
                        FirmwareBuildDatetime = $pf.firmwareBuildDatetime
                        LatestBackup          = $pf.latestBackUp
                    }
                    $foundLatest = $true
                }
            }
        }

        if (-not $foundLatest) {
            $results += [PSCustomObject]@{
                SerialNumber          = $serial
                FirmwareVersion       = ""
                FileCount             = ""
                IsGoldStandard        = ""
                PrefFileID            = ""
                FileName              = ""
                FileType              = ""
                Description           = ""
                CreatedOn             = ""
                CreatedTimeInSec      = ""
                FileSize              = ""
                PinIt                 = ""
                GoldStandard          = ""
                Comments              = ""
                FirmwareAvailable     = ""
                ReleaseNotesUri       = ""
                BackupUsername        = ""
                FirmwareBuildDatetime = ""
                LatestBackup          = "NoBackup"
            }
        }

        Write-Host "   Success"
    }
    catch {
        Write-Host "   Failed for $serial. Error: $($_.Exception.Message)"

        # Still add a row to indicate failure
        $results += [PSCustomObject]@{
            SerialNumber          = $serial
            FirmwareVersion       = ""
            FileCount             = ""
            IsGoldStandard        = ""
            PrefFileID            = ""
            FileName              = ""
            FileType              = ""
            Description           = ""
            CreatedOn             = ""
            CreatedTimeInSec      = ""
            FileSize              = ""
            PinIt                 = ""
            GoldStandard          = ""
            Comments              = ""
            FirmwareAvailable     = ""
            ReleaseNotesUri       = ""
            BackupUsername        = ""
            FirmwareBuildDatetime = ""
            LatestBackup          = "Error"
        }
    }
}

# Export to CSV
$results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Force
Write-Host "`nExport complete: $OutputFile"
