module Tracker::Command
  class Todo < Base
    
    def main
      todos = tracker.todos(extract_project).collect{|l|l["todo"]}
      unless todos.size == 0
        puts "Todo:"
        todos.each do |todo|
          puts "##{todo['ticket_id']}\t #{todo['description'].split("\n").first}"
        end
      else
        puts "Nothing todo in this project"
      end
    end

    def done
      todos = tracker.todos_complete(extract_project).collect{|l|l["todo"]}
      unless todos.size == 0
        puts "Todo:"
        todos.each do |todo|
          puts "#{todo['completed_at'].split('T').first} ##{todo['ticket_id']}\t #{todo['description'].split("\n").first}"
        end
      else
        puts "Nothing done in this project yet"
      end
    end

    def create
      todo = tracker.create_todo(extract_project, @args.join(' '))
      if todo["todo"]
        display_todo todo
      end
    end

    def detail
      if @args.first.to_i > 0
        display_todo tracker.show_todo(extract_project, @args.first.to_i)
      else
        puts 'Incorrect ticket id'
      end
    end

    private

    def display_todo(todo)
      t = todo['todo']
      puts "Ticket #{t['ticket_id']}"
      puts
      puts t['description']
      puts
      puts "Priority:    #{t['priority']}"
      puts "Estimation:  #{t['est'] || 'not estimated'}"
      puts "Contributor: #{t['responsible'] || 'not planned'}"
      puts "Completed:   #{t['is_done'] ? t['completed_at'] : 'no'}"
      puts "Real cost:   #{t['cost'] || '0'}"
    end
    
  end
end
