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
  options = {}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: find_fusion_canditates.rb [options] R1.sam R2.sam"
    opts.separator ""
    opts.separator "sam files aligned to transcriptome, sorted by queryname"
  
    opts.separator ""
    #opts.on("-a", "--annotation_file [ANNO_FILE]",
    #  :REQUIRED,String,
    #  "fbgn_annotation_ID_fb_2013_05.tsv") do |anno_file|
    #  options[:anno_file] = anno_file
    #end

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

def read_samfiles(sam_files)
  fwd = File.open(sam_files[0])
  rev = File.open(sam_files[1])
  skip_header(fwd)
  skip_header(rev)
  fwd_info = {}
  rev_info = {}
  name = ""
  found = false
  fwd.each do |fwd_line|
    $logger.debug("fwd_line: " + fwd_line)
    fwd_line.chomp!
    fwd_fields = fwd_line.split("\t")
    name = fwd_fields[0] if name == ""
    if fwd_fields[0] != name
      rev.each do |rev_line|
        $logger.debug("rev_line: " + rev_line)
        rev_line.chomp!
        rev_fields = rev_line.split("\t")
        break if rev_fields[0] != name
        rev_info[rev_fields[0]] = [] unless rev_info[rev_fields[0]]
        rev_info[rev_fields[0]]  << rev_fields[2]
      end
      rev.lineno = rev.lineno - 1
      rev_info[name].each do |gene_name|
        if !fwd_info[name].include?(gene_name)
          found = true
          puts "#{name}\t#{gene_name}\t#{fwd_info[name]}"
        else
          fwd_info[name].delete(gene_name)
        end
      end
      name = fwd_fields[0]
      unless found
        fwd_info.delete(name)
        rev_info.delete(name)
      else
      end

    end
    fwd_info[fwd_fields[0]] = [] unless fwd_info[fwd_fields[0]]
    fwd_info[fwd_fields[0]]  << fwd_fields[2]
  end
  rev.each do |rev_line|
    $logger.debug("rev_line: " + rev_line)
    rev_line.chomp!
    rev_fields = rev_line.split("\t")
    break if rev_fields[0] != name
    rev_info[rev_fields[0]] = [] unless rev_info[rev_fields[0]]
    rev_info[rev_fields[0]]  << rev_fields[2]
  end
  rev.lineno = rev.lineno - 1
  rev_info[name].each do |gene_name|
    if !fwd_info[name].include?(gene_name)
      found = true
      puts "#{name}\t#{gene_name}\t#{fwd_info[name]}"
    else
      fwd_info[name].delete(gene_name)
    end
  end
  #name = fwd_fields[0]
  unless found
    fwd_info.delete(name)
    rev_info.delete(name)
  else
  end
  $logger.debug(fwd_info)
  $logger.debug(rev_info)
end


def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)

  gene_info = read_samfiles(argv)
  
end

if __FILE__ == $0
  run(ARGV)
end

