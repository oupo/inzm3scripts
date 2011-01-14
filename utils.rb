def read_byte(buf, index)
	buf.getbyte(index)
end

def read_short(buf, index)
	buf.getbyte(index) | buf.getbyte(index + 1) << 8
end

def read_long(buf, index)
	buf.getbyte(index) |
	buf.getbyte(index + 1) << 8 |
	buf.getbyte(index + 2) << 16 |
	buf.getbyte(index + 3) << 24
end

def read_short_signed(buf, index)
	val = read_short(buf, index)
	val >= 0x8000 ? val-0x10000 : val
end

def read_long_signed(buf, index)
	val = read_long(buf, index)
	val >= 0x80000000 ? val-0x100000000 : val
end

def write_byte(buf, index, val)
	buf.setbyte(index    , val)
end

def write_short(buf, index, val)
	buf.setbyte(index    , val       & 0xff)
	buf.setbyte(index + 1, val >>  8 & 0xff)
end

def write_long(buf, index, val)
	buf.setbyte(index    , val      & 0xff)
	buf.setbyte(index + 1, val >>  8 & 0xff)
	buf.setbyte(index + 2, val >> 16 & 0xff)
	buf.setbyte(index + 3, val >> 24 & 0xff)
end

alias read8 read_byte
alias read16 read_short
alias read32 read_long
alias read16s read_short_signed
alias read32s read_long_signed

alias write8 write_byte
alias write16 write_short
alias write32 write_long

def get_cstr(str, pos=0)
	str[pos...(str.index("\0", pos) || str.size)].force_encoding("cp932")
end

# Shift_JISŒn‚Ì•¶š—ñ‚ğ•¶š‚ÌƒoƒCƒg’· = •¶š‚Ì•‚Æ‚µ‚Äljust‚·‚é
def sjis_ljust(str, width)
	enc = str.encoding
	str.dup.force_encoding("ascii-8bit").ljust(width).force_encoding(enc)
end

def read_slice(path, block_size)
	result = []
	open(path, "rb") do |f|
		until f.eof?
			result << f.read(block_size)
		end
	end
	result
end

def readfile(path)
	open(path, "rb"){|f| f.read }
end

def dump_binary(bytes)
	bytes = bytes.bytes if bytes.respond_to?(:bytes)
	bytes.map{|i|"%.2x" % i}.join(" ")
end

def dump_binary_long(buf)
	buf.bytes.each_slice(16).map{|block|
		block.map{|i|"%.2x" % i}.join(" ")
	}.join("\n")
end

def dump_binary_with_ruler(binary)
	r = "    " + (0..15).map{|i| "%02x" % i }.join(" ") + "\n"
	binary.bytes.each_slice(16).with_index do |line, i|
		r << "%02x| " % (i * 16)
		r << line.map {|byte| "%02x" % byte }.join(" ") + "\n"
	end
	r
end

def search_binary_offset(binaries, intsize)
	int_bytesize = (intsize / 8)
	hit = Array.new(binaries[0].size / int_bytesize, true)
	binaries.each_with_index do |binary, index|
		expected = yield(index)
		next unless expected
		(binary.size / int_bytesize).times do |i|
			byte = send("read#{intsize}", binary, i * int_bytesize)
			if byte != expected
				hit[i] = false
			end
		end
	end
	hit.each_with_index.select{|v, i| v }.map{|v, i| i * int_bytesize }
end
