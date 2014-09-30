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
