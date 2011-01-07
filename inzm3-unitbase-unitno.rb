#!ruby
# encoding: cp932

require_relative "utils.rb"

unitbase_dat = read_slice("unitbase.dat", 104)
unitno_dat = open("unitno.dat", "rb"){|f| f.read.unpack("v*") }


reverse_unitno = []
unitno_dat.each_with_index do |i, unitbase_index|
	(reverse_unitno[i] ||= []) << unitbase_index
end

# unitno.datはunitbase.dat+0x4eと同じらしい。なあんだ
def dump_unitbase
	offset = [0x4e, 0x50, 0x56]
	unitbase_dat.each_with_index do |b, index|
		ids = offset.map{|i| read_short(b, i) }
		unless ids.all?{|id| id == ids[0] }
			puts "%s: %d,%s,%s" % [get_cstr(b, 28), index, ids.join(","), unitno_dat[index]]
		end
	end
end


reverse_unitno.each_with_index do |ids, i|
	unless ids
		puts "none"
		next
	end
	
	next if i == 0
	puts get_cstr(unitbase_dat[ids[0]], 28)
end

if false
reverse_unitno.each_with_index do |ids, i|
	puts "%d: [%s]" % [i, ids.map{|id|
		unitbase_dat[id] ? "%s (%d)" % [get_cstr(unitbase_dat[id], 28), id] : id
	}.join(",")]
end
end
