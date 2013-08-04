module Copt::App

  module ClassMethods
    attr_reader :commands, :config

    #
    # Sets the app description and configuration settings.
    #
    def app(desc, config = {})
      @config = config.dup.freeze

      @command = Copt::Command.new(self, nil, desc)
      yield if block_given?

      commands[nil] = @command
      @global_command = @command
      @command = nil
    end

    #
    # Declares a new app subcommand.
    #
    def command(name, description)
      raise Copt::Error, "Duplicate command '#{name}'" if commands.has_key?(name)

      @command = Copt::Command.new(self, name, description)
      yield @command

      if @command.block.nil?
        raise Copt::Error, "Command '#{name}' has no run block."
      end

      commands[name] = @command
      @command = nil
      commands[name]
    rescue Copt::Error => e
      errors << e.message
    end

    #
    # Declares a command line option for the current subcommand.
    #
    def option(name, description, extra = {})
      @command.option(name, description, extra)
    rescue Copt::Error => e
      errors << e.message
    end

    #
    # Declares a precondition that must be met before the current subcommand
    # executes.
    #
    def check(message, &block)
      @command.check(message, &block)
    rescue Copt::Error => e
      errors << e.message
    end

    #
    # Specifies the block of code to execute when the current subcommand is
    # invoked.
    #
    def run(&block)
      @command.block(&block)
    rescue Copt::Error => e
      errors << e.message
    end

    #
    # Returns the description of this app.
    #
    def description
      @global_command.description
    end

    #
    # Returns the version number of this app.
    #
    def version
      @config[:version]
    end

    #
    # The list of errors detected in the app's command and option definitions.
    #
    def errors
      @errors ||= []
    end

    #
    # The set of options accepted by all commands.
    #
    def global_options
      @global_command.options
    end

    #
    # Run the app with the given arguments.
    #
    # This action parses the arguments, detects the subcommand being invoked,
    # along with any options and arguments, and invokes the appropriate
    # subcommand block.
    #
    def run!(arguments = ARGV)
      validate
      app = new(arguments)
      app.run
    end

    alias_method :opt, :option
    alias_method :v, :version
    alias_method :desc, :description
    alias_method :cmd, :command

    private

    #
    # A hash of objects representing all the app's commands and options supported.
    #
    def commands
      @commands ||= {}
    end

    #
    # The list of names of all supported subcommands.
    #
    def command_names
      commands.keys.compact
    end

    #
    # Validates that there were no errors reported for the app command and option definitions.
    #
    def validate
      unless errors.empty?
        $stderr.puts 'Fatal: There are command and option definition errors:'
        errors.each { |error| $stderr.puts " - #{error}" }
        exit(-1)
      end
    end

    #
    # Resets the app as if no commands, options and settings have been defined.
    #
    # Used for testing and debugging purposes only.
    #
    def reset
      @commands = @command = @global_command = @errors = nil
    end
  end

  module InstanceMethods
    attr_reader :args, :opts

    #
    # Initializes a new app instance.
    #
    def initialize(arguments = ARGV)
      parse arguments.dup
      @status = :initialized
    end

    #
    # The name of the command invoked in this app instance.
    #
    def command
      @command ? @command.name : nil
    end

    #
    # When called with no arguments, it runs this app instance, executing
    # whatever command was invoked.
    #
    # However, this method can be used to invoke another command explicitly, by
    # providing its name as an argument, along with an optional hash.  This can
    # only be done while the main app logic is running, making it possible for
    # a command to be able to call other commands within its own block of code.
    #
    # When used in this fashion, the hash supports three different optional
    # arguments controlling the nested subcommand invocation:
    #
    # hash[:arr] - An array of arguments to provide to the command being
    #   invoked.  If omitted, the command will be invoked with the same list
    #   of arguments of the invoking command.
    #
    # hash[:opts] - A hash of options to provide to the command being invoked.
    #   If omitted, the command will be invoked with the same set of options of
    #   the invoking command.
    #
    # hash[:check] - A boolean flag indicating if the invoked subcommand should
    #   check its preconditions and other error conditions, or not.  This flag
    #   is assumed to be true unless explicitly stated to be false, thus
    #   bypassing error checking.
    #
    def run(command_name = nil, hash = nil)
      if command_name
        raise Copt::Error, "Cannot invoke commands if app is not running" unless @status == :running
        hash ||= {}
        push(command_name, hash)
      else
        raise Copt::Error, "App cannot be run more than once" unless @status == :initialized
        @status = :running
      end

      check_errors unless hash && hash.fetch(:check, true) == false
      instance_eval(&@command.block)

      if command_name
        pop
      else
        @status = :finished
      end

      self
    end

    #
    # Checks that the given condition holds, and reports an error if not.
    #
    def check(condition, message = nil, stream = $stderr)
      unless condition
        errors << message if message
        print_help(stream)
      end
    end

    #
    # Prints the app's help message and exits.
    #
    def print_help(stream = $stdout)
      stream.puts errors.last unless errors.empty?
      stream.puts 'TODO: Help'
      exit(stream == $stdout && errors.empty?)
    end

    private

    def check_errors
      check errors.empty?
      check @command, 'No command given'
      @command.preconditions.each do |precondition|
        message, block = *precondition
        result = instance_eval(&block)
        check(result, message)
      end
    end

    #
    # Parses the given list of arguments, detecting the invoked subcommand,
    # command line options and extra arguments.
    #
    def parse(arguments)
      return if @parsed
      @arguments = arguments
      @command = nil
      @args = []
      @opts = {}
      @all_args = false
      until @arguments.empty?
        s = @arguments.shift
        if s =~ /\A-+\z/ && !@all_args
          @all_args = true
        elsif s.start_with?('-') && !@all_args
          process_option(s)
        else
          process_argument(s)
        end
      end
      @parsed = true
    end

    def process_argument(str)
      if @args.empty? && @command.nil? && command?(str) && !@all_args
        @command = commands[str.to_sym]
        @opts = @command.default_option_values.merge(@opts)
      else
        @args << str
      end
    end

    def process_option(str)
      if str.start_with?('---')
        errors << "Invalid option '#{str}'"
      elsif str.start_with?('--no-')
        option = str.sub(/\A--no-/, '').gsub('-', '_').to_sym
        add_option(option, :negative)
      elsif str.start_with?('--')
        option = str.sub(/\A--/, '').gsub('-', '_').to_sym
        add_option(option)
      else # options starts with a single '-'
        str = str.sub(/\A-/, '')
        if str.length == 1
          add_option(str.to_sym)
        else
          str.each_char { |c| add_option(c.to_sym, :flag) }
        end
      end
    end

    def add_option(option_name, mode = nil)
      option = global_options[option_name]
      option = @command.options[option_name] if @command && option.nil?

      unless option
        errors << "Invalid option '#{option_name}'"
        return
      end

      if mode == :negative && option.type != :flag
        errors << "Invalid option '--no-#{option_name}'"
        return
      end

      if mode == :flag && option.type != :flag
        errors << "Can't accept option '#{option_name}' without an argument"
        return
      end

      if option.type == :flag
        @opts[option.name] = (mode != :negative)
      else
        @opts[option.name] = option.parse_value(@arguments.shift)
      end
    end

    def global_options
      self.class.send :global_options
    end

    def commands
      self.class.send :commands
    end

    def command?(name)
      commands.has_key?(name.to_sym)
    end

    def config
      self.class.config
    end

    def errors
      @errors ||= []
    end

    def push(command_name, hash)
      new_command = commands[command_name.to_sym]
      raise Copt::Error, "Unknow command name '#{command_name}'" if new_command.nil?

      @stack ||= []
      @stack.push({
        command: @command,
        opts: @opts,
        args: @args,
        errors: @errors,
      })

      @command = new_command
      @opts = hash[:opts] || @opts
      @args = hash[:args] || @args
      @errors = []
    end

    def pop
      raise Copt::Error, "Internal copt stack empty" if @stack.nil? || @stack.empty?
      top = @stack.pop
      @command = top[:command]
      @opts = top[:opts]
      @args = top[:args]
      @errors = top[:errors]
      top
    end
  end

end
