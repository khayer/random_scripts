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
    @filehandle.pos = pos_in_file
    seen = 0
    @filehandle.each do |line|
      line.chomp!
      fields = line.split("\t")
      puts line
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

g = GTF.new("/Users/kat/Box Sync/emanuela/mm9_anno/mm9_ensembl_ucsc_patched.gtf")
g.create_index()
puts g.filename
puts g.index
puts "HERE"
puts g.transcript("ENSMUST00000175395")
