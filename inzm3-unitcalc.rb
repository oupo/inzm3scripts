#!ruby
# encoding: cp932
require_relative "utils.rb"

@unitcalc = read_slice("unitcalc.dat", 32)

@names = [
[1, "オフェンス側"],
[3, "ディフェンス側"],
[25, "オフェンス側(必殺技)"],
[27, "ディフェンス側(必殺技)"],
[4, "シュート"],
[5, "ループシュート"],
[6, "ボレーシュート・ヘディング"],
[9, "シュート(必殺技)"],
[8, "キーパー(表示用)"],
[7, "キーパー"],
[10, "キーパー(必殺技)"],
#[15, "パス"],
#[31, "？"],
[11, "競り合い1"],
[12, "競り合い2"],
[13, "競り合いでキープするか"],
[28, "シュートブロック"],
[32, "シュートブロック(シュート技)"],
]

def simple_dump
	@unitcalc.each_with_index do |b, pos|
		# 04, 06, 1a が unsigned
		names = %w(限界 倍率 乱数の幅 バーニングフェーズ ? 威力 キック ボディ ガード コントロール スピード ガッツ スタミナ flags)
		puts "#{pos}:"
		names.each_with_index do |name, i|
			v = read16s(b, i * 2)
			puts " %.2x(%s)=%d" % [i * 2, name, v]
		end
		puts 13.times.map{|i| "<td>" + read16s(b, i * 2).to_s }.join("")
	end
end

def dump_table
	columns = [0..5, 6..13]
	column_name = %w(limit magnification random_width burning_phase shoot_power power kick body guard control speed guts stamina flags)
	
	columns.each do |col|
		puts "<table>"
		print "<tr><th>"
		col.each{|i| print "<th>#{column_name[i]}" }
		puts
		
		@names.each do |(pos, name)|
			print "<tr><th>#{name}"
			b = @unitcalc[pos]
			col.each do |i|
				v = read16s(b, i * 2)
				print "<td>#{v}"
			end
			puts
		end
		puts "</table>"
		puts
	end
end

dump_table
