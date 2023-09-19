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
    expect(rp.stages[1].name).to eq("Stage 2")
  end

  it "will list all the jobs in a stage" do
    expect(rp.stages.first.jobs).to be_a(Array)
  end

  it "will list all the tasks in a job" do
    expect(rp.stages[1].jobs.first.tasks.first.name).to eq("Deploy Azure App Service")
  end

  it "will get the task IDs in a job" do
    expect(rp.stages[1].jobs.first.tasks.first.taskId).to eq("497d490f-eea7-4f2b-ab94-48d9c1acdcb1")
  end

  it "should know how to parse a task" do
    expect(rp.get_task_by_id("D9BAFED4-0B18-4F58-968D-86655B4D2CE9")).to eq("CmdLineV2")
  end

  it "should return a good default when you fail to find a task" do
    expect(rp.get_task_by_id("D9BAFED4-0B18-4F58-968D-HURRSDUDF")).to eq("Unknown")
  end
end