#!/usr/bin/env rspec
require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe GitBareRepo do
  describe "when creating a bare git repo object" do
    it "should fail when given an invalid repo directory" do
      proc{GitBareRepo.new("bad_dir")}.should raise_error(Grit::NoSuchPathError)
    end
  end
end
