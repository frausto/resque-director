require 'spec_helper'

describe Resque::Plugins::Director::Scaler do
  subject { Resque::Plugins::Director::Scaler }
  
  describe "#scale_up" do
    before do
      Resque::Plugins::Director::Config.queue = :test
    end
    
    it "should start a worker on a specific queue" do
      subject.should_receive(:system).with("QUEUE=test rake resque:work &")
      subject.scale_up
    end
    
    it "should start the specified number of workers on a specific queue" do
      subject.should_receive(:system).twice.with("QUEUE=test rake resque:work &")
      subject.scale_up(2)
    end
  end
  
end