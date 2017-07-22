require "sass"
require "file_utils"

SOURCE_DIR = File.expand_path(ARGV[0], __DIR__)
TARGET_DIR = File.expand_path(ARGV[1], __DIR__)

def compile(filename)
  target_path = File.join(TARGET_DIR, File.dirname(filename).lchop(SOURCE_DIR))
  target_filename = File.join(target_path, File.basename(filename, File.extname(filename)) + ".css")
  FileUtils.mkdir_p(target_path)

  css = Sass.compile_file(filename, include_path: SOURCE_DIR)

  File.open(target_filename, "w+", &.puts css)
  puts "Compiled: #{filename.lchop(Dir.current)} -> #{target_filename.lchop(Dir.current)}"
rescue
  puts "Skipped: #{filename.lchop(Dir.current)}"
end

Dir.glob(File.join(SOURCE_DIR, "**/*.{sass,scss}")).each do |filename|
  compile filename
end
