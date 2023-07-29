require_relative '../lib/yamlease'

PIPELINE_URL = "https://vsrm.dev.azure.com/builddoctor/8b6935cc-ac1a-47f3-9114-12e7e977ce0f/_apis/Release/definitions/1"

RSpec.describe ReleasePipeline do
  it "has a URL" do
    rp = ReleasePipeline.new

    expect(rp.url).to eq(PIPELINE_URL)
  end

  it "has multiple stages" do
    rp = ReleasePipeline.new

    expect(rp.stages[1][:name]).to eq("Stage 2")
  end
end