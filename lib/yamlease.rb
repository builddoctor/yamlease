# frozen_string_literal: true

# Converts an exported Azure DevOps classic release definition into a YAML
# pipeline. The export is parsed into plain hashes, mapped onto a Hash with the
# shape of a YAML pipeline, and serialised with Psych, which handles quoting,
# multi-line values and indentation.
#
# Anything that cannot be converted is recorded as a warning, which ends up as
# a TODO comment at the top of the generated pipeline.
module Yamlease
end

require_relative 'yamlease/version'
require_relative 'yamlease/support'
require_relative 'yamlease/task_definition'
require_relative 'yamlease/task'
require_relative 'yamlease/job'
require_relative 'yamlease/stage'
require_relative 'yamlease/release_pipeline'
