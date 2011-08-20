require 'spec_helper'

describe Resque::Plugins::Director::Lifecycle do
  subject { Resque::Plugins::Director::Lifecycle }
  
  before do
    Resque::Plugins::Director::Config.queue = "test"
  end
  
  describe "#lifecycle" do
    it "should add the jobs timestamp at the end of the job args" do
      now = Time.now
      Time.stub(:now => now)
      time_stamp = now.utc.to_i
      
      Resque.enqueue(TestJob, "arg1")
      Resque.pop("test").should == {"args"=>["arg1", {'resdirecttime' => time_stamp}], "class"=>"TestJob"}
    end
  end
end