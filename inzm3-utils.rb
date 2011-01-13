# encoding: cp932
require_relative "utils.rb"

def init_unitbase
	return if @unitbase_dat
	@unitbase_dat = read_slice("unitbase.dat", 104)

	# unitnoからunitbase.datインデックスへ
	@unitno_to_index = []
	@unitbase_dat.each_with_index do |b, unitbase_index|
		unitno = read_short(b, 0x4e)
		@unitno_to_index[unitno] = unitbase_index
	end
end

def get_unit_name(unitno)
	init_unitbase()
	unitbase = get_unitbase(unitno)
	get_cstr(unitbase, 28)
end

def get_unitbase(unitno)
	@unitbase_dat[@unitno_to_index[unitno]]
end

def init_way_scout
	return if @unitno_to_way_scout
	usearch_dat = read_slice("usearch.dat", 44)
	
	@unitno_to_way_scout = []
	usearch_dat.each do |b|
		unitno = read_short(b, 0x24)
		way_scout = read_byte(b, 0x26)
		
		@unitno_to_way_scout[unitno] = way_scout
	end
end

def get_way_scout(unitno)
	init_way_scout()
	@unitno_to_way_scout[unitno]
end

def init_hastalkfile
	return if @unitno_to_hastalkfile
	eve_pkh = read_pkh(readfile("eve.pkh"))
	@unitno_to_hastalkfile = []
	eve_pkh.each do |e|
		if e.value / 10000 == 3700
			@unitno_to_hastalkfile[e.value - 37000000] = true
		end
	end
end

def hastalkfile?(unitno)
	init_hastalkfile()
	!!@unitno_to_hastalkfile[unitno]
end

PkhEntry = Struct.new(:value, :pkb_pos, :pkb_length)

def read_pkh(binary)
	length = read16(binary, 22)
	result = []
	length.times do |i|
		pos = 48 + i * 12
		result << PkhEntry.new(read32(binary, pos), read32(binary, pos + 4), read32(binary, pos + 8))
	end
	result
end
