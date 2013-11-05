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
  options = {:out_file =>  "gc_content.txt"}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] gtf_file fasta_file"
    opts.separator ""
    opts.separator "calculates gc content for each gene."

    opts.separator ""
    opts.on("-o", "--out_file [OUT_FILE]",
      :REQUIRED,String,
      "File for the output, Default: gc_content.txt") do |anno_file|
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

def add_gene(gene_info,name,chromosome,starts,stops)
  gene_info[name] = {:chr => chromosome, :starts => starts,
    :stops => stops, :gc_content => 0.5}
end


def read_gtf_file(gtf_file)
  gene_info = {}
  last_name = nil
  starts = []
  stops = []
  chromosome = nil
  identifier = ""
  File.open(gtf_file).each do |line|
    line.chomp!
    next unless line =~ /exon/
    chr,d,d,start,stop,d,d,d,identifier = line.split("\t")
    identifier = /\w*-\w*/.match(identifier)[0]
    last_name = identifier unless last_name
    if last_name != identifier
      add_gene(gene_info,last_name,chromosome,starts,stops)
      starts = []
      stops = []
      last_name = identifier
    end
    starts << start.to_i
    stops << stop.to_i
    chromosome = chr

  end
  add_gene(gene_info,identifier,chromosome,starts,stops)
  gene_info
end

def read_index(fai_file)
  fai_index = {}
  File.open(fai_file).each do |line|
    line.chomp!
    chr,length,start = line.split("\t")
    length = length.to_i
    start = start.to_i
    fai_index[chr] = {:start => start, :stop => start+length-1}
  end
  fai_index
end

def calculate_gc_content(fai_index,fasta_file,info)
  sequence = ""

  info[:starts].each_with_index do |start,i|
    sequence += fasta_file[fai_index[info[:chr]][:start]..fai_index[info[:chr]][:stop]][start..info[:stops][i]]
  end
  gc_count = sequence.count("GgCc")
  gc_content = gc_count/sequence.length.to_f
end

def get_gene_length(info)
  length = 0
  info[:starts].each_with_index do |start,i|
    length += info[:stops][i] - start
  end
  length
end

def process(gene_info,fasta_file,outfile)
  fai_index = read_index("#{fasta_file}.fai")
  puts "\tlength\tgccontent"
  fasta_file = File.open(fasta_file).read
  i = 0
  gene_info.each_pair do |id, info|
    $logger.debug("Processed #{i} id's") if i % 1000 == 0
    i += 1
    gc_content = calculate_gc_content(fai_index,fasta_file,info)
    length = get_gene_length(info)
    outfile.puts "#{id}\t#{length}\t#{gc_content}"
  end
end

def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)
  $logger.debug("Reading gtf file")
  gene_info = read_gtf_file(argv[0])
  $logger.debug("Processing ...")
  outfile = File.open(options[:out_file], "w")
  gene_info = process(gene_info,argv[1],outfile)

end

if __FILE__ == $0
  run(ARGV)
end
