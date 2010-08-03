module Tracker::Command
  class List < Base
    
    def main
      lists = tracker.todo_lists(extract_project).collect{|l|l["todo_list"]}
      unless lists.size == 0
        puts "Todo lists:"
        longest_name_length = lists.map{|l| l['name'].size}.compact.max
        lists.each do |list|
          puts format_list(list, longest_name_length)
        end
      end
    end
    
    def format_list(l, longest_name_length)
      done = l['completed_todos_count'].to_i
      todo = l['current_todos_count'].to_i
      name = l['name'].upcase
      comment = if todo > 0
        "#{todo} tasks todo, #{done} tasks done"
      elsif done > 0
        "completed"
      else
        "empty"
      end
      "%-*s # %s" % [longest_name_length, name, comment]
    end
  end
end
