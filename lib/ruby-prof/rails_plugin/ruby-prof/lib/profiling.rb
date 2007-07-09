require 'ruby-prof'

module ActionController #:nodoc:
  # The ruby-prof module times the performance of actions and reports to the logger. If the Active Record
  # package has been included, a separate timing section for database calls will be added as well.
  module Profiling #:nodoc:
    def self.included(base)
      base.class_eval do
        alias_method_chain :perform_action, :profiling
      end
    end

    def perform_action_with_profiling
      # Profling could be running if this
      # is a render_component call.
      if RubyProf.running? or
         not logger or
         not logger.level == Logger::DEBUG
        perform_action_without_profiling
      else
        result = RubyProf.profile do
          perform_action_without_profiling
        end
        
        output = StringIO.new
        output << " [#{complete_request_uri rescue "unknown"}]"
        output << "\n\n"
        
        # Create a flat printer
        printer = RubyProf::FlatPrinter.new(result)
        
        # Skip anything less than 1% - which is a lot of
        # stuff in Rails. Don't print the source file
        # its too noisy.
        printer.print(output, {:min_percent => 1,
                               :print_file => false})
        logger.info(output.string)
        
        ## Example for Graph html printer
        #printer = RubyProf::GraphHtmlPrinter.new(result)
        #File.open('c:/temp/request.html', 'w') do |file|
          #printer.print(file, {:min_percent => 1,
                               #:print_file => true})
        #end   
        
        ## Used for KCacheGrind visualizations
        #printer = RubyProf::CallTreePrinter.new(result)
        #File.open('c:/temp/callgrind.out', 'w') do |file|
          #printer.print(file, {:min_percent => 1,
                                 #:print_file => true})
        #end          
      end
    end
  end
end
