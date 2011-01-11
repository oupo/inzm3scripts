#!ruby
# encoding: cp932
require_relative "utils.rb"

# マップ名の文字列プールへのオフセットがどっかにないか探してみたけど見当たらなかった
def search_string_offset
	base = open("eve.pkh-dump/0216ab64", "rb"){|f| f.read }
	table = Array.new(base.size / 2, true)
	Dir["eve.pkh-dump/*"].each do |path|
		b = open(path, "rb") {|f| f.read }
		next unless b.index("MAPINIT_ENCTABLE")
		ok = path != "eve.pkh-dump/0216ab00" && valid_mapname(get_cstr(b, 0x650))
		if ok
			puts "#{path}: #{get_cstr(b, 0x650)}"
		end
		table.size.times do |i|
			next if not table[i]
			if i * 2 + 1 >= b.size
				table[i] = false
				next
			end
			if ok # okのときはbaseと値が一致してなければならない
				table[i] = false unless read16(base, i * 2) == read16(b, i * 2)
			else # okでないときはbaseと値が不一致でなければならない
				table[i] = false unless read16(base, i * 2) != read16(b, i * 2)
			end
		end
	end
	table.size.times do |i|
		if table[i]
			puts "%d: %.4x" % [i * 2, read16(base, i * 2)]
		end
	end
end

def valid_mapname(bytes)
	/\A(?:[\x81-\x9f\xe0-\xef][\x40-\x7e\x80-\xfc])+\z/n =~ bytes
end

# eve.pkb内の各ファイルからマップ名とエンカウントインデックスの対応を調べる
# eve.pkb内の各ファイルの構造は調べてないのでいい加減
def dump_mapname_encount
	mapnames = {}
	open("SCRIPTINFOMAP.TXT", "rb:c932") do |f|
		f.each_line do |line|
			/^(\w+)\.mbld, (.+)$/ =~ line.chomp
			mapnames[$1] = $2
		end
	end

	Dir["eve.pkh-dump/*"].each do |path|
		b = open(path, "rb"){|f| f.read}
		mark = "■MAPINIT_MINIMAP\0".force_encoding("ascii-8bit")
		index = b.index(mark)
		next unless index
		index += (mark.length + 3) / 4 * 4 + 4
		#encount_index = read32(b, 0x2d4) # スパーク
		encount_index = read32(b, 0x2d8) # ジ・オーガ
		filename = get_cstr(b, index)
		index += ([(filename + "\0").length, 5].max + 3) / 4 * 4 + 4
		map_name = get_cstr(b, index)
		id = filename[/^[^_]+/]
		puts "#{path}: #{filename},#{map_name},#{mapnames[id]},#{encount_index}"
	end
end

dump_mapname_encount
