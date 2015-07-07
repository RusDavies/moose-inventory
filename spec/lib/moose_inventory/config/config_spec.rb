require 'spec_helper'

RSpec.describe 'Moose::Inventory::Config' do
  before(:all) do
    # Set up the configuration object
    @mockarg_parts = {
      config:  File.join(spec_root, 'config/config.yml'),
      format:  'yaml',
      env:     'test'
    }

    @mockargs = []
    @mockarg_parts.each do |key, val|
      @mockargs << "--#{key}"
      @mockargs << val
    end

    @config = Moose::Inventory::Config
  end

  # .init()
  describe '.init()' do
    it 'should be responsive' do
      result = @config.respond_to?(:init)
      expect(result).to eq(true)
    end
  end

  # ._configopts
  describe '._configopts' do
    it 'should be responsive' do
      result = @config.respond_to?(:_confopts)
      expect(result).to eq(true)
    end

    it 'should not be nil' do
      @config.init(@mockargs)
      expect(@config._confopts).not_to be_nil
    end

    it 'should default "--format" to json' do
      @config.init([])
      expect(@config._confopts[:format]).to eq('json')
    end

    it 'should pick up "--format" from its argument list' do
      @config.init(@mockargs)
      expect(@config._confopts[:format]).to eq('yaml')
    end

    it 'should default "--env" to ""' do
      @config.init([])
      expect(@config._confopts[:env]).to eq('')
    end

    it 'should pick up "--env" from its argument list' do
      tmpargs = ['--env', 'rspectest', '--config', @mockarg_parts[:config]]
      @config.init(tmpargs)
      expect(@config._confopts[:env]).to eq('rspectest')
    end
  end

  # ._settings
  describe '._settings' do
    it 'should be responsive' do
      result = @config.respond_to?(:_settings)
      expect(result).to eq(true)
    end

    it 'should not be nil' do
      @config.init(@mockargs)
      expect(@config._confopts).not_to be_nil
    end

    it 'should pick up "config.db" from the configuration file' do
      @config.init(@mockargs)
      expect(@config._settings[:config][:db]).not_to be_nil
    end
  end
end
