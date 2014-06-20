#!/usr/bin/env ruby
require 'optparse'
require 'logger'
require 'spreadsheet'
require 'csv'
require 'bio'

$logger = Logger.new(STDERR)
$usage = "Usage: hany.rb [prep/compare]"

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

#def read_annotation(anno_file)
#  gene_info = {}
#  CSV.read(anno_file, { :col_sep => "\t",:headers => :first_row }).each do |row|
#    #puts row
#    #puts row["name2"]
#    gene_info[{:chrom => row["chrom"],:name => row["name"],:txStart => row["txStart"],:txEnd => row["txEnd"]}] = {:chrom => row["chrom"], :strand => row["strand"],
#      :txStart => row["txStart"], :txEnd => row["txEnd"], :name2 => row["name2"],
#      :cdsStart => row["cdsStart"], :cdsEnd => row["cdsEnd"],
#      :exonStarts => row["exonStarts"], :exonEnds => row["exonEnds"],
#      :exonCount => row["exonCount"]}
#  end
#  gene_info
#end
#
#def read_index(fai_file)
#  fai_index = {}
#  File.open(fai_file).each do |line|
#    line.chomp!
#    chr,length,start = line.split("\t")
#    length = length.to_i
#    start = start.to_i
#    bias = length/2
#    fai_index[chr] = {:start => start, :stop => start+length+bias-1}
#  end
#  fai_index
#end
#
#def match_junctions(junctions,gene_info,out_file,membrane_names, fasta)
#  book = Spreadsheet::Workbook.new
#  sheet1 = book.create_worksheet
#  sheet1.row(0).push 'Pos', 'ID', '# Skipped Exons', 'New Exon', 'Within exon',
#    '# reads', 'Refseq ID'
#
#  fai_index = read_index("#{fasta}.fai")
#  $logger.debug("FAI index: #{fai_index}")
#  #fasta_file = File.open("/Users/hayer/Downloads/mm9_ucsc.fa").read
#  fasta_file = File.open(fasta).read  #lines.map {|e| e.strip }.join("")
#  seq_hash = {}
#  fai_index.each_pair do |name, index|
#    seq_hash[name] = fasta_file[index[:start]..index[:stop]].delete("\n")
#  end
#  i = 1
#  #amino_change << Bio::Sequence::NA.new(code).translate
#  tab_file_h = File.open(junctions)
#  out_file_h = File.open(out_file,'w')
#  tab_file_h.each do |line|
#    line.chomp!
#    next unless line =~ /^chr/
#    chrom, chromStart, chromEnd, name, score, strand, thickStart,
#      thickEnd, itemRgb, blockCount, blockSizes, blockStarts = line.split(" ")
#    next if itemRgb == "16,78,139"
#    next unless score.to_i >= 10
#    start = chromStart.to_i + blockSizes.split(",")[0].to_i
#    stop = chromEnd.to_i - blockSizes.split(",")[1].to_i
#    #puts start
#    #puts stop
#    a = gene_info.keys
#    #puts a.length
#    a.keep_if { |v| v[:chrom] == chrom }  #=> ["a", "e"]
#    #puts a.length
#    a.keep_if { |v| v[:txStart].to_i <= start && v[:txEnd].to_i >= stop  }  #=> ["a", "e"]
#    #puts a.length
#
#    novel = false
#    novel_genes = []
#    a.each do |gene_key|
#
#      gene = gene_info[gene_key]
#      #puts gene[:name2]
#      next unless membrane_names.keys.include?(gene[:name2])
#      exonStarts = gene[:exonStarts].split(",").map { |e| e.to_i }
#      exonEnds = gene[:exonEnds].split(",").map { |e| e.to_i }
#
#      novel = true
#      for k in 0...gene[:exonCount].to_i
#        novel = false if exonStarts[k+1] == stop && exonEnds[k] == start
#        break unless novel
#      end
#      novel_genes << gene_key if novel
#      break if novel
#    end
#    next unless novel_genes.length > 0
#    #puts gene_info[novel_genes[0]]
#
#    novel_genes.each do |gene_key|
#      num_skipped_exons = 0
#      new_exon = false
#      within_exon = false
#      gene = gene_info[gene_key]
#      exonStarts = gene[:exonStarts].split(",").map { |e| e.to_i }
#      exonEnds = gene[:exonEnds].split(",").map { |e| e.to_i }
#      if gene[:cdsStart].to_i != gene[:cdsEnd].to_i
#        exonStarts[0] = gene[:cdsStart].to_i
#        exonEnds[-1] = gene[:cdsEnd].to_i
#      else
#        next
#      end
#      sequence_original = ""
#      sequence_novel = ""
#      for k in 0...gene[:exonCount].to_i
#        $logger.debug(chrom)
#        $logger.debug(exonStarts.join("\t"))
#        $logger.debug(exonEnds.join("\t"))
#        sequence_original += seq_hash[chrom][exonStarts[k]...exonEnds[k]]
#        #if exonStarts[k] < start && exonEnds[k] < start
#        #  sequence_novel += seq_hash[chr][exonStarts[k]...exonEnds[k]]
#        #elsif exonStarts[k] < start && exonEnds[k] > start
#        #  sequence_novel += seq_hash[chr][exonStarts[k]...start]
#        #elsif exonEnds[k]
#      end
#      novelStarts_tmp = [exonStarts,stop].flatten.sort
#      novelStops_tmp = [exonEnds,start].flatten.sort
#      novelStarts = []
#      novelStops = []
#      puts "START: #{start}"
#      puts "STOP: #{stop}"
#      puts novelStarts_tmp.join("\t")
#      puts novelStops_tmp.join("\t")
#      for k in 0...novelStarts_tmp.length-1
#        if novelStarts.include?(novelStarts_tmp[k]) || novelStops.include?(novelStops_tmp[k])
#          next
#        else
#          if novelStarts_tmp[k+1] < novelStops_tmp[k] || novelStarts_tmp[k+1] == novelStarts_tmp[k]
#            if novelStarts_tmp[k] == stop
#              novelStarts << novelStarts_tmp[k]
#              novelStops << novelStops_tmp[k]
#            else
#              novelStarts << novelStarts_tmp[k+1]
#              novelStops << novelStops_tmp[k]
#            end
#          elsif novelStops_tmp[k+1] < novelStarts_tmp[k] || novelStops_tmp[k+1] == novelStops_tmp[k]
#            if novelStops_tmp[k] == start
#              novelStarts << novelStarts_tmp[k]
#              novelStops << novelStops_tmp[k]
#            else
#              novelStarts << novelStarts_tmp[k]
#              novelStops << novelStops_tmp[k+1]
#            end
#          else
#            novelStarts << novelStarts_tmp[k]
#            novelStops << novelStops_tmp[k]
#          end
#        end
#      end
#      novelStarts << novelStarts_tmp[-1]
#      novelStops << novelStops_tmp[-1]
#      puts "START: #{start}"
#      puts "STOP: #{stop}"
#      puts "STRAND #{gene[:strand]}"
#      puts novelStarts.join("\t")
#      puts novelStops.join("\t")
#      puts "ORIGINAL:"
#      puts exonStarts.join("\t")
#      puts exonEnds.join("\t")
#      sequence_novel = ""
#      for k in 0...novelStarts.length
#        $logger.debug(chrom)
#        $logger.debug(novelStarts.join("\t"))
#        $logger.debug(novelStops.join("\t"))
#        sequence_novel += seq_hash[chrom][novelStarts[k]...novelStops[k]]
#        #if exonStarts[k] < start && exonEnds[k] < start
#        #  sequence_novel += seq_hash[chr][exonStarts[k]...exonEnds[k]]
#        #elsif exonStarts[k] < start && exonEnds[k] > start
#        #  sequence_novel += seq_hash[chr][exonStarts[k]...start]
#        #elsif exonEnds[k]
#      end
#      if gene[:strand] == "+"
#        puts sequence_novel = Bio::Sequence::NA.new(sequence_novel.split("ATG")[1..-1].join("")).translate
#        puts sequence_original = Bio::Sequence::NA.new(sequence_original.split("ATG")[1..-1].join("")).translate
#      else
#        puts sequence_novel = Bio::Sequence::NA.new(sequence_novel).reverse_complement
#        puts sequence_original = Bio::Sequence::NA.new(sequence_original).reverse_complement
#        puts sequence_novel = Bio::Sequence::NA.new(sequence_novel.split("atg")[1..-1].join("")).translate
#        puts sequence_original = Bio::Sequence::NA.new(sequence_original.split("atg")[1..-1].join("")).translate
#      end
#      STDIN.gets
#
#      if exonStarts.include?(stop) && exonEnds.include?(start)
#        index_stop = exonStarts.index(stop)
#        index_start = exonEnds.index(start)
#        num_skipped_exons = index_stop - index_start - 1
#        $logger.debug("Num of skipped exons: #{num_skipped_exons}")
#      else
#        within_start = false
#        within_stop = false
#        sequence_original = ""
#        for k in 0...gene[:exonCount].to_i
#          within_start = true if exonStarts[k] <= start && exonEnds[k] >= start
#          within_stop = true if exonStarts[k] <= stop && exonEnds[k] >= stop
#          break if within_start && within_stop
#        end
#
#        if within_start && within_stop
#          within_exon = true
#        else
#          new_exon = true
#        end
#      end
#      pos = "#{gene[:chrom]}:#{start}-#{stop}"
#      #sheet1.row(0).push 'Pos', 'ID', '# Skipped Exons', 'New Exon', 'Within exon',
#      #'# reads', 'Refseq ID'
#      sheet1.update_row i, pos, gene[:name2],num_skipped_exons,
#        new_exon, within_exon, score.to_i, gene_key[:name],
#        exonStarts.join(","), exonEnds.join(","), membrane_names[gene[:name2]]
#      i += 1
#      break
#    end
#    #break if i > cut_off
#  end
#  book.write out_file
#end
#
#def read_membrane_file(membrane_file)
#  membrane_names = {}
#  first = true
#  name = ""
#  info = ""
#  File.open(membrane_file).each do |line|
#    line.chomp!
#    if line == "" && !first
#      membrane_names[name] = info
#      #puts membrane_names
#      #STDIN.gets
#      name = ""
#      info = ""
#    else
#      first = false
#      if line =~ /^[0-9]+.\s/
#        name = line.split(" ")[1]
#      else
#        info += line + ";" if line != ""
#      end
#    end
#  end
#  membrane_names
#end
#
#def read_uni_gene(uni_gene)
#  membrane_names = {}
#  first = true
#  name = ""
#  info = ""
#  File.open(uni_gene).each do |line|
#    line.chomp!
#    if line == "" && !first
#      membrane_names[name] = info
#      #puts membrane_names
#      #STDIN.gets
#      name = ""
#      info = ""
#    else
#      first = false
#      if line =~ /^[0-9]+.\s/
#        #name = line.split(" ")[1]
#        info = line
#      end
#      if line =~ /Homo sapiens$/
#        name = line.split(", ")[0]
#        #info += line + ";" if line != ""
#      end
#    end
#  end
#  membrane_names
#end

def matches(cigar)
  numbers = cigar.split(/\D/).map { |e| e.to_i }
  letters = cigar.split(/\d*/).reject { |c| c.empty? }
  all_M = letters.each_index.select{|i| letters[i] == 'M'}
  sum = 0
  all_M.each {|e| sum += numbers[e]}
  sum
end

def read_trans(trans_file)
  trans_hash={}
  name = nil
  pair = []
  File.open(trans_file).each do |line|
    line.chomp!
    next if line =~ /^@/
    fields = line.split("\t")
    next if fields[2] == "*"
    name ||= fields[0]

    if name != fields[0]
      if matches(pair[0][0]) > 90 || matches(pair[1][0]) > 90
        #$logger.debug("NAME = #{name} PAIR = #{pair}")
        trans_hash[name] = pair
      end
      name = fields[0]
      pair = []
    end
    # [CIGAR, SEQUENCE]
    pair << [fields[5], fields[9]]
  end
  trans_hash
end

def run_prep(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)
  #membrane_names = read_membrane_file(options[:membrane_file]) if options[:membrane_file] != ""
  trans_hash = read_trans(argv[0])
  #puts trans_hash
  name = nil
  pair = []
  File.open(argv[1]).each do |line|
    line.chomp!
    next if line =~ /^@/
    next unless line =~ /NH:i:1\s/
    fields = line.split("\t")
    next unless trans_hash[fields[0]]
    name ||= fields[0]
    if name != fields[0]
      if matches(pair[0][0]) > 90 || matches(pair[1][0]) > 90
        #$logger.debug("NAME = #{name} PAIR = #{pair}")
        puts "#{name}\t#{pair.join("\t")}"
      end
      name = fields[0]
      pair = []
    end
    # [CIGAR, SEQUENCE]
    pair << [ fields[5], fields[9], fields[2], fields[3]]
  end
end


def setup_options2(args)
  options = {:out_file =>  "junctions_table.xls", :cut_off => 1000, :membrane_file => ""}
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: hany.rb compare [options] out_hany_prep"
    opts.separator ""
    opts.separator "This script counts the number of unique insertions."
    opts.separator ""

    #opts.on("-o", "--out_file [OUT_FILE]",
    #  :REQUIRED,String,
    #  "File for the output, Default: table.xls") do |anno_file|
    #  options[:out_file] = anno_file
    #end

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
  raise "Please specify input files" if args.length != 1
  options
end

def is_within?(pos_1,pos_2,dis=500000)
  (pos_1.to_i-pos_2.to_i).abs < dis.to_i
end

def run_compare(argv)
  options = setup_options2(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)
  #membrane_names = read_membrane_file(options[:membrane_file]) if options[:membrane_file] != ""
  #trans_hash = read_trans(argv[0])
  #puts trans_hash
  name = nil
  positions = []
  File.open(argv[0]).each do |line|
    line.chomp!


    read_name, cigar_1, seq_1, chr_1, pos_1, cigar_2, seq_2, chr_2, pos_2 = line.split("\t")
    next unless chr_1 == chr_2
    next unless is_within?(pos_1,pos_2)

    accounted = false
    positions.each do |el|
      accounted = (el[0] == chr_1 && is_within?(el[1],pos_1))
      break if accounted
    end
    positions << [chr_1,pos_1] unless accounted
  end
  puts "Num_uniq_insertions:\t#{positions.length}"
  puts "CHR\tPOS"
  positions.sort.each {|e| puts e.join("\t")}
end

if __FILE__ == $0
  unless ARGV.length > 0
    puts $usage
  end
  case ARGV[0]
  when "prep"
    run_prep(ARGV[1..-1])
  when "compare"
    run_compare(ARGV[1..-1])
  end
end
