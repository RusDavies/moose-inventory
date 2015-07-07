require 'json'
require 'yaml'
require 'indentation'

module Moose
  module Inventory
    module Cli
      ##
      # TODO: Documentation
      module Formatter
        # rubocop:disable Style/ModuleFunction
        extend self
        # rubocop:enable Style/ModuleFunction

        def self.dump(arg, format = nil)
          out(arg, format)
        end
        
        def self.out(arg, format = nil)
          return if arg.nil?

          if format.nil?
            format = Moose::Inventory::Config._confopts[:format].downcase
          end
          
          case format
          when 'yaml','y'
            $stdout.puts arg.to_yaml

          when 'prettyjson','pjson','p'
            $stdout.puts JSON.pretty_generate(arg)

          when 'json','j'
            $stdout.puts arg.to_json

          else
            abort("Output format '#{format}' is not yet supported.")
          end
        end
        
        #---------------
        attr_accessor :indent

        def reset_indent
          @indent = 2
        end
        
        def puts(indent, msg, stream='STDOUT')
          case stream
          when 'STDOUT'
            $stdout.puts msg.indent(indent)
          when 'STDERR'
            $stderr.puts msg.indent(indent)
          else
            abort("Output stream '#{stream}' is not known.")
          end
        end
        
        def print(indent, msg, stream='STDOUT')
          case stream
          when 'STDOUT'
            $stdout.print msg.indent(indent)
          when 'STDERR'
            $stderr.print msg.indent(indent)
          else
            abort("Output stream '#{stream}' is not known.")
          end
        end

        def info(indent, msg, stream='STDOUT')
          case stream
          when 'STDOUT'
            $stdout.print "INFO: {msg}"
          when 'STDERR'
            $stderr.print "INFO: {msg}"
          else
            abort("Output stream '#{stream}' is not known.")
          end
        end
        
        def warn(msg)
            $stderr.print "WARNING: #{msg}"
        end

        def error(msg)
            $stderr.print "ERROR: #{msg}"
        end
                        
      end
    end
  end
end
