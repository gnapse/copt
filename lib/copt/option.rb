module Copt
  class Option
    attr_reader :command, :name, :long, :short, :type, :default

    def initialize(command, name, description, extra = {})
      @command = command
      @description = description

      @default = extra[:default]
      @type = extra[:type]
      type_from_default = type_for(@default)
      if @type && type_from_default && @type != type_from_default
        raise Copt::Error, "Conflict between type of default value and explicit :type for option '#{name}'"
      end
      @type ||= type_from_default || :flag
      @default = false if @default.nil? && @type == :flag

      @name = name.to_sym
      @long = extra[:long] || @name
      @short = extra[:short]
      @long = @long.to_sym
      @short = @short.to_sym if @short

      if @short && @short.length != 1
        raise Copt::Error, 'Short option names must consist of a single letter only.'
      end
      if @long.length <= 1
        raise Copt::Error, 'Long option names must consist of at least two letters.'
      end
    end

    def app
      @command.app
    end

    private

    def normalized_type(type)
      case type
      when :boolean, :bool then :flag
      when :integer then :int
      when :integers then :ints
      when :double then :float
      when :doubles then :floats
      when Class
        case type.name
        when 'TrueClass', 'FalseClass' then :flag
        when 'String' then :string
        when 'Integer' then :int
        when 'Float' then :float
        when 'Date' then :date
        when 'IO' then :io
        else unsupported(type.name)
        end
      when nil then nil
      else unsupported(type)
      end
    end

    def type_for(value)
      case value
      when Integer then :int
      when Numeric then :float
      when TrueClass, FalseClass then :flag
      when String then :string
      when Date then :date
      when IO then :io
      when nil then nil
      else unsupported(value.class.name)
      end
    end

    def unsupported(type)
      raise Copt::Error, "Unsupported argument type '#{type}'"
    end
  end
end
