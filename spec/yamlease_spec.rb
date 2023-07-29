require_relative '../lib/yamlease'

PIPELINE_URL = "https://vsrm.dev.azure.com/builddoctor/8b6935cc-ac1a-47f3-9114-12e7e977ce0f/_apis/Release/definitions/1"

RSpec.describe ReleasePipeline do

  let(:rp) do
     ReleasePipeline.new("show.yml")
  end

  it "lets you specify a filename on instantiation" do
    expect(rp.url).to eq(PIPELINE_URL)
  end
  it "has a URL" do
    expect(rp.url).to eq(PIPELINE_URL)
  end

  it "has multiple stages" do
    expect(rp.stages[1][:name]).to eq("Stage 2")
  end

  it "will list all the tasks in a stage" do
    expect(rp.stages[1][:tasks][0]["name"]).to eq("Deploy Azure App Service")
  end
end