require "copt/version"

module Copt
  class Error < StandardError; end
  autoload :App, 'copt/app'
  autoload :Command, 'copt/command'
  autoload :Option, 'copt/option'

  def self.included(receiver)
    receiver.send :extend, Copt::App::ClassMethods
    receiver.send :include, Copt::App::InstanceMethods
  end
end
