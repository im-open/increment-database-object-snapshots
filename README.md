# increment-database-object-snapshots

A GitHub Action that creates or updates snapshot files for database objects. The snapshot files are `.sql` files that represent the shape of the object at the point in time the snapshot was taken.

## Index

- [Inputs](#inputs)
- [Example](#example)
- [Contributing](#contributing)
  - [Incrementing the Version](#incrementing-the-version)
- [Code of Conduct](#code-of-conduct)
- [License](#license)

**Example snapshot**

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SomeTable](
 [id] [int] NOT NULL,
 [anotherProperty] [int] NOT NULL,
 CONSTRAINT [PK_SomeTable] PRIMARY KEY CLUSTERED 
(
 [id] ASC,
 [anotherProperty] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER AUTHORIZATION ON [dbo].[SomeTable] TO  SCHEMA OWNER 
GO
CREATE NONCLUSTERED INDEX [NCIX_SomeTable_anotherProperty] ON [dbo].[SomeTable]
(
 [anotherProperty] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
```

## Inputs

| Parameter              | Is Required | Description                                                                                                                                     |
| ---------------------- | ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `db-name`              | true        | The name of the database to get the snapshots from.                                                                                             |
| `instance-name`        | true        | The name of the database server instance. Most often this will follow the format `<server name>,<port>`.                                        |
| `snapshot-path`        | true        | The path to where the snapshots will be outputted.                                                                                              |
| `excluded-db-objects`  | false       | A comma separated list of db object names to exclude from the snapshots.                                                                        |
| `objects-to-increment` | false       | A json string containing the list of database objects to take snapshots of. See below for the shape of the objects that should be in the array. |

**objects-to-increment shape**

```json
[{"objectName":"SomeTable","schemaName":"dbo","operationType":"I","objectType":"Tables"},{"objectName":"AnotherTable","schemaName":"dbo","operationType":"I","objectType":"Tables"}]
```

- `objectName`: The name of the object. E.g. table name, view name, etc.
- `schemaName`: The name of the schema. E.g. dbo, MyCustomSchema etc.
- `objectType`: The type of object. This should be one of `Tables`, `Views`, `StoredProcedures`, `Sequences`, `UserDefinedFunctions`, or `Synonyms`.
- `operationType`: The operation that was performed on the object. This needs to be one of `U` (Updated), `I` (Initialized/Newly Created), or `D` (Deleted).

## Example

```yml
jobs:
  job1:
    runs-on: [self-hosted]
    steps:
      - uses: actions/checkout@v3

      - name: Install Flyway
        uses: im-open/setup-flyway@v1
        with:
          version: 7.2.0

      # Build the database so it can be used to create snapshots from
      - name: Build Database
        uses: im-open/build-database-ci-action@v3
        with:
          db-server-name: localhost
          db-name: LocalDB
          drop-db-after-build: false

      # Get the list of db objects that have changed from a view.
      # Because the sql query returns some unnecessary information, map the results to trimmed down objects before converting them to json.
      - name: Get db objects that have changed
        id: changed-objects
        shell: pwsh
        run: |
          Import-Module SqlServer -MinimumVersion 21.0
          $changedObjectsQuery = 
            "SELECT
                schemaName,
                objectName,
                objectType,
                operationType
              FROM DBA.V_ChangedObjectsForSnapshot"

          $changedObjects = Invoke-Sqlcmd -ServerInstance $instanceName -Database $dbName -Query $changedObjectsQuery
          $mappedObjects = $changedObjects | foreach-object { @{ schemaName=$_.schemaName, objectName=$_.objectName, objectType=$_.objectType, operationType=$_.operationType } }
          $objectsAsJson = $mappedObjects | ConvertTo-Json -Compress

          echo "::set-output name=json::$objectsAsJson"

      - name: Increment snapshots
        # You may also reference the major or major.minor version
        uses: im-open/increment-database-object-snapshots@v1.0.4
        with:
          db-name: LocalDB
          instance-name: localhost,1433
          snapshot-path: ./snapshots
          objects-to-increment: "${{ steps.changed-objects.outputs.json }}"
```

## Contributing

When creating new PRs please ensure:

1. For major or minor changes, at least one of the commit messages contains the appropriate `+semver:` keywords listed under [Incrementing the Version](#incrementing-the-version).
1. The action code does not contain sensitive information.

When a pull request is created and there are changes to code-specific files and folders, the `auto-update-readme` workflow will run.  The workflow will update the action-examples in the README.md if they have not been updated manually by the PR author. The following files and folders contain action code and will trigger the automatic updates:

- `action.yml`
- `scripts/**`

There may be some instances where the bot does not have permission to push changes back to the branch though so this step should be done manually for those branches. See [Incrementing the Version](#incrementing-the-version) for more details.

### Incrementing the Version

The `auto-update-readme` and PR merge workflows will use the strategies below to determine what the next version will be.  If the `auto-update-readme` workflow was not able to automatically update the README.md action-examples with the next version, the README.md should be updated manually as part of the PR using that calculated version.

This action uses [git-version-lite] to examine commit messages to determine whether to perform a major, minor or patch increment on merge.  The following table provides the fragment that should be included in a commit message to active different increment strategies.
| Increment Type | Commit Message Fragment                     |
| -------------- | ------------------------------------------- |
| major          | +semver:breaking                            |
| major          | +semver:major                               |
| minor          | +semver:feature                             |
| minor          | +semver:minor                               |
| patch          | *default increment type, no comment needed* |

## Code of Conduct

This project has adopted the [im-open's Code of Conduct](https://github.com/im-open/.github/blob/master/CODE_OF_CONDUCT.md).

## License

Copyright &copy; 2021, Extend Health, LLC. Code released under the [MIT license](LICENSE).

[git-version-lite]: https://github.com/im-open/git-version-lite
