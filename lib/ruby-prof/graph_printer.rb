module RubyProf
  # Generates graph[link:files/examples/graph_txt.html] profile reports as text. 
  # To use the graph printer:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::GraphPrinter.new(result, 5)
  #   printer.print(STDOUT, 0)
  #
  # The constructor takes two arguments.  The first is
  # a RubyProf::Result object generated from a profiling
  # run.  The second is the minimum %total (the methods 
  # total time divided by the overall total time) that
  # a method must take for it to be printed out in 
  # the report.  Use this parameter to eliminate methods
  # that are not important to the overall profiling results.

  class GraphPrinter
    PERCENTAGE_WIDTH = 8
    TIME_WIDTH = 10
    CALL_WIDTH = 20
  
    # Create a GraphPrinter.  Result is a RubyProf::Result  
    # object generated from a profiling run.
    def initialize(result, min_percent = 0)
      @result = result
      @min_percent = min_percent
    end

    # Print a graph report to the provided output.
    # 
    # output - Any IO oject, including STDOUT or a file. 
    # The default value is STDOUT.
    # 
    # min_percent - The minimum %total (the methods 
    # total time divided by the overall total time) that
    # a method must take for it to be printed out in 
    # the report. Default value is 0.
    def print(output = STDOUT, min_percent = 0)
      @output = output
      @min_percent = min_percent

        print_threads
    end

    private 
    def print_threads
      # sort assumes that spawned threads have higher object_ids
      @result.threads.sort.each do |thread_id, methods|
        print_methods(thread_id, methods)
        @output << "\n" * 2
      end
    end
    
    def print_methods(thread_id, methods)
      # Sort methods from longest to shortest total time
      methods = methods.sort.reverse
      
      toplevel = methods.first
      total_time = toplevel.total_time
      if total_time == 0
        total_time = 0.01
      end
      
      print_heading(thread_id)
    
      # Print each method in total time order
      methods.each do |method|
        total_percentage = (method.total_time/total_time) * 100
        self_percentage = (method.self_time/total_time) * 100
        
        next if total_percentage < @min_percent
        
        @output << "-" * 80 << "\n"

        print_parents(thread_id, method)
    
        # 1 is for % sign
        @output << sprintf("%#{PERCENTAGE_WIDTH-1}.2f\%", total_percentage)
        @output << sprintf("%#{PERCENTAGE_WIDTH-1}.2f\%", self_percentage)
        @output << sprintf("%#{TIME_WIDTH}.2f", method.total_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", method.self_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", method.children_time)
        @output << sprintf("%#{CALL_WIDTH}i", method.called)
        @output << sprintf("     %s", method.name)
        @output << "\n"
    
        print_children(method)
      end
    end
  
    def print_heading(thread_id)
      @output << "Thread ID: #{thread_id}\n"
      # 1 is for % sign
      @output << sprintf("%#{PERCENTAGE_WIDTH}s", "%total")
      @output << sprintf("%#{PERCENTAGE_WIDTH}s", "%self")
      @output << sprintf("%#{TIME_WIDTH}s", "total")
      @output << sprintf("%#{TIME_WIDTH}s", "self")
      @output << sprintf("%#{TIME_WIDTH+2}s", "children")
      @output << sprintf("%#{CALL_WIDTH-2}s", "calls")
      @output << "   Name"
      @output << "\n"
    end
    
    def print_parents(thread_id, method)
      method.parents.each do |caller|
        @output << " " * 2 * PERCENTAGE_WIDTH
        @output << sprintf("%#{TIME_WIDTH}.2f", caller.total_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", caller.self_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", caller.children_time)
    
        call_called = "#{caller.called}/#{method.called}"
        @output << sprintf("%#{CALL_WIDTH}s", call_called)
        @output << sprintf("     %s", caller.target.name)
        @output << "\n"
      end
    end
  
    def print_children(method)
      method.children.each do |child|
        # Get children method
        
        @output << " " * 2 * PERCENTAGE_WIDTH
        
        @output << sprintf("%#{TIME_WIDTH}.2f", child.total_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", child.self_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", child.children_time)

        call_called = "#{child.called}/#{child.target.called}"
        @output << sprintf("%#{CALL_WIDTH}s", call_called)
        @output << sprintf("     %s", child.target.name)
        @output << "\n"
      end
    end
  end
end 

