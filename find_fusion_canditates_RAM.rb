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
  options = {:out_file =>  "fusion_canditates.txt"}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: find_fusion_canditates.rb [options] R1.sam R2.sam"
    opts.separator ""
    opts.separator "sam files aligned to transcriptome, sorted by queryname"

    opts.separator ""
    opts.on("-o", "--out_file [OUT_FILE]",
      :REQUIRED,String,
      "File for the output, Default: fusion_canditates.txt") do |anno_file|
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

def skip_header(open_file)
  open_file.each do |line|
    break unless line =~ /^@/
  end
  open_file.lineno = open_file.lineno - 1
end

def read_samfiles(sam_files,out_file)
  fwd = File.open(sam_files[0])
  rev = File.open(sam_files[1])
  out_file_handler = File.open(out_file,'w')
  skip_header(fwd)
  skip_header(rev)
  fwd_info = {}
  fwd_sequences = {}

  fwd.each do |fwd_line|
    next unless fwd_line =~ /NH:i:1/
    $logger.debug("fwd_line: " + fwd_line)
    fwd_line.chomp!
    fwd_fields = fwd_line.split("\t")
    #fwd_info[fwd_fields[0]] = [] unless fwd_info[fwd_fields[0]]
    next if fwd_fields == "*"
    $logger.debug("fwd_line2: " + fwd_line)
    fwd_fields[0].gsub!(/[ab]/,"")
    fwd_info[fwd_fields[0]] = fwd_fields[2]
    fwd_sequences[fwd_fields[0]]  = fwd_fields[9]
  end

  rev_info = {}
  rev_sequences = {}
  name = ""

  rev.each do |rev_line|
    next unless rev_line =~ /NH:i:1/
    rev_fields = rev_line.split("\t")
    rev_fields[0].gsub!(/[ab]/,"")
    name = rev_fields[0] if name == "*"
    found = false
    if fwd_info[rev_fields[0]] == rev_fields[2] || fwd_info[rev_fields[0]] == "*" || rev_fields[2] == "*" || !fwd_info[rev_fields[0]]
      found = true
      fwd_info.delete(rev_fields[0])
      fwd_sequences.delete(rev_fields[0])
    else
      puts "#{rev_fields[0]}\t#{fwd_info[rev_fields[0]]}\t#{rev_fields[2]}"
      found = true
      out_file_handler.puts("#{rev_fields[0]}\t#{fwd_sequences[rev_fields[0]]}\t#{rev_fields[2]}")
      out_file_handler.puts("#{rev_fields[0]}\t#{rev_fields[9]}\t#{fwd_info[rev_fields[0]]}")
      fwd_info.delete(rev_fields[0])
      fwd_sequences.delete(rev_fields[0])
    end
    unless found
      #rev_info[rev_fields[0]] = rev_fields[2]
    end
  end
end

def get_memory_usage
  `ps -o rss= -p #{Process.pid}`.to_i
end


def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)
  before = get_memory_usage
  #print "BEFORE: " + before.to_s
  $logger.info("BEFORE: " + before.to_s + " (in 1024 Bytes)")
  
  gene_info = read_samfiles(argv,options[:out_file])
  after = get_memory_usage
  #print "AFTER: " + (after-before).to_s
  $logger.info("AFTER: " + (after-before).to_s + " (in 1024 Bytes)")
end

if __FILE__ == $0
  run(ARGV)
end

