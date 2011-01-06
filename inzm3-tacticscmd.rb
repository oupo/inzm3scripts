#!ruby
# encoding: cp932
require_relative "utils.rb"


def read_comamnd_str(str)
	result = []
	str_pos = 0
	while str_pos < str.size
		name = get_cstr(str[str_pos, 2*16])
		i = 2
		while true
			summary = str[str_pos + 2*16, i*16]
			break if summary.index("\0")
			i += 2
		end
		summary = get_cstr(summary).gsub("\n", " ")
		result << [name, summary]
		str_pos += (2+i)*16
	end
	result
end

tacticscmd = read_slice("tacticscmd.dat", 20)
# ���O���؂�Ă���̂Ŏ�Œ�����
#tacticscmd_names = read_comamnd_str(open("tacticscmd.STR", "rb"){|f| f.read })
tacticscmd_names = open("tacticscmd-names.txt", "rb:cp932"){|f| f.read.lines.map{|i| i.chomp} }

type_to_unitcalc_name = {
	1 => "�I�t�F���X��(�K�E�Z)",
	2 => "�I�t�F���X��(�K�E�Z)",
	3 => "�f�B�t�F���X��(�K�E�Z)",
	4 => "�V���[�g(�K�E�Z)"
}

tacticscmd.zip(tacticscmd_names) do |b, name|
	type = read8(b, 0)
	next if type == 0
	puts "<tr><th>#{name}<td>#{read8(b, 3)}<th>#{type_to_unitcalc_name[type]}"
end

