clean:
	rm -rf azure-pipelines-tasks

spec:
	bundle exec rspec spec

task_map.txt:
	./generate_task_map.sh


.PHONY: clean task_map.txt spec