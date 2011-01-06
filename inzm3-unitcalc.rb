#!ruby
# encoding: cp932
require_relative "utils.rb"

@unitcalc = read_slice("unitcalc.dat", 32)

@names = [
[1, "�I�t�F���X��"],
[3, "�f�B�t�F���X��"],
[25, "�I�t�F���X��(�K�E�Z)"],
[27, "�f�B�t�F���X��(�K�E�Z)"],
[4, "�V���[�g"],
[5, "���[�v�V���[�g"],
[6, "�{���[�V���[�g�E�w�f�B���O"],
[9, "�V���[�g(�K�E�Z)"],
[8, "�L�[�p�[(�\���p)"],
[7, "�L�[�p�["],
[10, "�L�[�p�[(�K�E�Z)"],
#[15, "�p�X"],
#[31, "�H"],
[11, "���荇��1"],
[12, "���荇��2"],
[13, "���荇���ŃL�[�v���邩"],
[28, "�V���[�g�u���b�N"],
[32, "�V���[�g�u���b�N(�V���[�g�Z)"],
]

def simple_dump
	@unitcalc.each_with_index do |b, pos|
		# 04, 06, 1a �� unsigned
		names = %w(���E �{�� �����̕� �o�[�j���O�t�F�[�Y ? �З� �L�b�N �{�f�B �K�[�h �R���g���[�� �X�s�[�h �K�b�c �X�^�~�i flags)
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
