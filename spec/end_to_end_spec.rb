# frozen_string_literal: true

require_relative 'spec_helper'

# Runs bin/ye against each exported release definition and checks that the
# result is a pipeline ADO would accept.
IDENTIFIER = /\A[A-Za-z_][A-Za-z0-9_]*\z/

DEFINITIONS = %w[show.yml random1.yml random2.yml random3.yml].freeze

RSpec.describe 'bin/ye end to end' do
  DEFINITIONS.each do |fixture|
    context "with #{fixture}" do
      let(:result) { run_ye(fixture) }
      let(:pipeline) { YAML.safe_load(result[0]) }
      let(:stages) { pipeline.fetch('stages') }
      let(:jobs) { stages.flat_map { |stage| stage.fetch('jobs') } }

      it 'exits successfully and writes YAML that parses' do
        expect(result[2]).to be_success, result[1]
        expect(pipeline).to be_a(Hash)
      end

      it 'uses valid identifiers for stage names' do
        expect(stages.map { |stage| stage['stage'] }).to all(match(IDENTIFIER))
      end

      it 'uses valid identifiers for job names' do
        expect(jobs.map { |job| job['job'] }).to all(match(IDENTIFIER))
      end

      it 'gives every job at least one step' do
        expect(jobs.map { |job| job['steps'] }).to all(be_an(Array).and(be_any))
      end

      it 'does not emit template expressions for runtime macros' do
        expect(result[2]).to be_success, result[1]
        expect(result[0]).not_to include('${{')
      end
    end
  end

  context 'with the output of `az pipelines release definition list`' do
    it 'fails with a message pointing at `definition show`' do
      _out, err, status = run_ye('definition_list.yml')
      expect(status).not_to be_success
      expect(err).to include('definition show')
      expect(err).not_to include('NoMethodError')
    end
  end
end
