require 'spec_helper'

describe Resque::Plugins::Director::PushPop do
  subject { Resque::Plugins::Director::PushPop }
  
  before do
    Resque::Plugins::Director::Config.queue = "test"
    @now = Time.now
    Time.stub(:now => @now)
    @timestamp = @now.utc.to_i
  end
  
  describe "#push" do
    it "should add the start timestamp to the end of the job" do
      Resque.enqueue(TestJob, "arg1")
      Resque.redis.lindex("queue:test",0).should =~ /^\{.*\"created_at\":#{@timestamp}/
    end
  end
  
  describe "#pop" do
    it "should direct workers using the timestamp" do
      Resque.enqueue(TestJob, "arg1")
      expected_time = Time.at(@timestamp).utc
      TestJob.should_receive(:after_pop_direct_workers).with(expected_time)
      Resque.pop("test").should == {"args"=>["arg1"], "class"=>"TestJob", "created_at"=>@timestamp}
    end
    
    it "should direct workers with current time if no start time" do
      Resque.should_receive(:original_pop).and_return({'args' => [], 'class' => 'TestJob'})
      TestJob.should_receive(:after_pop_direct_workers).with(@now)
      Resque.pop("test").should == {"args"=>[], "class"=>"TestJob"}
    end
    
    it "should not direct workers if the job is not directed" do
      Resque.enqueue(NonDirectedTestJob, "arg1")
      NonDirectedTestJob.should_not_receive(:after_pop_direct_workers)
      Resque.pop("non_directed").should include({"args"=>["arg1"], "class"=>"NonDirectedTestJob"})
    end
    
    it "should return the job properly if an exception is thrown in the direction logic" do
      Resque.enqueue(TestJob, "arg1")
      TestJob.should_receive(:after_pop_direct_workers).and_throw(:Exception)
      Resque.pop("test").should include({"args"=>["arg1"], "class"=>"TestJob"})
    end
  end
end