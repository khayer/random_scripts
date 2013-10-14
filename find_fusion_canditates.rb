#!/usr/bin/env ruby
require 'optparse'
require 'logger'

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
  options = {:out_file =>  "fusion_canditates.txt"}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: find_fusion_canditates.rb [options] R1.sam R2.sam"
    opts.separator ""
    opts.separator "sam files aligned to transcriptome, sorted by queryname"

    opts.separator ""
    opts.on("-o", "--out_file [OUT_FILE]",
      :REQUIRED,String,
      "File for the output, Default: fusion_canditates.txt") do |anno_file|
      options[:out_file] = anno_file
    end

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:log_level] = "info"
    end

    opts.on("-d", "--debug", "Run in debug mode") do |v|
      options[:log_level] = "debug"
    end

  end

  args = ["-h"] if args.length == 0
  opt_parser.parse!(args)
  raise "Please specify the sam files" if args.length == 0
  options
end

def skip_header(open_file)
  open_file.each do |line|
    break unless line =~ /^@/
  end
  open_file.lineno = open_file.lineno - 1
end

def read_samfiles(sam_files,out_file)
  fwd = File.open(sam_files[0])
  rev = File.open(sam_files[1])
  out_file_handler = File.open(out_file,'w')
  skip_header(fwd)
  skip_header(rev)
  fwd_info = {}
  fwd_sequences = {}
  rev_info = {}
  rev_sequences = {}
  name = ""
  names = []
  found = false
  fusion = false
  fwd.each do |fwd_line|
    $logger.debug("fwd_line: " + fwd_line)
    fwd_line.chomp!
    fwd_fields = fwd_line.split("\t")
    name = fwd_fields[0] if name == ""
    if fwd_fields[0] != name
      fwd_info.each_pair do |fwd_name, fwd_gene_name|
        rev_name = ""
        rev.each do |rev_line|
          $logger.debug("rev_line: " + rev_line)
          rev_line.chomp!
          rev_fields = rev_line.split("\t")
          rev_sequences[rev_fields[0]]  = rev_line
          rev_name = rev_fields[0] if rev_name == ""
          break if rev_fields[0] != rev_name
          rev_info[rev_fields[0]] = [] unless rev_info[rev_fields[0]]
          rev_info[rev_fields[0]]  << rev_fields[2]
        end
        rev.lineno = rev.lineno - 1

        if rev_info[fwd_name]
          rev_info[fwd_name].each do |gene_name|
            if !fwd_info[fwd_name].include?(gene_name) && !fwd_info[fwd_name].empty?
              fusion = true
              puts "#{fwd_name}\t#{gene_name}\t#{fwd_info[fwd_name].join(",")}"
            else
              found = true
              fwd_info[fwd_name].delete(gene_name)
            end
          end
        else
          $logger.debug("Rev_info[#{fwd_name}] was empty!")
        end

        if found
          fwd_info.delete(fwd_name)
          rev_info.delete(fwd_name)
          fwd_sequences.delete(fwd_name)
          rev_sequences.delete(fwd_name)
        end
        if fusion
          out_file_handler.puts(fwd_sequences[fwd_name])
          out_file_handler.puts(rev_sequences[fwd_name])
          fwd_info.delete(fwd_name)
          rev_info.delete(fwd_name)
          fwd_sequences.delete(fwd_name)
          rev_sequences.delete(fwd_name)
        end
        fusion = false
        found = false
      end
        name = fwd_fields[0]
    end
    fwd_info[fwd_fields[0]] = [] unless fwd_info[fwd_fields[0]]
    fwd_info[fwd_fields[0]]  << fwd_fields[2]
    fwd_sequences[fwd_fields[0]]  = fwd_line
  end
  fwd_info.each_pair do |fwd_name, fwd_gene_name|
    rev_name = ""
    rev.each do |rev_line|
      $logger.debug("rev_line: " + rev_line)
      rev_line.chomp!
      rev_fields = rev_line.split("\t")
      rev_name = rev_fields[0] if rev_name == ""
      break if rev_fields[0] != rev_name
      rev_info[rev_fields[0]] = [] unless rev_info[rev_fields[0]]
      rev_info[rev_fields[0]]  << rev_fields[2]
    end
    rev.lineno = rev.lineno - 1

    if rev_info[fwd_name]
      rev_info[fwd_name].each do |gene_name|
        if !fwd_info[fwd_name].include?(gene_name) && !fwd_info[fwd_name].empty?
          fusion = true
          puts "#{fwd_name}\t#{gene_name}\t#{fwd_info[fwd_name].join(",")}"
        else
          found = true
          fwd_info[fwd_name].delete(gene_name)
        end
      end
    else
      $logger.debug("Rev_info[#{fwd_name}] was empty!")
    end

    if found
      fwd_info.delete(fwd_name)
      rev_info.delete(fwd_name)
      fwd_sequences.delete(fwd_name)
      rev_sequences.delete(fwd_name)
    end
    if fusion
      out_file_handler.puts(fwd_sequences[fwd_name])
      out_file_handler.puts(rev_sequences[fwd_name])
      fwd_info.delete(fwd_name)
      rev_info.delete(fwd_name)
      fwd_sequences.delete(fwd_name)
      rev_sequences.delete(fwd_name)
    end
    fusion = false
    found = false
  end
  $logger.info(fwd_info)
  $logger.info(rev_info)
  $logger.debug(fwd_sequences)
  $logger.debug(rev_sequences)

  fwd_sequences.each_pair do |q_name, line|
    if rev_sequences[q_name]
      out_file_handler.puts(line)
      out_file_handler.puts(rev_sequences[q_name])
      rev_sequences.delete(q_name)
    else
      out_file_handler.puts("### next has no pair")
      out_file_handler.puts(line)

    end
    fwd_sequences.delete(q_name)
  end
  rev_sequences.each_pair do |q_name,line|
    out_file_handler.puts("### next has no pair")
    out_file_handler.puts(line)
    rev_sequences.delete(q_name)
  end
  $logger.info(fwd_info)
  $logger.info(rev_info)
  $logger.debug(fwd_sequences)
  $logger.debug(rev_sequences)
end


def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)

  gene_info = read_samfiles(argv,options[:out_file])

end

if __FILE__ == $0
  run(ARGV)
end

