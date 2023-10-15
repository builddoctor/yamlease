spec:
	bundle exec rspec spec

clean:
	rm -rf azure-pipelines-tasks *.gem

task_map.txt:
	./generate_task_map.sh

gem:
	gem build yamlease.gemspec

cli:
	./bin/ye show.yml

pscli:
	pwsh cli.ps1

.PHONY: clean task_map.txt spec gem cli pscli
