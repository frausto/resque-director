require 'spec_helper'

class TestJob
  extend Resque::Plugins::Director
  @queue = :test

  def self.perform
  end
end

describe Resque::Plugins::Director do
  it "should follow the resque plugin convention" do
    Resque::Plugin.lint(Resque::Plugins::Director)
  end
  
  describe "#after_enqueue_start_workers" do
    
    it "should not scale up workers if the minumum number or greater are already running" do
      Resque.stub_chain(:workers, :size).and_return(1)
      Resque::Plugins::Director::Scaler.should_not_receive(:scale_up)
      Resque.enqueue(TestJob)
    end
    
    it "should scale up the minimum number of workers if non are running" do
      TestJob.direct :min_workers => 2
      Resque::Plugins::Director::Scaler.should_receive(:scale_up).with(:test, 2)
      Resque.enqueue(TestJob)
    end
    
    it "should scale up the minimum number of workers if less than the minimum are running" do
      TestJob.direct :min_workers => 2
      Resque.stub_chain(:workers, :size).and_return(1)
      Resque::Plugins::Director::Scaler.should_receive(:scale_up).with(:test, 1)
      Resque.enqueue(TestJob)
    end
  end
end
