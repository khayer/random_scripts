#!/usr/bin/env ruby
require 'optparse'
require 'logger'
require 'spreadsheet'
require 'set'

$logger = Logger.new(STDERR)
$index_file = ""

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
    opts.banner = "Usage: #{$0} [options] real.xls sim.xls index_file"
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

  args = ["-h"] if args.length < 3
  opt_parser.parse!(args)
  raise "Please specify the sam files" if args.length == 0
  options
end

def run_bl2seq(gene1,gene2)
  name1 = `grep #{gene1} #{$index_file}`.split(" ")[0].delete(">")
  $logger.debug("name1 #{name1}")
  name2 = `grep #{gene2} #{$index_file}`.split(" ")[0].delete(">")
  #gene1 = "hg19_refGene_#{gene1}"
  #gene2 = "hg19_refGene_#{gene2}"
  gene1 = name1.split("|").join("\|")
  $logger.debug("gene1 #{gene1}")
  gene2 = name1.split("|").join("\|")
  `samtools faidx #{$index_file} #{gene1} > tmp1.fa`
  `samtools faidx #{$index_file} #{gene2} > tmp2.fa`
  out = `bl2seq -F F -i tmp1.fa -j tmp2.fa -p blastn -D 1`
  score = ""
  identities = ""
  expect = ""
  alignment_length = ""
  out.split("\n").each do |line|
    line.chomp!
    next if line =~ /^#/
    fields = line.split("\t")
    score = fields[-1].to_f
    identities = fields[2].to_f
    expect = fields[-2].to_f
    alignment_length = fields[3].to_i
    break
  end
  [expect, identities,score,  alignment_length]
end


def merge(real,sim,out_file,cut_off)
  book = Spreadsheet::Workbook.new
  bold = Spreadsheet::Format.new :weight => :bold
  grey = Spreadsheet::Format.new :pattern_fg_color => :grey, :pattern => 1
  sheet1 = book.create_worksheet
  sheet1.row(0).push 'Counts', 'Gen sym 1', 'Pos 1', 'Gen sym 2',
    'Pos 2', 'Refseq 1', 'Refseq 2', 'Junctions?', 'E-value', 'Identity',
    'Bit Score', 'Ali Length'
  i = 1


  book_sim = Spreadsheet.open(sim)
  sheet_sim = book_sim.worksheet 0

  info = {}
  sheet_sim.each 1 do |row|
    #puts row[5]
    #puts row[6]
    s = Set.new [row[5],row[6]]
    info[s] = row
  end

  book_real = Spreadsheet.open(real)
  sheet_real = book_real.worksheet 0

  i = 1
  sheet_real.each 1 do |row|
    s = Set.new [row[5],row[6]]

    expect, identities,score,  alignment_length = run_bl2seq(row[5].to_s,row[6].to_s)
    if info.include?(s)
      sheet1.row(i).default_format = grey
      #sheet1.row(i).set_format(grey)
      sheet1.update_row i, row[0],row[1],row[2],row[3],row[4],row[5],
        row[6],row[7],expect, identities,score,  alignment_length,
        info[s][0],info[s][1],info[s][2],info[s][3],info[s][4],info[s][7]
    else
      sheet1.update_row i, row[0],row[1],row[2],row[3],row[4],row[5],
        row[6],row[7],expect, identities,score,  alignment_length
    end
    i += 1
  end



  #tab_file_h.each do |line|
  #  line.chomp!
  #  next if line == ""
  #  counts, refseq_1, refseq_2 = line.split(" ")
  #  refseq_2.gsub!(/^hg19_refGene_/,"")
  #  refseq_1.gsub!(/^hg19_refGene_/,"")
  #  #$logger.debug("#{refseq_1} and #{refseq_2}")
  #  gene_sym_1 = gene_anno[refseq_1][:name2]
  #  gene_sym_1_link = make_link(gene_sym_1)
  #  gene_sym_2 = gene_anno[refseq_2][:name2]
  #  gene_sym_2_link = make_link(gene_sym_2)
#
  #  if junctions
  #    s = Set.new [refseq_1,refseq_2]
  #    junc = junctions[s]
  #  else
  #    junc = "n/a"
  #  end
  #  pos1 = "#{gene_anno[refseq_1][:chrom]}:#{gene_anno[refseq_1][:txStart]}-#{gene_anno[refseq_1][:txEnd]}"
  #  pos2 = "#{gene_anno[refseq_2][:chrom]}:#{gene_anno[refseq_2][:txStart]}-#{gene_anno[refseq_2][:txEnd]}"
  #  sheet1.update_row i, counts, Spreadsheet::Link.new(gene_sym_1_link,gene_sym_1),
  #    pos1,Spreadsheet::Link.new(gene_sym_2_link,gene_sym_2), pos2, refseq_1,
  #    refseq_2, junc
  #  i += 1
  #  break if i >= cut_off
  #end
  #out_file = File.open(out,'w')
  book.write out_file
  #out_file.close()
end


def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)
  $index_file = argv[2]

  #puts junctions
  #gene_anno = read_table(argv[1])
  #$logger.debug(gene_anno)
  #$logger.debug(gene_anno["NM_014513"][:chrom])
  merge(argv[0],argv[1],options[:out_file],options[:cut_off])

end

if __FILE__ == $0
  run(ARGV)
end