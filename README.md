YAML from relEASE definition
============================

This project allows you to generate a YAML pipeline from an existing ADO "release" pipeline. The YAML pipeline is
generated from the "release" pipeline definition, not from the "release" pipeline run.

## Why?

Release Pipelines, with their graphical editor, were a great idea in the previous decade.  Now that release isn't 
solely an ops team concern (and some shops no longer have an ops team), it makes sense to move towards YAML pipelines:

* Microsoft have made it clear that [YAML pipelines are the future](https://learn.microsoft.com/en-us/azure/devops/pipelines/get-started/pipelines-get-started?view=azure-devops#feature-availability)
* YAML pipelines are easier to version control
* YAML pipelines are easier to share
* You're probably building code in YAML pipelines already

## Usage

### Prerequisites
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) with the ADO extension
* Ruby 3.0 distribution
* this repo cloned locally

### Steps

Install Yamlease:

```bash
gem install yamlease
```

Extract your release definition from ADO:

```bash

az pipelines release definition list --organization https://dev.azure.com/$ORG --project "$PROJECT" 
az pipelines release definition show --organization https://dev.azure.com/$ORG --project "$PROJECT"  --id $ID| tee my_release.yml
```

Run Yamlease:

```bash 
ye  my_release.yml > my_pipeline.yml
``` 
Paste your pipeline into ADO and tweak as necessary.  You'll want to add in a pipeline to build the application that you're releasing in the first stage.
