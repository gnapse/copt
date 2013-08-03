module Copt
  class Option
    attr_reader :command, :name, :long, :short, :type, :default

    def initialize(command, name, description, extra = {})
      @command = command
      @description = description

      @default = extra[:default]
      @default = @default.call if @default.is_a?(Proc)
      @type = normalized_type(extra[:type])
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

    def parse_value(value)
      case type
      when :int then parse_int(value)
      when :float then parse_float(value)
      when :date then parse_date(value)
      when :string then value.to_s
      else
        raise Copt::Error, "Option type '#{type}' not supported."
      end
    end

    private

    # Regex for floating point numbers
    FLOAT_RE = /^-?((\d+(\.\d+)?)|(\.\d+))([eE][-+]?[\d]+)?$/

    def parse_int(value)
      raise Copt::Error, "Option '#{name}' expects an integer" unless value =~ /\A\d+\z/
      value.to_i
    end

    def parse_float(value)
      raise Copt::Error, "Option '#{name}' expects a float number" unless value =~ FLOAT_RE
      value.to_f
    end

    def parse_date(value)
      Date.parse(value)
    rescue ArgumentError
      raise Copt::Error, "Option '#{name}' expects a date"
    end

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
