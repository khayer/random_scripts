#!/usr/bin/env ruby
require 'optparse'
require 'logger'

$logger = Logger.new(STDERR)

# Initialize logger
def setup_logger(loglevel)
  case loglevel
  when "debug"
    $logger.level = Logger::DEBUG
  when "warn"
    $logger.level = Logger::WARN
  when "info"
    $logger.level = Logger::INFO
  else
    $logger.level = Logger::ERROR
  end
end

def setup_options(args)
  options = {:out_file =>  "fusion_canditates_table.txt"}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: fusion_table.rb [options] fusion_canditates.txt"
    opts.separator ""
    opts.separator "sam files aligned to transcriptome, sorted by queryname"

    opts.separator ""
    opts.on("-o", "--out_file [OUT_FILE]",
      :REQUIRED,String,
      "File for the output, Default: fusion_canditates_table.txt") do |anno_file|
      options[:out_file] = anno_file
    end

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:log_level] = "info"
    end

    opts.on("-d", "--debug", "Run in debug mode") do |v|
      options[:log_level] = "debug"
    end

  end

  args = ["-h"] if args.length == 0
  opt_parser.parse!(args)
  raise "Please specify the sam files" if args.length == 0
  options
end

def read_samfiles(sam_files,out_file)
  sam_file_h = File.open(sam_files[0])
  out_file_h = File.open(out_file,'w')
  sam_file_h.each do |line|
    line.chomp!
    next if line == ""
    fields[0] = line.split("\t")
  end
end


def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)

  gene_info = read_samfiles(argv,options[:out_file])

end

if __FILE__ == $0
  run(ARGV)
end

