param (
    [string]$dbName, # name of the database
    [string]$instanceName, # the name of the SQL Server instance
    [string]$snapshotPath,
    [array]$excludedDbObjects = @(),
    [string]$objectsToIncrement = "[]"
)

. $PSScriptRoot\snapshot-types.ps1
. $PSScriptRoot\smo-scripting-options.ps1
. $PSScriptRoot\path-finder.ps1
. $PSScriptRoot\synonyms.ps1
. $PSScriptRoot\exception-utilities.ps1

Import-Module SqlServer -MinimumVersion 21.0

$ServerInstance = New-Object -TypeName "Microsoft.SqlServer.Management.Smo.Server" -ArgumentList $instanceName
$AllIncludedTypes = Get-AllTypes
$IncrementalTypes = Get-IncrementalTypes
$ExcludedSchemas = Get-ExcludedSchemas
$ExcludedObjects = Get-ExcludedObjects + $excludedDbObjects

# $ChangedObjects = Get-ChangedObjects -dbName $dbName -instanceName $instanceName
$ScriptingOptions = Get-SmoScriptingOptions
$Db = $serverInstance.Databases[$dbName]

Write-Host "Creating all snapshot files."
foreach ($Type in $AllIncludedTypes) {
    $TypeFolder = Get-FolderForDbObjectType -typeName $Type
    $TypeSnapshotPath = Join-Path $snapshotPath $TypeFolder

    # create folders for type if we don't have one already
    if (!(Test-Path $TypeSnapshotPath)) {
        New-Item -ItemType Directory $TypeSnapshotPath | Out-Null
    }

    if ($Type -eq "Synonyms") {
        $SynonymScripts = Get-SynonymScripts -dbName $dbName -instanceName $instanceName
    }

    if ($IncrementalTypes -contains $Type) {
        $TypeObjects = $objectsToIncrement | ConvertFrom-Json | Where-Object { $_.objectType -eq $Type } | Sort-Object -Property operationType
        $CountOfObjectsByType = @($TypeObjects).Count

        Write-Host "Incrementing $Type Snapshots of changed objects. ($CountOfObjectsByType)"
        foreach ($TypeObject in $TypeObjects) {
            $ObjectName = $TypeObject.schemaName + "." + $TypeObject.objectName
            $SnapshotFilePath = Join-Path $TypeSnapshotPath "$ObjectName.sql"

            # Remove the old file(s) before generating new ones
            if (Test-Path $SnapshotFilePath) {
                Remove-Item $SnapshotFilePath
            }

            if ($ExcludedObjects -contains $ObjectName -or $TypeObject.operationType -eq "D") {
                continue
            }

            try {
                if ($Type -eq "Synonyms") {
                    $Synonym = $SynonymScripts | Where-Object { $_.objectName -eq $ObjectName }
                    Set-Content -Path $SnapshotFilePath -Value $Synonym.synonymScript
                }
                else {
                    $ScriptingOptions.FileName = $SnapshotFilePath
                    $Objects = $Db.$Type | Where-Object { $_.Name -eq $TypeObject.objectName -and $_.Schema -eq $TypeObject.schemaName }
                    $Objects.Script($ScriptingOptions)
                }
            }
            catch {
                Write-Status "Error creating snapshot for $ObjectName `r`n $(Get-ExceptionDetails $_.Exception)"
                throw
            }
        }
    }
    else {
        Write-Host "Generating $Type Snapshots."

        # Remove the old file(s) before generating new ones 
        foreach ($Item in Get-ChildItem $TypeSnapshotPath) {
            Remove-Item $Item.FullName -Recurse -Force
        }

        foreach ($Objects in $Db.$Type) {
            $ObjectName = "$Objects".replace("[", "").replace("]", "").Replace("\\", "_")
            
            if ($ExcludedSchemas -contains $Objects.Schema -or $ExcludedObjects -contains $ObjectName) {
                continue
            }

            $SnapshotFilePath = Join-Path $TypeSnapshotPath "$ObjectName.sql"
            $ScriptingOptions.FileName = $SnapshotFilePath

            try {
                $Objects.Script($ScriptingOptions)
            }
            catch {
                Write-Status "Error creating snapshot for $ObjectName `r`n $(Get-ExceptionDetails $_.Exception)"
                throw
            }
        }
    }
}