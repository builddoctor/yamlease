YAML FROM RELEASE DEFINITION
============================
```bash

az pipelines release definition list --organization https://dev.azure.com/builddoctor --project "test must go"
az pipeines release definition show --organization https://dev.azure.com/builddoctor --project "test must go"  --id 1| tee show.yml
```