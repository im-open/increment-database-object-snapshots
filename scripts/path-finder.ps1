function Get-FolderForDbObjectType {
    [CmdletBinding()]
	param (
		[string]$typeName
	)

    $TypeFolder = 
		Switch ($typeName) {
			"StoredProcedures" { "Stored Procedures" }
			"Triggers" { "Database Triggers" }
			"FullTextCatalogs" { "Storage/Full Text Catalogs" }
			"Roles" { "Security/Roles" }
			"Schemas" { "Security/Schemas" }
			"Users" { "Security/Users" }
			"XmlSchemaCollections" { "Types/XML Schema Collections" }
			"UserDefinedFunctions" { "Functions" }
			"UserDefinedTableTypes" { "Types/User-defined Data Types" }
			default { $typeName }
		}
    return $TypeFolder
}