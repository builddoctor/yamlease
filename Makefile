clean:
	rm -rf azure-pipelines-tasks

spec:
	bundle exec rspec spec

task_map.txt:
	./generate_task_map.sh

gem:
	gem build yamlease.gemspec


.PHONY: clean task_map.txt spec gem