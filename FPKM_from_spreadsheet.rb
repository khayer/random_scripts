require "csv"

def fpkm(fragment,length_transcript,number_mio_of_reads=50)
  ((fragment.to_f/(length_transcript.to_f/1000))/number_mio_of_reads.to_f).to_f
  #(fragment.to_f/number_mio_of_reads.to_f).to_f
end

def calc_length(transcript)
  length = 0
  #logger.debug(transcript.join("::"))
  (0..transcript.length-1).step(2).to_a.each do |i|
    length += transcript[i+1]-transcript[i]
  end
  length
end

class GTF

  def initialize(filename)
    @filename = filename
    @index = Hash.new()
    @filehandle = File.open(@filename)
    @coverage = Hash.new()
  end

  attr_accessor :coverage, :index, :filehandle, :filename

  def create_index()
    raise "#{@filename} is already indexed" unless @index == {}
    #logger.info("Creating index for #{@filename}")
    @filehandle.rewind
    previous_position = 0
    @filehandle.each do |line|
      line.chomp!
      #next if line =~ /cov "0.000000"/
      next unless line =~ /\sexon\s/
      fields = line.split("\t")
      id = fields[-1].split("gene_id ")[1].split(";")[0].delete("\"")
      @index[id] = previous_position unless @index[id]
      previous_position = @filehandle.pos
    end
    #logger.info("Indexing of #{@index.length} transcripts complete")
  end

  def transcript(key)
    transcript = []
    pos_in_file = @index[key]
    #puts key
    @filehandle.pos = pos_in_file
    seen = 0
    @filehandle.each do |line|
      line.chomp!
      fields = line.split("\t")
      #puts line
      id = fields[-1].split("gene_id ")[1].split(";")[0].delete("\"")
      break if id != key && seen == 1
      next unless line =~ /\sexon\s/
      if id == key
        transcript << fields[3].to_i-1
        transcript << fields[4].to_i
        seen  = 1
      end
    end
    transcript.sort!
  end
end

def read_mapping_stats(file)
  mio_reads = {}
  #id totalreads  UniqueFWDandREV UniqueFWDorREV  UniqueChrM  %overlap  Non-UniqueFWDandREV Non-UniqueFWDorREV  FWDorREVmapped
  CSV.foreach(file,:col_sep => "\t", :headers => true) do |ps|
    id = ps["id"].gsub(/_NSS$/,"")
    #puts id
    num = ps["UniqueFWDandREV"].delete(",").to_f / 1000000
    mio_reads[id] = num
  end
  mio_reads
end
g = GTF.new("/Users/hayer/Box Sync/emanuela/mm9_anno/Mus_musculus.NCBIM37.62.gtf")
#g = GTF.new("/Users/hayer/Box Sync/emanuela/mm9_anno/mm9_ensembl_ucsc_patched.gtf")
g.create_index()
#puts g.filename
#puts g.index
#puts "HERE"
#puts g.transcript("ENSMUST00000072177")

mio_reads = read_mapping_stats("/Users/hayer/Box Sync/emanuela/mappingstats_summary_merged.txt")
#puts mio_reads
first = true
sample_names = []
CSV.foreach("/Users/hayer/Box Sync/emanuela/FINAL_master_list_of_genes_counts_MIN.BATCH.UNNORMALIZED.txt",:col_sep => "\t") do |ps|
#CSV.foreach("/Users/hayer/Box Sync/emanuela/not_normalized.csv") do |ps|
  ps.map { |e| e.delete("\"") }
  if first
    ps.each do |k|
      sample_names << k.split(".")[0].gsub(/_NSS$/,"")
    end
    puts sample_names.join(",")
    first = false
    next
  end
  gene_id = ps[0].gsub(/^gene:/,"")
  fpkms  = [gene_id]
  for i in (1..16).to_a
    length_transcript = calc_length(g.transcript(gene_id))
    fpkms << fpkm(ps[i],length_transcript,mio_reads[sample_names[i]])
  end
  puts fpkms.join(",")
end



