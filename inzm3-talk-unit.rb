#!ruby
# encoding: cp932

require "set"
require_relative "utils.rb"
require_relative "inzm3-utils.rb"

def dump_simple()
	unitbase_dat = read_slice("unitbase.dat", 104)
	unitbase_dat.each do |b|
		unitno = read_short(b, 0x4e)
		name = get_cstr(b, 28)
		
		sym = hastalkfile?(unitno) ? "*" : " "
		
		puts "#{sym}#{name}"
	end
end

# �j�b�N�l�[�������ł͎�������p�Z���t�����邩�ǂ����𔻕ʂł��Ȃ��I�肽�����o��
def dump_ambiguous_units()
	name_to_units = gen_name_to_units()
	
	name_to_units.each do |name, unitnos|
		bools = unitnos.map {|unitno| hastalkfile?(unitno) }
		if bools.include?(true) and bools.include?(false)
			print "#{name}: "
			puts unitnos.map {|unitno| [unitno, hastalkfile?(unitno), get_way_scout(unitno)] }.inspect
		end
	end
end

def dump_for_js()
	name_to_units = gen_name_to_units()
	
	unitnames1 = []
	unitnames2 = []
	
	
	name_to_units.each do |name, unitnos|
		bools = unitnos.map {|unitno| hastalkfile?(unitno) }
		if bools.all? {|x| x == true }
			unitnames1 << name
		elsif bools.all? {|x| x == false }
			unitnames2 << name
		else
			$stderr.puts "ambiguous unit: #{name}"
		end
	end
	
	puts "var UNITNAME_RE_HASTALKFILE = /^#{regexp_asseble(unitnames1)}$/;"
	puts "var UNITNAME_RE_NOTHASTALKFILE = /^#{regexp_asseble(unitnames2)}$/;"
end

def regexp_asseble(strs)
	encoded_strs = strs.map{|x| x.encode("utf-8") }
	IO.popen(["perl", "-e", <<-EOS, *encoded_strs], "rb:utf-8"){|io| io.read.encode("cp932") }
use utf8;
use Encode;
use Regexp::Assemble;
print(encode('UTF-8', Regexp::Assemble->new->add(map { decode('UTF-8', $_) } @ARGV)->as_string));
	EOS
end


def gen_name_to_units()
	unitbase_dat = read_slice("unitbase.dat", 104)
	result = {}
	unitbase_dat.each do |b|
		unitno = read_short(b, 0x4e)
		name = get_cstr(b, 28)
		next if unitno == 0
		next if (3931..3946).include?(unitno) # �S���z���C�c�A�~�����b�Y�̑I�肽�������O
		next if get_way_scout(unitno) == 252 # ���ԕs�����O
		(result[name] ||= []).push(unitno)
	end
	result
end