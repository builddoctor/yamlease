#!/bin/bash
gh repo clone microsoft/azure-pipelines-tasks -- --depth 1

cd azure-pipelines-tasks/Tasks || exit
find . -name task.json -exec dirname {} \; | while read -r task; do
  id=$(jq -r .id < "$task/task.json")
  pretty_task=$(echo $task | sed 's/\.\///g')
  echo "${id} ${pretty_task}"
done > ../../task_map.txt