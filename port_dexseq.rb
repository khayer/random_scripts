#!/usr/bin/env ruby
require 'optparse'
require 'logger'
require "csv"


$logger = Logger.new(STDERR)
$usage = "Usage: port_dexseq.rb port_out dexseq_out"

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
  options = {:out_file =>  "junctions_table.xls", :cut_off => 1000, :membrane_file => ""}
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: hany.rb prep [options] trans.sam malaria.sam"
    opts.separator ""
    opts.separator "This script summarizes all reads mapping to both transcriptome and"
    opts.separator "the malaria genome."
    opts.separator ""

    opts.on("-o", "--out_file [OUT_FILE]",
      :REQUIRED,String,
      "File for the output, Default: table.xls") do |anno_file|
      options[:out_file] = anno_file
    end

    #opts.on("-m", "--mebrane_file [MEMBRANE_FILE]",
    #  :REQUIRED,String,
    #  "Text with membrane genes.") do |anno_file|
    #  options[:membrane_file] = anno_file
    #end

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:log_level] = "info"
    end

    opts.on("-d", "--debug", "Run in debug mode") do |v|
      options[:log_level] = "debug"
    end

    #opts.on("-c", "--cut_off",:REQUIRED, Integer, "Set cut_off default is 1000") do |v|
    #  options[:cut_off] = v
    #end

  end

  args = ["-h"] if args.length == 0
  opt_parser.parse!(args)
  raise "Please specify input files" if args.length != 2
  options
end

def read_port(file)
  genes_port = {}
  #feature type  chromosome  start end mean control  mean IL q-value fold  symbol  description ucsc_id
  CSV.read(file, { :col_sep => "\t",:headers => :first_row }).each do |row|
    genes_port[[row["chromosome"],row["start"].to_i,row["end"].to_i]] = row["fold"].to_f
  end
  genes_port
end

def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)




  genes_port = read_port(argv[0])
  #puts genes_port[["chr11",83461346,83462859]] == 422.75
  genes_dexseq = {}


  #"groupID" "featureID" "exonBaseMean"  "dispersion"  "stat"  "pvalue "padj"  "control" "IL1b"  "log2fold_control_IL1b" "genomicData.seqnames"  "genomicData.start" "genomicData.end" "genomicData.width" "genomicData.strand"  "countData.4146_IL1b" "countData.4147_IL1b" "countData.4148_IL1b" "countData.4149_IL1b" "countData.4783_control"  "countData.4784_control"  "countData.4786_control"  "countData.4787_control"  "transcripts"
  CSV.read(argv[1], { :col_sep => "@",:headers => :first_row }).each do |row|
    k = row["log2fold_IL_control"].to_f
    next if k == 0.0
    #puts k
    genes_dexseq[[row["genomicData.seqnames"],row["genomicData.start"].to_i,row["genomicData.end"].to_i]] = 2.0 ** k
  end

  #File.open(argv[1], "r").each { |io|  puts io }

  #puts genes_dexseq
  #puts genes_dexseq[["chr11",83461346,83462859]] #== 1.1294926122229985
  genes_port.each_pair do |key,value|
    if genes_dexseq[key]
      puts "#{key.join("\t")}\t#{value}\t#{genes_dexseq[key]}"
    end
end

if __FILE__ == $0
  run(ARGV)
end