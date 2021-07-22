function Get-SynonymScripts {
	[CmdletBinding()]
	param (
		[string]$dbName, # name of the database
		[string]$instanceName # the name of the SQL Server instance. Should be the <server name>,<port>
	)

	#get changed objects
	$connectionString = "Server=$instanceName;Database=$dbName;Integrated Security=True;"
	$connection = New-Object System.Data.SqlClient.SqlConnection
	$connection.ConnectionString = $connectionString
	$connection.Open()

	$synonymScriptsQuery = 
	"SELECT
			CONCAT(
				SCHEMA_NAME(synonyms.schema_id), '.',
				sys.synonyms.name) AS objectName,
			CONCAT
			(
				'CREATE SYNONYM [',
				SCHEMA_NAME(synonyms.schema_id), '].[', synonyms.name, ']',
				' FOR ',
				synonyms.base_object_name, '`n','GO'
			) AS synonymScript
		FROM sys.synonyms;"
		
	$command = $connection.CreateCommand()
	$command.CommandText = $synonymScriptsQuery

	$sqlAdapter = new-object System.Data.SqlClient.SqlDataAdapter 
	$sqlAdapter.SelectCommand = $command
	$dataSet = new-object System.Data.Dataset
	$sqlAdapter.Fill($dataSet) 

	$data = $dataSet.Tables[0]

	$connection.Close()
	return $data
}