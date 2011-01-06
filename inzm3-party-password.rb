#!ruby

CHAR_TABLE = ["0".."9", "a".."z", "A".."Z"].map{|i|i.to_a}.flatten - ["l", "o", "I", "O"]
KEY = "IZ3IntegrationPassKey"

def main()
	unitnos = [1, 2, 11, 3]
	levels = [1, 1, 1, 1]
	password = encode_data(unitnos, levels)
	puts password
	p decode_data(password)
end

def encode_data(unitnos, levels)
	bytes = unit_data_to_bytes(unitnos, levels)
	crypt_bytes!(bytes, KEY)
	encode_bytes(bytes)
end

def decode_data(password)
	bytes = decode_bytes(password)
	decrypt_bytes!(bytes, KEY)
	bytes_to_unit_data(bytes)
end

def unit_data_to_bytes(unitnos, levels)
	builder = BitsBuilder.new
	unitnos.each do |unitno|
		builder.append(unitno, 12)
	end
	levels.each do |level|
		builder.append(level, 7)
	end
	bytes = builder.to_bytes
	bytes.fill(0, bytes.length...16)
	bytes
end

def bytes_to_unit_data(bytes)
	reader = BitsReader.new(bytes)
	num_units = 4
	unitnos = []
	levels = []
	num_units.times do
		unitnos << reader.read(12)
	end
	num_units.times do
		levels << reader.read(7)
	end
	[unitnos, levels]
end

KEY_XORMASK = 0x62d3
SEED_BASE = 0x05888f27
SEED_SWAP = 0x014a76e0

def crypt_bytes!(bytes, key_str)
	length = bytes.length
	data_crc = crc16(bytes, length - 2)
	key_crc = crc16(key_str.bytes.to_a)
	
	key = KEY_XORMASK ^ data_crc ^ key_crc
	
	bytes[length - 2] = key & 0xff
	bytes[length - 1] = key >> 8
	
	prng = PRNG.new
	prng.srand SEED_BASE + key
	
	(length - 2).times do |i|
		bytes[i] ^= prng.rand() >> 24
	end
	
	prng.srand SEED_SWAP
	array_swap bytes, length - 2, prng.rand() % (length - 2)
end

def decrypt_bytes!(bytes, key_str)
	length = bytes.length
	key_crc = crc16(key_str.bytes.to_a)
	
	prng = PRNG.new
	prng.srand SEED_SWAP
	array_swap bytes, length - 2, prng.rand() % (length - 2)
	
	key = bytes[length - 2] | bytes[length - 1] << 8
	expected_data_crc = key ^ key_crc ^ KEY_XORMASK
	
	prng.srand SEED_BASE + key
	(length - 2).times do |i|
		bytes[i] ^= prng.rand() >> 24
	end
	
	data_crc = crc16(bytes, length - 2)
	
	if data_crc != expected_data_crc
		raise "crc error (got: %.4x, expected: %.4x)" % [data_crc, expected_data_crc]
	end
end



def encode_bytes(bytes)
	table = CHAR_TABLE
	num_chars = 11
	
	result = ""
	(bytes.size / 8).times do |i|
		val = bytes_to_u64(bytes, i * 8)
		num_chars.times do
			result << table[val % table.size]
			val /= table.size
		end
	end
	result
end

def decode_bytes(str)
	table = CHAR_TABLE
	num_chars = 11
	
	result = []
	all_chars = str.chars.to_a
	(all_chars.length / num_chars).times do |i|
		chars = all_chars[i * num_chars, num_chars]
		val = 0
		chars.reverse_each do |char|
			val = val * table.size + table.index(char)
		end
		bytes = u64_to_bytes(val)
		result << bytes
	end
	result.flatten
end

def bytes_to_u64(bytes, pos)
	num = 0
	8.times do |i|
		num = num << 8 | bytes[pos+7-i]
	end
	num
end

def u64_to_bytes(num)
	bytes = []
	8.times do |i|
		bytes[i] = num >> (8*i) & 0xff
	end
	bytes
end

class BitsBuilder
	def initialize
		@value = 0
		@length = 0
	end
	
	def append(val, nbits)
		@value |= val << @length
		@length += nbits
		self
	end
	
	def to_bytes
		bytes = []
		(0...@length).step(8) do |i|
			bytes << (@value >> i & 0xff)
		end
		bytes
	end
end

class BitsReader
	def initialize(bytes)
		@bytes = bytes
		@pos = 0
	end
	
	def read(nbits)
		val = 0
		nbits.times do |i|
			val = val << 1 | read_bit(@pos + nbits - 1 - i)
		end
		@pos += nbits
		val
	end
	
	private
	def read_bit(pos)
		@bytes[pos / 8] >> (pos % 8) & 1
	end
end

def crc16(bytes, len=bytes.length)
	result = 0xffff
	len.times do |i|
		result ^= bytes[i] << 8
		8.times do
			if (result & 0x8000) != 0
				result = ((result << 1) ^ 0x1021) & 0xffff
			else
				result = (result << 1) & 0xffff
			end
		end
	end
	result ^ 0xffff
end

class PRNG
	def initialize
		@seed = 0
	end
	
	def srand(seed)
		@seed = seed
	end
	
	def rand
		@seed = (@seed * 0x021fc436 + 1) & 0xffffffff
		@seed
	end
end

def array_swap(array, i, j)
	t = array[i]
	array[i] = array[j]
	array[j] = t
end

if $0 == __FILE__
	main()
end
