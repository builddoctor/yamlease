#!/bin/bash
# Regenerates lib/task_map.txt (task ID and directory name for every built-in
# task) from a shallow clone of microsoft/azure-pipelines-tasks.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")" && pwd)
cd "$repo_root"
[ -d azure-pipelines-tasks ] || gh repo clone microsoft/azure-pipelines-tasks -- --depth 1

find azure-pipelines-tasks/Tasks -name task.json -maxdepth 2 | sort | while read -r task_json; do
  id=$(jq -r .id < "$task_json")
  echo "${id} $(basename "$(dirname "$task_json")")"
done > lib/task_map.txt
