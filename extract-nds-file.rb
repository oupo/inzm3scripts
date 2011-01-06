#!ruby

def main(nds_path, filelist_path, virtual_file_path)
	file_path_re = Regexp.compile("\\A#{virtual_file_path}\\z")

	infos = []
	open(filelist_path, "rb") do |f|
		f.each_line do |line|
			next unless /^ +\d+ 0x([0-9A-F]+) 0x[0-9A-F]+ +(\d+) ([^\r\n]+)/ =~ line
			offset, len, fname = $1.to_i(16), $2.to_i, $3
			if file_path_re =~ fname
				infos << {:offset => offset, :len => len, :fname => fname}
			end
		end
	end

	if infos.size == 0
		puts "not found"
		exit
	end

	infos.each do |i|
		open(nds_path, "rb") do |f|
			f.pos = i[:offset]
			open(File.basename(i[:fname]), "wb") do |wf|
				wf.write f.read(i[:len])
			end
			puts "#{i[:fname]} extracted"
		end
	end
end

if $0 == __FILE__
	if ARGV.size != 3
		$stderr.puts "usage: ruby #$0 <nds_path> <filelist_path> <virtual_file_path>"
		exit 1
	end
	main *ARGV
end
