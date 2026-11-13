spec:
	bundle exec rspec spec

clean:
	rm -rf azure-pipelines-tasks *.gem

lib/task_map.txt:
	./generate_task_map.sh

gem:
	gem build yamlease.gemspec

cli:
	./bin/ye spec/fixtures/show.yml

.PHONY: clean lib/task_map.txt spec gem cli lint

lint:
	bundle exec rubocop
