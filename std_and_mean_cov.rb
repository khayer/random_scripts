#!/usr/bin/env ruby
#require 'csv'
#require 'rsruby'
require 'optparse'
require 'logger'
require 'descriptive_statistics'


$logger = Logger.new(STDERR)

#groups = ARGV[0].split(",")

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
    opts.banner = "Usage: #{$0} [options] union.cov"
    opts.separator ""

    opts.on("-p", "--out_prefix [OUT_PREFIX]",:REQUIRED,String,  "Out prefix") do |p|
      options[:out_prefix] = p
    end

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:log_level] = "info"
    end

    opts.on("-d", "--debug", "Run in debug mode") do |v|
      options[:log_level] = "debug"
    end

    opts.on("-g", "--groups [GROUPS]",:REQUIRED,
      String,
      "grouping, for example 3,3 for two groups with each 3 replicates") do |g|
      options[:groups] = g
    end


  end

  args = ["-h"] if args.length == 0
  opt_parser.parse!(args)
  raise "Please specify htseq_files" if args.length == 0
  options
end

def read_coverage(cov_file,groups,out_prefix)
  g = groups.split(",").map { |e| e.to_i }
  file_h = []
  g.each_with_index do |e, i|
    file_h << File.open("#{out_prefix}_group#{i}_upper","w")
    file_h << File.open("#{out_prefix}_group#{i}_middle","w")
    file_h << File.open("#{out_prefix}_group#{i}_lower","w")
  end
  $logger.debug(file_h)
  File.open(cov_file).each do |line|
    line.chomp!
    next if line =~ /chrom/
    fields = line.split("\t")
    position = fields[0..2].join("\t")
    g.each_with_index do |e, i|
      samples = []
      for k in 0...e
        samples << fields[k+3].to_i
      end
      $logger.debug(samples)
      $logger.debug(file_h[i*3])
      file_h[i*3].puts "#{position}\t#{(samples.mean+samples.standard_deviation).round}"
      file_h[i*3+1].puts "#{position}\t#{(samples.mean).round}"
      file_h[i*3+2].puts "#{position}\t#{(samples.mean-samples.standard_deviation).round}"
    end
  end
  g.each_with_index do |e, i|
    file_h[i*3].close
    file_h[i*3+1].close
    file_h[i*3+2].close
  end

end


def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)

  read_coverage(ARGV[0],options[:groups],options[:out_prefix])


end

if __FILE__ == $0
  run(ARGV)
end