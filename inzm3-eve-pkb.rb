#!ruby
require_relative "utils.rb"

def extract_bytes(src)
	dest_size = read32(src, 0) >> 8
	flag = (read32(src, 0) & 0xf) != 0
	src_pos = 4
	
	dest = "\0" * dest_size
	dest_pos = 0
	
	while dest_pos < dest_size
		flags = read8(src, src_pos)
		src_pos += 1
		
		8.times do |i|
			if (flags >> (7-i) & 1) == 0
				write8 dest, dest_pos, read8(src, src_pos)
				src_pos += 1
				dest_pos += 1
			else
				b = read8(src, src_pos)
				copy_length = 0
				if not flag
					copy_length = 3
				else
					if (b & 0xe0) != 0
						copy_length = 1
					else
						src_pos += 1
						copy_length = (b & 0xf) << 4
						if (b & 0x10) != 0
							copy_length = (copy_length << 8) + (read8(src, src_pos) << 4) + 0x100
							src_pos += 1
						end
						copy_length += 0x11
						b = read8(src, src_pos)
					end
				end
				copy_length += (b >> 4)
				src_pos += 1
				offset = (read8(src, src_pos) | (b & 0xf) << 8) + 1
				src_pos += 1
				copy_length.times do
					write8 dest, dest_pos, read8(dest, dest_pos - offset)
					dest_pos += 1
				end
			end
			break if dest_pos >= dest_size
		end
	end
	dest
end

EvePkhEntry = Struct.new(:value, :pkb_pos, :pkb_length)

def read_eve_pkh(binary)
	length = read16(binary, 22)
	result = []
	length.times do |i|
		pos = 48 + i * 12
		result << EvePkhEntry.new(read32(binary, pos), read32(binary, pos + 4), read32(binary, pos + 8))
	end
	result
end

eve_pkh = read_eve_pkh(open("eve.pkh", "rb"){|f| f.read})
eve_pkb = open("eve.pkb", "rb"){|f| f.read}

eve_pkh.each do |e|
	path = "eve.pkh-dump/%.8x" % e.value
	open(path, "wb") do |f|
		src = eve_pkb[e.pkb_pos, e.pkb_length]
		f.write extract_bytes(src)
	end
	puts "extracted #{path}"
end
