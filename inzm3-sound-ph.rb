#!ruby

SoundPh = Struct.new(:data, :is_fileinfo, :back_reference, :fileinfo_indicies)

def gen_sound_ph(binary)
	data = binary.unpack("V*")
	is_fileinfo = Array.new(data.size, false)
	back_reference = Array.new(data.size, nil)
	fileinfo_indicies = []
	
	data.each_with_index do |e,i|
		if (e & (1<<31)) != 0
			index = (e & ~(1<<31)) / 4
			is_fileinfo[index] = true
			is_fileinfo[index + 1] = true
			is_fileinfo[index + 2] = true
			fileinfo_indicies << index
			append_elem back_reference, index, i
		end
	end
	
	data.each_with_index do |e,i|
		next if (e & (1<<31)) != 0
		next if is_fileinfo[i]
		append_elem back_reference, e & 0xffff, i
		append_elem back_reference, e >> 16, i
	end
	
	fileinfo_indicies.sort!
	fileinfo_indicies.uniq!
	
	SoundPh.new(data, is_fileinfo, back_reference, fileinfo_indicies)
end

def search(sound_ph, filename_crc32)
	data = sound_ph.data
	key = filename_crc32
	pos = 0
	32.times do |i|
		v = data[pos]
		puts "pos = %3d, v = %.8x" % [pos, v]
		if (v & (1<<31)) != 0
			return (v & ~(1<<31)) / 4
		end
		if (key & 1) != 0
			pos = v >> 16
		else
			pos = v & 0xffff
		end
		key >>= 1
	end
	return nil
end

def dump_sound_ph(sound_ph)
	sound_ph.data.each_with_index do |e, i|
		note = ""
		ref = sound_ph.back_reference[i]
		if (e & (1<<31)) != 0
			note = " (%5d)" % ((e & ~(1<<31)) / 4)
		elsif sound_ph.is_fileinfo[i]
			note = " *"
		end
		if ref
			note += " (ref:"+ref.join(", ")+")"
		end
		puts "%5d: %.8x%s" % [i, e, note]
	end
end

TraceResult = Struct.new(:pass, :binary)

def trace_reference(sound_ph, index, way)
	ref = sound_ph.back_reference[index]
	return [TraceResult.new([index], [way].compact)] if not ref or index == 0
	
	result = nil
	ref.each do |i|
		r = trace_reference(sound_ph, i, get_way(sound_ph.data[i], index))
		r.each do |e|
			e.pass << index
			e.binary << way if way
		end
		if result
			r.each{|e| result << e }
		else
			result = r
		end
	end
	result
end

def get_way(val, index)
	if (val & (1<<31)) != 0
		return nil
	elsif (val >> 16) == index
		return 1
	elsif (val & 0xffff) == index
		return 0
	else
		raise "bug! way not fonud (val = %.8x, index = %d)" % [val, index]
	end
end

def show_all_binary(sound_ph, files_trie)
	sound_ph.fileinfo_indicies.each do |index|
		results = trace_reference(sound_ph, index, nil)
		if results.size == 1
			result = results[0]
		else
			if index != 1639
				raise "trace results size > 1 (size = %d, index = %d)" % [size, index]
			end
			result = results.find{|e| e.pass[0] == 0 }
		end
		crc32_fragment = result.binary.reverse.join("")
		filenames = search_filename_by_crc32_fragment(files_trie, crc32_fragment)
		sound_pb_offset = sound_ph.data[index]
		filesize = sound_ph.data[index + 1]
		puts "%s: %5d %s%s" % [index, filesize, crc32_fragment, filenames.size > 0 ? " (" + filenames.join(", ") + ")" : ""]
	end
end

def search_filename_by_crc32_fragment(files_trie, crc32_fragment)
	fragment = crc32_fragment.to_i(2)
	t = files_trie
	crc32_fragment.size.times do |i|
		v = (fragment >> i) & 1
		t = t[v]
		return [] unless t
	end
	collect_trie_filenames(t)
end

def collect_trie_filenames(t)
	if t == nil
		[]
	elsif t.kind_of?(Pair)
		collect_trie_filenames(t[0]) + collect_trie_filenames(t[1])
	else
		t
	end
end

Pair = Struct.new(:first, :second)

def gen_trie_by_filenames(filenames)
	trie = Pair.new
	filenames.each do |filename|
		crc32 = calc_crc32(filename.bytes)
		append_trie trie, crc32, filename
	end
	trie
end

def append_trie(trie, crc32, filename)
	t = trie
	32.times do |i|
		v = (crc32 >> i) & 1
		if i == 31
			append_elem t, v, filename
		else
			t = (t[v] ||= Pair.new)
		end
	end
end

def calc_crc32(bytes)
	poly = 0xedb88320
	char_bit = 8
	
	r = 0xffffffff
	bytes.each do |b|
		r ^= b
		char_bit.times do |i|
			if (r & 1) != 0
				r = (r >> 1) ^ poly
			else
				r >>= 1
			end
		end
	end
	r ^ 0xffffffff
end

def append_elem(ary, index, val)
	(ary[index] ||= []) << val
end

filenames = (begin
  open("sound-ph-filenames.txt", "rb") {|f| f.lines.map{|i| i.chomp } }
rescue Errno::ENOENT
  %w(m301.smw m302.smw m303.smw) # part
end)


files_trie = gen_trie_by_filenames(filenames)

sound_ph_binary = open("sound.ph", "rb"){|f| f.read }
sound_ph = gen_sound_ph(sound_ph_binary)
show_all_binary sound_ph, files_trie

