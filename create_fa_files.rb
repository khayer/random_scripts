#!/usr/bin/env ruby
require 'optparse'
require 'logger'
require 'set'

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
  options = {:out_file =>  "fusion_reads_", :cut_off => 2000}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: create_fa_files.rb [options] fusion_canditates.txt R1_chim.sam R2_chim.sam R1.sam R2.sam top_hits.txt"
    opts.separator ""
    opts.separator "sam files aligned to transcriptome, sorted by queryname"

    opts.separator ""
    opts.on("-o", "--out_prefix [OUT_FILE]",
      :REQUIRED,String,
      "File for the output, Default: fusion_reads_") do |anno_file|
      options[:out_file] = anno_file
    end

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:log_level] = "info"
    end

    opts.on("-d", "--debug", "Run in debug mode") do |v|
      options[:log_level] = "debug"
    end

    opts.on("-c", "--cut_off",Integer, "Set cut_off default is 2000") do |v|
      options[:cut_off] = v
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

#def read_samfiles(r1,r2,fusion_sets)
#  fwd = File.open(r1)
#  rev = File.open(r2)
#
#  skip_header(fwd)
#  skip_header(rev)
#
#  fwd_sequences = {}
#
#  first = true
#  fwd.each do |fwd_line|
#    if first
#      fwd_line.chomp!
#      q_name,d,gene1,d,d,d,gene2,d,d,seq = fwd_line.split("\t")
#      gene1.gsub!(/^hg19_refGene_/,"")
#      gene2.gsub!(/^hg19_refGene_/,"")
#      next if gene1 == gene2
#      s = Set.new [gene1,gene2]
#      next unless fusion_sets.include?(s)
#      fwd_sequences[q_name]=seq
#      first = false
#    else
#      first = true
#    end
#  end
#
#  rev_sequences = {}
#
#  rev.each do |rev_line|
#    if first
#      rev_line.chomp!
#      q_name,d,gene1,d,d,d,gene2,d,d,seq = rev_line.split("\t")
#      gene1.gsub!(/^hg19_refGene_/,"")
#      gene2.gsub!(/^hg19_refGene_/,"")
#      next if gene1 == gene2
#      s = Set.new [gene1,gene2]
#      next unless fusion_sets.include?(s)
#      rev_sequences(q_name)=seq
#      first = false
#    else
#      first = true
#    end
#  end
#  [fwd_sequences, rev_sequences]
#end

def get_sequences(reads,fusion_sets)
  fwd = File.open(reads)
  skip_header(fwd)

  fwd_sequences = {}

  first = true
  fwd.each do |fwd_line|
    if first
      fwd_line.chomp!
      q_name,d,gene1,d,d,d,gene2,d,d,seq = fwd_line.split("\t")
      gene1.gsub!(/^hg19_refGene_/,"")
      gene2.gsub!(/^hg19_refGene_/,"")
      next if gene1 == gene2
      s = Set.new [gene1,gene2]
      next unless fusion_sets.include?(s)
      fwd_sequences[q_name]=seq
      first = false
    else
      first = true
    end
  end
  fwd.close()
  fwd_sequences
end


def get_memory_usage
  `ps -o rss= -p #{Process.pid}`.to_i
end

def fusion_canditates_to_fa(fusion_canditates,out_prefix)
  o1 = File.open("#{out_prefix}R1.fa",'w')
  o2 = File.open("#{out_prefix}R2.fa",'w')

  first = true
  File.open(fusion_canditates).each do |line|
    line.chomp!
    fields = line.split("\t")
    if first
      o1.puts(">#{fields[0]}")
      o1.puts(fields[1])
      first = false
    else
      o2.puts(">#{fields[0]}")
      o2.puts(fields[1])
      first = true
    end
  end
  o1.close
  o2.close
end

def create_fusions_sets(top_hits,cut_off)
  fusion_sets = []
  i = 0
  File.open(top_hits).each do |line|
    line.chomp!
    count,gene1,gene2 = line.split(" ")
    gene1.gsub!(/^hg19_refGene_/,"")
    gene2.gsub!(/^hg19_refGene_/,"")
    next if gene1 == gene2
    #$logger.debug(gene1)
    #$logger.debug(gene2)
    s = Set.new [gene1,gene2]
    fusion_sets << s unless fusion_sets.include?(s)
    i += 1
    break if i > cut_off
  end
  fusion_sets
end

def find_matchting_seq(alinged_sam,sequences,out_prefix,is_fwd)
  o1 = File.open("#{out_prefix}R1.fa",'a')
  o2 = File.open("#{out_prefix}R2.fa",'a')

  sam_file = File.open(alinged_sam)
  skip_header(sam_file)

  fwd_sequences = {}
  sam_file.each do |line|
    line.chomp!
    next unless line =~ /NH:i:1/
    q_name,d,d,d,d,d,d,d,d,seq = line.split("\t")
    if sequences.include?(q_name)
      if is_fwd
        o1.puts(">#{qname}")
        o1.puts(seq)
        o2.puts(">#{qname}")
        o2.puts(sequences[qname])
      else
        o2.puts(">#{qname}")
        o2.puts(seq)
        o1.puts(">#{qname}")
        o1.puts(sequences[qname])
      end
    end
  end
  o1.close
  o2.close
end


def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)
  before = get_memory_usage
  #print "BEFORE: " + before.to_s
  $logger.info("BEFORE: " + before.to_s + " (in 1024 Bytes)")

  #fusion_canditates.txt R1_chim.sam R2_chim.sam R1.sam R2.sam top_hits.txt
  fusion_canditates_to_fa(argv[0],options[:out_file])

  fusion_sets = create_fusions_sets(argv[5],options[:cut_off])
  #fwd_sequences, rev_sequences = read_samfiles(argv[1],argv[2],fusion_sets)
  fwd_sequences = get_sequences(argv[1],fusion_sets)
  find_matchting_seq(argv[4],fwd_sequences,options[:out_file],false)
  fwd_sequences = nil
  rev_sequences = get_sequences(argv[2],fusion_sets)
  find_matchting_seq(argv[3],rev_sequences,options[:out_file],true)
  after = get_memory_usage
  #print "AFTER: " + (after-before).to_s
  $logger.info("AFTER: " + (after-before).to_s + " (in 1024 Bytes)")
end

if __FILE__ == $0
  run(ARGV)
end

