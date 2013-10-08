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
    opts.banner = "Usage: anova.rb [options] anova_result"
    opts.separator ""
    opts.separator "anova_result (from anova.rb):"
    opts.separator "\tgene\tp_value\tq_value\tfpkm_values*"
    opts.separator "\tCG9989-RA\t0.373\t0.431\t0.1\t0.3\tetc."
    opts.separator ""
    opts.on("-a", "--annotation_file [ANNO_FILE]",
      :REQUIRED,String,
      "fbgn_annotation_ID_fb_2013_05.tsv") do |anno_file|
      options[:anno_file] = anno_file
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
  raise "Please specify a anova_result file" if args.length == 0
  options
end

def read_annotation(anno_file)
  gene_info = {}
  File.open(anno_file, "r").each do |line|
    line.chomp!
    next unless line =~ /CG/
    gene_symbol, primary_FBgn, secondary_FBgn, annotation_ID =
      line.split("\t")
    $logger.debug(gene_symbol)
    gene_info[annotation_ID] = gene_symbol
  end
  gene_info
  $logger.debug(gene_info)
end

def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)

  gene_info = read_annotation(options[:anno_file])
end

if __FILE__ == $0
  run(ARGV)
end

