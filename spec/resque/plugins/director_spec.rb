require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

class TestJob
  extend Resque::Plugins::Director

  def self.perform
  end
end

describe Resque::Plugins::Director do
  it "should follow the resque plugin convention" do
    Resque::Plugin.lint(Resque::Plugins::Director)
  end
end
