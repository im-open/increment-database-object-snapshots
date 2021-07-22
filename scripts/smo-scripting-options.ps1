function Get-SmoScriptingOptions {
    $so = New-Object -TypeName "Microsoft.SqlServer.Management.Smo.ScriptingOptions"
	$so.Encoding = [System.Text.Encoding]::ASCII
	$so.IncludeIfNotExists = 0
	$so.SchemaQualify = 1
	$so.AllowSystemObjects = 0
	$so.ScriptDrops = 0
	$so.ScriptBatchTerminator = 1
	$so.Indexes = 1
	$so.AnsiFile = 1
	$so.Triggers = 1
	$so.ClusteredIndexes = 1
	$so.NonClusteredIndexes = 1
	$so.FullTextCatalogs = 1
	$so.FullTextIndexes = 1
	$so.FullTextStopLists = 1
	$so.XmlIndexes = 1
	$so.IncludeDatabaseRoleMemberships = 1
	$so.Permissions = 0
	$so.AllowSystemObjects = 0
	$so.AnsiPadding = 1
	$so.ExtendedProperties = 1
	$so.SchemaQualifyForeignKeysReferences = 1
	$so.ScriptSchema = 1
	$so.ScriptBatchTerminator = 1
	$so.IncludeHeaders = 0
	$so.DriAll = 1
	$so.ToFileOnly = 1
	$so.AppendToFile = 0
	$so.IncludeDatabaseRoleMemberships = 1
	$so.IncludeScriptingParametersHeader = 0
	$so.ScriptOwner = 1

    return $so
}