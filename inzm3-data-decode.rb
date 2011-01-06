require_relative "utils.rb"

# thanks: http://hp.vector.co.jp/authors/VA018359/inazuma3hack.txt
def decode_bytes!(buf)
	buf.size.times do |i|
		c = buf.getbyte(i)
		c = c ^ 0xad
		2.times do
			c = (c << 7 | c >> 1) & 0xff
		end
		buf.setbyte(i, c)
	end

	(0...buf.size-2).step(3) do |i|
		swap buf, i, i+2
	end
	(0...buf.size-4).step(5) do |i|
		swap buf, i, i+4
	end
	(0...buf.size-6).step(7) do |i|
		swap buf, i, i+6
	end
	(0...buf.size-1).step(2) do |i|
		swap buf, i, i+1
	end
end

def swap(buf, i, j)
	t = buf.getbyte(i)
	buf.setbyte(i, buf.getbyte(j))
	buf.setbyte(j, t)
end

def decode_file(path, block_size)
	result = []
	open(path, "rb") do |f|
		until f.eof?
			buf = f.read(block_size)
			decode_bytes! buf
			result << buf
		end
	end
	result
end
