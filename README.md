YAML from relEASE definition
============================

Yamlease generates a YAML pipeline from an existing Azure DevOps (ADO) classic "release" pipeline. It works from the
release *definition* (the pipeline you edit), not from a release run.

## Why?

Release Pipelines, with their graphical editor, were a great idea in the previous decade.  Now that release isn't 
solely an ops team concern (and some shops no longer have an ops team), it makes sense to move towards YAML pipelines:

* Microsoft have made it clear that [YAML pipelines are the future](https://learn.microsoft.com/en-us/azure/devops/pipelines/get-started/pipelines-get-started?view=azure-devops#feature-availability)
* YAML pipelines are easier to version control
* YAML pipelines are easier to share
* You're probably building code in YAML pipelines already

## Usage

### Prerequisites

* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) with the `azure-devops` extension
* Ruby 3.1 or later

### Steps

Install Yamlease:

```bash
gem install yamlease
```

Find your release definition's ID and export it from ADO:

```bash
az pipelines release definition list --organization https://dev.azure.com/$ORG --project "$PROJECT" --output table
az pipelines release definition show --organization https://dev.azure.com/$ORG --project "$PROJECT" --id $ID > my_release.json
```

Run Yamlease:

```bash
ye my_release.json > azure-pipelines.yml
```

Then work through the `# TODO` comments at the top of the generated file, add your build steps to the `BuildThings`
stage, and commit the pipeline to your repository.

## What gets converted

| Classic release                                       | YAML pipeline                                              |
|-------------------------------------------------------|------------------------------------------------------------|
| Environments (stages)                                 | Stages, with `dependsOn` worked out from the stage triggers |
| Deployment phases                                     | Jobs, run one after another as they were in the release     |
| Agentless phases                                      | Jobs with `pool: server`                                   |
| Microsoft-hosted agent images                         | Job `pool: vmImage`                                        |
| Built-in tasks, with their inputs                     | Steps, using the task version the release used             |
| Disabled tasks, conditions, continue on error, timeouts | The matching step and job settings                       |
| Pipeline and stage variables                          | `variables`                                                |

`$(variable)` references are kept as they are, because YAML pipelines support the same syntax.

## What you need to finish by hand

Yamlease can't convert everything, either because the export doesn't contain enough detail or because YAML pipelines
do it differently. Each of these is listed as a `# TODO` at the top of the output (and on stderr when you redirect
the output to a file):

* **Approvals and gates:** add them as checks on an [environment](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/environments)
  and turn the job into a deployment job.
* **Secret variables:** they aren't in the export. Add them as secret pipeline variables, or from a variable group or
  Key Vault.
* **Variable groups:** the export only has their IDs. Add each one as `- group: <name>`.
* **Artifacts:** add them under `resources` and download them in the jobs that use them.
* **Self-hosted agent pools:** the export only has the queue ID. Set `pool: name:`.
* **Deployment groups:** use a deployment job that targets an environment with virtual machine resources.
* **Task groups:** convert them to step templates.
* **Marketplace tasks:** they appear as `task: Unknown`; replace that with the task's YAML name.
* **Manually deployed stages, artifact filters and triggers on statuses other than "succeeded".**

The generated pipeline triggers on `main` and uses an `ubuntu-latest` pool by default; change both to suit.

## Development

```bash
bundle install
make spec   # run the tests
make lint   # run RuboCop
make cli    # convert the sample definition in spec/fixtures
```

`lib/task_map.txt` maps task IDs to task names. Regenerate it from
[microsoft/azure-pipelines-tasks](https://github.com/microsoft/azure-pipelines-tasks) with `make lib/task_map.txt`
(needs the GitHub CLI and `jq`).
