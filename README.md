# increment-database-object-snapshots

A GitHub Action that creates or updates snapshot files for database objects. The snapshot files are `.sql` files that represent the shape of the object at the point in time the snapshot was taken.

## Index <!-- omit in toc -->

- [increment-database-object-snapshots](#increment-database-object-snapshots)
  - [Inputs](#inputs)
  - [Usage Examples](#usage-examples)
  - [Contributing](#contributing)
    - [Incrementing the Version](#incrementing-the-version)
    - [Source Code Changes](#source-code-changes)
    - [Updating the README.md](#updating-the-readmemd)
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
|------------------------|-------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
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

## Usage Examples

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

          echo "json=$objectsAsJson" >> $GITHUB_OUTPUT

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

When creating PRs, please review the following guidelines:

- [ ] The action code does not contain sensitive information.
- [ ] At least one of the commit messages contains the appropriate `+semver:` keywords listed under [Incrementing the Version] for major and minor increments.
- [ ] The README.md has been updated with the latest version of the action.  See [Updating the README.md] for details.

### Incrementing the Version

This repo uses [git-version-lite] in its workflows to examine commit messages to determine whether to perform a major, minor or patch increment on merge if [source code] changes have been made.  The following table provides the fragment that should be included in a commit message to active different increment strategies.

| Increment Type | Commit Message Fragment                     |
|----------------|---------------------------------------------|
| major          | +semver:breaking                            |
| major          | +semver:major                               |
| minor          | +semver:feature                             |
| minor          | +semver:minor                               |
| patch          | *default increment type, no comment needed* |

### Source Code Changes

The files and directories that are considered source code are listed in the `files-with-code` and `dirs-with-code` arguments in both the [build-and-review-pr] and [increment-version-on-merge] workflows.  

If a PR contains source code changes, the README.md should be updated with the latest action version.  The [build-and-review-pr] workflow will ensure these steps are performed when they are required.  The workflow will provide instructions for completing these steps if the PR Author does not initially complete them.

If a PR consists solely of non-source code changes like changes to the `README.md` or workflows under `./.github/workflows`, version updates do not need to be performed.

### Updating the README.md

If changes are made to the action's [source code], the [usage examples] section of this file should be updated with the next version of the action.  Each instance of this action should be updated.  This helps users know what the latest tag is without having to navigate to the Tags page of the repository.  See [Incrementing the Version] for details on how to determine what the next version will be or consult the first workflow run for the PR which will also calculate the next version.

## Code of Conduct

This project has adopted the [im-open's Code of Conduct](https://github.com/im-open/.github/blob/main/CODE_OF_CONDUCT.md).

## License

Copyright &copy; 2023, Extend Health, LLC. Code released under the [MIT license](LICENSE).

<!-- Links -->
[Incrementing the Version]: #incrementing-the-version
[Updating the README.md]: #updating-the-readmemd
[source code]: #source-code-changes
[usage examples]: #usage-examples
[build-and-review-pr]: ./.github/workflows/build-and-review-pr.yml
[increment-version-on-merge]: ./.github/workflows/increment-version-on-merge.yml
[git-version-lite]: https://github.com/im-open/git-version-lite
