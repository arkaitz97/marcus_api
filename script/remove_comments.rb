# This script removes all comments from controllers, models, and routes files.

require 'fileutils'

# Directories to process
directories = [
  'app/controllers',
  'app/models',
  'config/routes.rb'
]

# Method to remove comments from a file
def remove_comments_from_file(file_path)
  content = File.read(file_path)
  uncommented_content = content.lines.reject { |line| line.strip.start_with?('#') }.join
  File.write(file_path, uncommented_content)
  puts "Processed: #{file_path}"
end

# Process each directory or file
directories.each do |path|
  if File.directory?(path)
    Dir.glob("#{path}/**/*.rb").each do |file|
      remove_comments_from_file(file)
    end
  elsif File.file?(path)
    remove_comments_from_file(path)
  else
    puts "Path not found: #{path}"
  end
end