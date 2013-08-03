module Copt
  class Command
    attr_reader :app, :name, :options, :block
    attr_reader :preconditions
    attr_accessor :description

    def initialize(app, name, description)
      @app = app
      @name = name
      @description = description
      @options = {}
      @preconditions = []
    end

    def option(name, description, extra = {})
      opt = Option.new(self, name, description, extra)

      # Check for duplicate option keys
      dup opt.name, options
      dup opt.short, options
      dup opt.long, options
      unless name.nil? # global command
        dup opt.name, app.global_options
        dup opt.short, app.global_options
        dup opt.long, app.global_options
      end

      @options[opt.name] = opt
      @options[opt.long] = opt
      @options[opt.short] = opt if opt.short
    end

    def has_option?(key)
      @options.has_key?(key)
    end

    def block(&b)
      return @block unless block_given?
      raise Copt::Error, "Command '#{name}' can't have two run blocks" if @block
      @block = b
    end

    def check(message, &block)
      raise Copt::Error, 'Missing check code block' unless block_given?
      @preconditions << [message, block]
    end

    def default_option_values
      unless @default_option_values
        @default_option_values = {}
        @options.each_pair do |name, opt|
          @default_option_values[name] = opt.default if opt.default
        end
      end
      @default_option_values
    end

    private

    def dup(str, hash)
      raise Copt::Error, "Duplicate option key '#{str}'" if hash.has_key?(str)
    end
  end
end
