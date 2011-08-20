require 'spec_helper'

class TestNonDirectedJob
  @queue = :non_direct
  def self.perform
  end
end

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
    
    it "should not add job timestamps to non directed jobs" do
      Resque.enqueue(TestNonDirectedJob, "arg1")
      Resque.pop("non_direct").should == {"args"=>["arg1"], "class"=>"TestNonDirectedJob"}
    end
    
    it "should not add job timestamps that throw exceptions to direction logic" do
      TestNonDirectedJob.stub(:ancestors).and_throw(:Exception)
      Resque.enqueue(TestNonDirectedJob, "arg1")
      
      Resque.pop("non_direct").should == {"args"=>["arg1"], "class"=>"TestNonDirectedJob"}
    end
  end
end