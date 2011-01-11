#!ruby
# encoding: cp932
require_relative "utils.rb"

def read_string_pool(buf)
	pc = 0x20
	num_blocks = read16(buf, 0xc)
	num_strings = read16(buf, 0xe)
	string_pool = 0x20 + read32(buf, 0x10)
	block_count = 0
	string_count = 0
	result = []

	while block_count < num_blocks and string_count < num_strings
		label = read16(buf, pc + 0)
		while string_count < num_strings and label == read16(buf, string_pool + 0)
			arg_index = read8(buf, string_pool + 2) - 1
			length = read8(buf, string_pool + 3)
			result[label] ||= []
			str = buf[string_pool + 4, length - 4].force_encoding("cp932")
			result[label][arg_index] = str
			
			string_count += 1
			string_pool += length
		end
		pc += read16(buf, pc + 2)
		block_count += 1
	end
	result
end

TYPE_NAMES = {
	0x7001 => "write",
	0x7010 => "rand",
	0x3070 => "debug_print",
}

def disasm_script(buf)
	string_pool = read_string_pool(buf)
	num_blocks = read16(buf, 0xc)
	pc = 0x20
	
	num_blocks.times do |i|
		label = read16(buf, pc + 0)
		size = read16(buf, pc + 2)
		type = read16(buf, pc + 4)
		name = TYPE_NAMES[type]
		
		args = dump_args(buf, pc, string_pool)
		
		puts "block#%d: label=%.4x, size=%d, type=%.4x%s, args=[%s]" %
		      [i, label, size, type, name ? " (#{name})" : "", args.join(", ")]
		pc += size
	end
end

def get_string_from_pool(string_pool, label, arg_index)
	string_pool[label] && string_pool[label][arg_index]
end

def dump_args(buf, pc, string_pool)
	label = read16(buf, pc + 0)
	nargs = read8(buf, pc + 6)
	pos = pc + 8 + ((nargs + 7) / 8) * 4
	r = []
	nargs.times do |i|
		type = (read32(buf, pc + 8 + (i / 8 * 4)) >> (i % 8 * 4)) & 0xf
		x = read32(buf, pos + i * 4)
		case type
		when 1, 2, 3
			str = get_string_from_pool(string_pool, label, i)
			if str
				r.push str.inspect
			else
				r.push "%.8x" % x
			end
		when 4
			r.push "expr#%.4x" % x
		when 5
			r.push "var#%.5x" % x
		when 6
			r.push "varaddr#%.5x" % x
		else
			r.push "unknown"
		end
	end
	r
end
