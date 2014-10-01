require 'csv'

def read_mapping_stats(file)
  mio_reads = {}
  #id totalreads  UniqueFWDandREV UniqueFWDorREV  UniqueChrM  %overlap  Non-UniqueFWDandREV Non-UniqueFWDorREV  FWDorREVmapped
  CSV.foreach(file,:col_sep => "\t", :headers => true) do |ps|
    id = ps["id"].gsub(/_NSS$/,"")
    #puts id
    num = ps["UniqueChrM"].delete(",").to_i
    mio_reads[id] = num
  end
  mio_reads
end

mio_reads = read_mapping_stats("/project/itmatlab/emanuela/kat_run_aug14/mappingstats_summary_merged.txt")

puts mio_reads["Sample_9574"]
puts mio_reads["Sample_9575"]
puts mio_reads["Sample_9578"]
puts mio_reads["Sample_9579"]
puts mio_reads["Sample_9580"]
puts mio_reads["Sample_9581"]
puts mio_reads["Sample_9582"]
puts mio_reads["Sample_9583"]

chrM_files = ["/project/itmatlab/emanuela/kat_run_aug14/chrM_pool/Sample_4731_chrM.sam",
  "/project/itmatlab/emanuela/kat_run_aug14/chrM_pool/Sample_4722_chrM.sam"]

File.open("/project/itmatlab/emanuela/kat_run_aug14/chrM_pool/new/names_file2.txt").each do |line|
  line.chomp!
  name = line.split(".")[0]
  shell = File.open("/project/itmatlab/emanuela/kat_run_aug14/chrM_pool/#{name}.sh",'w')
  out_file_spikes = "/project/itmatlab/emanuela/kat_run_aug14/chrM_pool/for_#{name}.sam"
  chrM_file = chrM_files[rand(2)]
  num = mio_reads[name]*2
  shell.puts "head -#{num} #{chrM_file} > #{out_file_spikes}"
  in_sam = "/project/itmatlab/emanuela/kat_run_aug14/out/#{name}/Aligned.out.sam"
  out_sam = "/project/itmatlab/emanuela/kat_run_aug14/chrM_pool/new/#{name}.sam"
  shell.puts "cat #{in_sam} #{out_file_spikes} > #{out_sam}"
  out_bam = "/project/itmatlab/emanuela/kat_run_aug14/chrM_pool/new/#{name}.bam"
  shell.puts "samtools view -bS #{out_sam} > #{out_bam}"
  out_R = "/project/itmatlab/emanuela/kat_run_aug14/chrM_pool/new/#{name}.Rdata"
  shell.puts "~/tools/R-3.1.0/bin/Rscript /project/itmatlab/emanuela/kat_run_aug14/chrM_pool/new/run_summarizeOverlaps.R #{out_bam} #{out_R}"
  shell.close
  `bsub -q max_mem30 bash /project/itmatlab/emanuela/kat_run_aug14/chrM_pool/#{name}.sh`
end

#irb(main):025:0> puts mio_reads["Sample_9574"]
#936799
#=> nil
#irb(main):026:0> puts mio_reads["Sample_9575"]
#516288
#=> nil
#irb(main):027:0> puts mio_reads["Sample_9578"]
#697773
#=> nil
#irb(main):028:0> puts mio_reads["Sample_9579"]
#601391
#=> nil
#irb(main):029:0> puts mio_reads["Sample_9580"]
#1005589
#=> nil
#irb(main):030:0> puts mio_reads["Sample_9581"]
#688704
#=> nil
#irb(main):031:0> puts mio_reads["Sample_9582"]
#856960
#=> nil
#irb(main):032:0> puts mio_reads["Sample_9583"]
#877152
#=> nil
