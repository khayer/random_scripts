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

