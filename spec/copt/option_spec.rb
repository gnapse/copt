require 'spec_helper'

describe Copt::Option do
  let(:command) { Copt::Command.new(nil, :cmd, 'desc') }

  def new_option(name, hash = {})
    Copt::Option.new(command, name, 'desc', hash)
  end

  def expect_success(&block)
    expect(&block).not_to raise_error
  end

  def expect_failure(&block)
    expect(&block).to raise_error(Copt::Error)
  end

  describe '.initialize' do
    it 'defaults to flag type if no type or default is given' do
      opt = new_option(:flag_opt)
      expect(opt.type).to eq(:flag)
    end

    it 'infers type from the default value correctly' do
      opt = new_option(:flag_opt, default: true)
      expect(opt.type).to eq(:flag)
      opt = new_option(:int_opt, default: 0)
      expect(opt.type).to eq(:int)
      opt = new_option(:float_opt, default: 0.0)
      expect(opt.type).to eq(:float)
      opt = new_option(:string_opt, default: 'none')
      expect(opt.type).to eq(:string)
      opt = new_option(:float_opt, default: Date.new(1979, 7, 27))
      expect(opt.type).to eq(:date)
    end

    it 'fails if default value conflicts with type' do
      expect_success { new_option(:first, default: 0, type: Integer) }
      expect_success { new_option(:second, default: 0.0, type: Float) }
      expect_failure { new_option(:third, default: 0, type: Date) }
      expect_failure { new_option(:fourth, default: 'none', type: :flag) }
    end

    it 'fails if short option name is not a single char' do
      expect_success { new_option(:first, short: 'c') }
      expect_failure { new_option(:second, short: 'cc') }
    end

    it 'fails if long option name is a single char' do
      expect_success { new_option(:first, long: 'cc') }
      expect_failure { new_option(:second, long: 'c') }
    end
  end

  describe '.parse_value' do
    def parse_value(name, type, value)
      option = Copt::Option.new(command, name, 'desc', type: type)
      option.parse_value(value)
    end

    it 'parses string values correctly' do
      value = parse_value(:id, String, '1234')
      expect(value).to eq('1234')
    end

    it 'parses integer numbers correctly' do
      value = parse_value(:age, Integer, '34')
      expect(value).to eq(34)
    end

    it 'parses floating point numbers correctly' do
      value = parse_value(:height, Float, '1.73')
      expect(value).to eq(1.73)
    end

    it 'parses dates correctly' do
      value = parse_value(:birth_date, Date, '1979-07-27')
      expect(value).to eq(Date.new(1979, 7, 27))
    end
  end
end
