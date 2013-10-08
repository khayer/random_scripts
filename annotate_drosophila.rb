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
      "fbgn_annotation_ID_fb_2013_05.tsv (ftp://ftp.flybase.net/releases/current/precomputed_files/genes/fbgn_annotation_ID_fb_2013_05.tsv.gz)") do |gtf_file|
      options[:gtf_file] = gtf_file
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

def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)

  #genes = get_genes(options[:gtf_file])
#
  #all_fpkm_values = all_fpkm(argv,genes)
#
  #feature, rep, val = format_groups(options[:groups])
  #all_p_values = p_values(all_fpkm_values,feature,val)
#
  #all_with_q_values = q_values(all_p_values)
  #all_with_q_values.each_pair do |key,value|
  #  puts "#{key}\t#{value.join("\t")}\t#{all_fpkm_values[key].join("\t")}"
  #end
end

if __FILE__ == $0
  run(ARGV)
end

