Changelog
=========

## 0.1.0

* Generate valid YAML: multi-line inputs such as inline scripts, and values that need quoting, are now written correctly.
* Keep `$(variable)` references as they are, instead of rewriting them to `${{ }}` template expressions. This also
  stops shell command substitution in scripts from being mangled, and removes the 1000-character limit on inputs.
* Use the task version the release used, e.g. `AzureRmWebAppDeployment@4`, and the task's name at that version.
* Give stages and jobs valid identifiers, keeping the original names as `displayName`.
* Work out stage `dependsOn` from the release triggers, and run jobs one after another as the release did.
* Convert agentless jobs, hosted agent images, disabled tasks, conditions, continue on error, timeouts and stage
  variables.
* List everything that can't be converted (approvals, gates, secrets, variable groups, artifacts, task groups,
  Marketplace tasks and more) as TODO comments at the top of the output.
* Skip jobs and stages with no tasks instead of writing empty ones.
* Give a clear error for files that aren't a single release definition, such as `definition list` output.
* Require Ruby 3.1 or later. Drop the `hash_with_dot_access` dependency; the gem now has no runtime dependencies.

## 0.0.2

* Fix resource loading bug

## 0.0.1

* Initial release
