module Tracker::Command
  class Application < Base
    def help
      puts "Usage: tracker [command [arguments]]"
    end

    def test
      p @args.join ' '
    end

    def init
      project_name = @args.join ' '

      unless project_name == ''
        id = create_project_by_name(project_name)
      else
        projects = tracker.list.collect{|i| i["project"]}
        if projects.size == 0
          puts "Please enter project name you want to create"
        else
          puts 'Please specify, which project do you want to init here:'
          projects.each_with_index do |prj, index|
            puts "#{index + 1}.\t#{prj["name"]} #{prj["id"]}"
          end
          puts 'Enter project number or type name of project if you want to create new one: '
        end
        
        selected_index = ask
        if selected_index =~ /^\d+$/
          id = false
          index = selected_index.to_i
          if 0 < index && index <= projects.size
            project = projects[index - 1]
            id = project["id"].to_i
          end
        else
          id = create_project_by_name(selected_index)
        end
      end
      if id
        File.open("#{Dir.pwd}/.tracker", 'w') do |file|
          file.puts id
        end
        puts 'Project successfully initialized'
      else
        puts 'Project not initialized'
      end
    end

    def list_todos
      tracker.list_todos(extract_project).collect{|t| t['todo']}.each do |t|
        puts "##{t['ticket_id']}\t#{t['description']}"
      end
    end

    private

    def create_project_by_name(project_name)
      tracker.create_project(project_name)["id"]
    end
  end
end
