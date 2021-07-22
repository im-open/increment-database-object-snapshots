function Get-AllTypes {
    return @(
		"ApplicationRoles",
		"Assemblies",
		"Defaults",
		"ExtendedProperties",
		"ExtendedStoredProcedures",
		"FullTextCatalogs",
		"FullTextStopLists",
		"PartitionFunctions",
		"PartitionSchemes",
		"Roles",
		"Rules",
		"Schemas",
		"SearchPropertyLists",
		"Sequences",
		"StoredProcedures",
		"Synonyms",
		"Tables",
		"Triggers",
		"UserDefinedAggregates",
		"UserDefinedDataTypes",
		"UserDefinedFunctions",
		"UserDefinedTableTypes",
		"UserDefinedTypes",
		"Views",
		"XmlSchemaCollections"
	)
}

function Get-IncrementalTypes {
    return @(
		"Sequences",
		"StoredProcedures",
		"Synonyms",
		"Tables",
		"Views",
		"UserDefinedFunctions"
	)
}

function Get-ExcludedSchemas {
	return @("sys", "Information_Schema")
}

function Get-ExcludedObjects {
    return @(
		"db_accessadmin"
		"db_backupoperator"
		"db_datareader"
		"db_datawriter"
		"db_ddladmin"
		"db_denydatareader"
		"db_denydatawriter"
		"db_owner"
		"db_securityadmin"
		"dbo"
		"guest"
		"sys"
		"INFORMATION_SCHEMA"
	)
}