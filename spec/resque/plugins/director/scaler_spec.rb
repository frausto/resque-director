require 'spec_helper'

describe Resque::Plugins::Director::Scaler do
  subject { Resque::Plugins::Director::Scaler }
  
  describe "#scale_up" do
    it "should start a worker on a specific queue" do
      subject.scale_up(:test, 1)
      Resque.workers.size.should == 1
      Resque.workers.first.queues.should == ["test"]
    end
  end
  
end