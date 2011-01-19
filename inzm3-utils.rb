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

def init_item_names
	return if @item_names
	@item_names = decode_file("item.dat", 44).map{|b| get_cstr(b, 0) }
end

def get_item_name(item_id)
	init_item_names()
	@item_names[item_id]
end

def init_games
	return if @games_dat
	@games_dat = read_slice("games.dat", 48)
	@team_pkb = read_slice("team.pkb", 352)

	@team_pkh = open("team.pkh", "rb") {|f|
		f.pos = 48
		f.read.unpack("V*")
	}
end

def game_id_to_team_name(game_id)
	init_games()
	game = @games_dat[game_id]
	team_id = read_short(game, 0)
	team_index = @team_pkh.index(team_id)
	team = @team_pkb[team_index]
	
	get_cstr(team, 0)
end

