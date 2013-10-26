#!/usr/bin/env ruby
require 'optparse'
require 'logger'
require 'spreadsheet'
require "csv"
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
  options = {:out_file =>  "fusion_canditates_table.xls", :cut_off => 1000,
    :junction_files => ""}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: fusion_table.rb [options] fusion_canditates.txt hg19_refseq_genes_anno"
    opts.separator ""
    opts.separator "sam files aligned to transcriptome, sorted by queryname"

    opts.separator ""
    opts.on("-o", "--out_file [OUT_FILE]",
      :REQUIRED,String,
      "File for the output, Default: fusion_canditates_table.xls") do |anno_file|
      options[:out_file] = anno_file
    end

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:log_level] = "info"
    end

    opts.on("-d", "--debug", "Run in debug mode") do |v|
      options[:log_level] = "debug"
    end

    opts.on("-c", "--cut_off",:REQUIRED, Integer, "Set cut_off default is 1000") do |v|
      options[:cut_off] = v
    end

    opts.on("-j", "--junction_files",:REQUIRED,String, "Comma separated junction list") do |v|
      options[:junction_files] = v
    end
  end

  args = ["-h"] if args.length == 0
  opt_parser.parse!(args)
  raise "Please specify the sam files" if args.length == 0
  options
end

def make_link(gene_name)
  link = "http://cancer.sanger.ac.uk/cosmic/gene/overview?ln=#{gene_name}"
end

def read_table(anno_file)
  gene_anno = {}
  CSV.read(anno_file, { :col_sep => "\t",:headers => :first_row }).each do |row|
    gene_anno[row["name"]] = {:chrom => row["chrom"], :strand => row["strand"],
      :txStart => row["txStart"], :txEnd => row["txEnd"], :name2 => row["name2"]}
  end
  gene_anno
end

def find_junctions(junction_files)
  junctions = {}
  junction_files.split(",").each do |file|
    #puts file
    File.open(file).each do |line|
      line.chomp!
      gene1,d,d,gene2 = line.split("\t")
      gene1.gsub!(/^hg19_refGene_/,"")
      gene2.gsub!(/^hg19_refGene_/,"")
      next if gene1 == gene2
      #$logger.debug(gene1)
      #$logger.debug(gene2)
      s = Set.new [gene1,gene2]
      junctions[s] = 0 unless  junctions[s]
      junctions[s] += 1
    end

  end
  junctions
end

def read_summary(fusion_table,out_file,gene_anno,cut_off,junctions)
  book = Spreadsheet::Workbook.new
  sheet1 = book.create_worksheet
  sheet1.row(0).push 'Counts', 'Gen sym 1', 'Pos 1', 'Gen sym 2',
    'Pos 2', 'Refseq 1', 'Refseq 2', 'Junctions?'
  i = 1

  tab_file_h = File.open(fusion_table)
  out_file_h = File.open(out_file,'w')
  tab_file_h.each do |line|
    line.chomp!
    next if line == ""
    counts, refseq_1, refseq_2 = line.split(" ")
    refseq_2.gsub!(/^hg19_refGene_/,"")
    refseq_1.gsub!(/^hg19_refGene_/,"")
    $logger.debug("#{refseq_1} and #{refseq_2}")
    gene_sym_1 = gene_anno[refseq_1][:name2]
    gene_sym_1_link = make_link(gene_sym_1)
    gene_sym_2 = gene_anno[refseq_2][:name2]
    gene_sym_2_link = make_link(gene_sym_2)

    if junctions
      s = Set.new [refseq_1,refseq_2]
      junc = junctions[s]
    else
      junc = "n/a"
    end
    pos1 = "#{gene_anno[refseq_1][:chrom]}:#{gene_anno[refseq_1][:txStart]}-#{gene_anno[refseq_1][:txEnd]}"
    pos2 = "#{gene_anno[refseq_2][:chrom]}:#{gene_anno[refseq_2][:txStart]}-#{gene_anno[refseq_2][:txEnd]}"
    sheet1.update_row i, counts, Spreadsheet::Link.new(gene_sym_1_link,gene_sym_1),
      pos1,Spreadsheet::Link.new(gene_sym_2_link,gene_sym_2), pos2, refseq_1,
      refseq_2, junc
    i += 1
    break if i > cut_off
  end

  book.write out_file
end


def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)
  #puts options[:cut_off]
  if options[:junction_files] != ""
    junctions = find_junctions(options[:junction_files])
  else
    junctions = nil
  end
  #puts junctions
  gene_anno = read_table(argv[1])
  #$logger.debug(gene_anno)
  #$logger.debug(gene_anno["NM_014513"][:chrom])
  #puts options[:cut_off]
  read_summary(argv[0],options[:out_file],gene_anno,options[:cut_off],junctions)

end

if __FILE__ == $0
  run(ARGV)
end

