#!/usr/bin/env ruby
require 'optparse'
require 'logger'
require 'spreadsheet'

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
  options = {:out_file =>  "merged_table.xls", :cut_off => 0,
    :junction_files => ""}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] real.xls sim.xls"
    opts.separator ""
    opts.separator "xls files produced by fusion_table.rb."

    opts.separator ""
    opts.on("-o", "--out_file [OUT_FILE]",
      :REQUIRED,String,
      "File for the output, Default: merged_table.xls") do |anno_file|
      options[:out_file] = anno_file
    end

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:log_level] = "info"
    end

    opts.on("-d", "--debug", "Run in debug mode") do |v|
      options[:log_level] = "debug"
    end

    opts.on("-c", "--cut_off",Integer, "Set cut_off default is no cut off") do |v|
      options[:cut_off] = v
    end

    #opts.on("-j", "--junction_files",:REQUIRED,String, "Comma separated junction list") do |v|
    #  options[:junction_files] = v
    #end
  end

  args = ["-h"] if args.length == 0
  opt_parser.parse!(args)
  raise "Please specify the sam files" if args.length == 0
  options
end

def merge(argv[0],argv[1],options[:out_file],options[:cut_off])
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
    #$logger.debug("#{refseq_1} and #{refseq_2}")
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
    break if i >= cut_off
  end

  book.write out_file
end


def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)

  #puts junctions
  #gene_anno = read_table(argv[1])
  #$logger.debug(gene_anno)
  #$logger.debug(gene_anno["NM_014513"][:chrom])
  merge(argv[0],argv[1],options[:out_file],options[:cut_off])

end

if __FILE__ == $0
  run(ARGV)
end