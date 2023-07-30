clean:
	rm -rf azure-pipelines-tasks


task_map.txt:
	./generate_task_map.sh


.PHONY: clean task_map.txt