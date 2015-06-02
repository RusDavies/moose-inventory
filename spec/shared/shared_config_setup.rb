
RSpec.shared_context "shared config init", :a => :b do
  before(:all) do
    @mockarg_parts = {
      config:  File.join(TestHelpers.specdir, 'config/config.yml'),
      format:  "yaml",
      env:     "test"
    }

    @mockargs = []
    @mockarg_parts.each do |key, val|
      @mockargs << "--#{key}"
      @mockargs << val
    end

    @config = Moose::Inventory::Config
    @config.init(@mockargs)

    @db      = Moose::Inventory::DB

  end
end