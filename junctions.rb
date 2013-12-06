#!/usr/bin/env ruby
require 'optparse'
require 'logger'
require 'spreadsheet'
require 'csv'

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
  options = {:out_file =>  "junctions_table.xls", :cut_off => 1000, :mebrane_file => ""}
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: junctions.rb [options] junctions.bed hg19_refseq_genes_anno.gtf"
    opts.separator ""
    opts.on("-o", "--out_file [OUT_FILE]",
      :REQUIRED,String,
      "File for the output, Default: junctions_canditates_table.xls") do |anno_file|
      options[:out_file] = anno_file
    end

    opts.on("-m", "--mebrane_file [MEMBRANE_FILE]",
      :REQUIRED,String,
      "Text with membrane genes.") do |anno_file|
      options[:membrane_file] = anno_file
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

  end

  args = ["-h"] if args.length == 0
  opt_parser.parse!(args)
  raise "Please specify input files" if args.length != 2
  options
end

def read_annotation(anno_file)
  gene_info = {}
  CSV.read(anno_file, { :col_sep => "\t",:headers => :first_row }).each do |row|
    #puts row
    #puts row["name2"]
    gene_info[{:chrom => row["chrom"],:name => row["name"],:txStart => row["txStart"],:txEnd => row["txEnd"]}] = {:chrom => row["chrom"], :strand => row["strand"],
      :txStart => row["txStart"], :txEnd => row["txEnd"], :name2 => row["name2"],
      :exonStarts => row["exonStarts"], :exonEnds => row["exonEnds"],
      :exonCount => row["exonCount"]}
  end
  gene_info
end

def match_junctions(junctions,gene_info,out_file)
  book = Spreadsheet::Workbook.new
  sheet1 = book.create_worksheet
  sheet1.row(0).push 'Pos', 'ID', '# Skipped Exons', 'New Exon', 'Within exon',
    '# reads', 'Refseq ID'
  i = 1

  tab_file_h = File.open(junctions)
  out_file_h = File.open(out_file,'w')
  tab_file_h.each do |line|
    line.chomp!
    next unless line =~ /^chr/
    chrom, chromStart, chromEnd, name, score, strand, thickStart,
      thickEnd, itemRgb, blockCount, blockSizes, blockStarts = line.split(" ")
    next if itemRgb == "16,78,139"
    next unless score.to_i >= 10
    start = chromStart.to_i + blockSizes.split(",")[0].to_i
    stop = chromEnd.to_i - blockSizes.split(",")[1].to_i
    #puts start
    #puts stop
    a = gene_info.keys
    #puts a.length
    a.keep_if { |v| v[:chrom] == chrom }  #=> ["a", "e"]
    #puts a.length
    a.keep_if { |v| v[:txStart].to_i <= start && v[:txEnd].to_i >= stop  }  #=> ["a", "e"]
    #puts a.length

    novel = false
    novel_genes = []
    a.each do |gene_key|
      gene = gene_info[gene_key]
      exonStarts = gene[:exonStarts].split(",").map { |e| e.to_i }
      exonEnds = gene[:exonEnds].split(",").map { |e| e.to_i }
      novel = true
      for k in 0...gene[:exonCount].to_i
        novel = false if exonStarts[k+1] == stop && exonEnds[k] == start
        break unless novel
      end
      novel_genes << gene_key if novel

    end
    next unless novel_genes.length > 0
    #puts gene_info[novel_genes[0]]

    novel_genes.each do |gene_key|
      num_skipped_exons = 0
      new_exon = false
      within_exon = false
      gene = gene_info[gene_key]
      exonStarts = gene[:exonStarts].split(",").map { |e| e.to_i }
      exonEnds = gene[:exonEnds].split(",").map { |e| e.to_i }
      if exonStarts.include?(stop) && exonEnds.include?(start)
        index_stop = exonStarts.index(stop)
        index_start = exonEnds.index(start)
        num_skipped_exons = index_stop - index_start - 1
        $logger.debug("Num of skipped exons: #{num_skipped_exons}")
      else
        within_start = false
        within_stop = false
        for k in 0...gene[:exonCount].to_i
          within_start = true if exonStarts[k] <= start && exonEnds[k] >= start
          within_stop = true if exonStarts[k] <= stop && exonEnds[k] >= stop
          break if within_start && within_stop
        end

        if within_start && within_stop
          within_exon = true
        else
          new_exon = true
        end
      end
      pos = "#{gene[:chrom]}:#{start}-#{stop}"
      #sheet1.row(0).push 'Pos', 'ID', '# Skipped Exons', 'New Exon', 'Within exon',
      #'# reads', 'Refseq ID'
      sheet1.update_row i, pos, gene[:name2],num_skipped_exons,
        new_exon, within_exon, score.to_i, gene_key[:name],
        exonStarts.join(","), exonEnds.join(",")
      i += 1
    end

    #break if i > cut_off
  end

  book.write out_file
end

def read_membrane_file(mebrane_file)
  membrane_names = {}

  File.open(mebrane_file).each do |line|
    if line == "" && !first
      membrane_names[name] = info
      name = ""
      info = ""
    end
  end
  membrane_names
end

def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)

  membrane_names = read_membrane_file(options[:mebrane_file]) if options[:mebrane_file] != ""

  gene_info = read_annotation(argv[1])
  match_junctions(argv[0],gene_info,options[:out_file])
end

if __FILE__ == $0
  run(ARGV)
end
