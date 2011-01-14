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

# ニックネームだけでは試合中専用セリフがあるかどうかを判別できない選手たちを出力
def dump_ambiguous_units()
	name_to_units = gen_name_to_units()
	
	name_to_units.each do |name, unitnos|
		bools = unitnos.map {|unitno| hastalkfile?(unitno) }
			if bools.include?(true) and bools.include?(false) and
			   not (bools.count(false) == 1 and not can_scout(unitnos[bools.index(false)]))
			print "#{name}: "
			puts unitnos.map {|unitno| [unitno, hastalkfile?(unitno), get_way_scout(unitno)] }.inspect
		end
	end
end

def dump_for_js()
	name_to_units = gen_name_to_units()
	
	unitnames_hastalkfile = []
	unitnames_nothastalkfile = []
	
	
	name_to_units.each do |name, unitnos|
		bools = unitnos.map {|unitno| hastalkfile?(unitno) }
		if bools.include?(true)
			if bools.include?(false) and
			   not (bools.count(false) == 1 and not can_scout(unitnos[bools.index(false)]))
				$stderr.puts "ambiguous unit: #{name}"
			end
			hastalkfile = true
		else
			hastalkfile = false
		end
		
		if unitnos.any?{|unitno| not can_scout(unitno) }
			$stderr.puts "can't scout: #{name} #{hastalkfile}"
		end
		
		(hastalkfile ? unitnames_hastalkfile : unitnames_nothastalkfile) << name
	end
	
	puts "var UNITNAME_RE_HASTALKFILE = /^#{regexp_asseble(unitnames_hastalkfile)}$/;"
	puts "var UNITNAME_RE_NOTHASTALKFILE = /^#{regexp_asseble(unitnames_nothastalkfile)}$/;"
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
		(result[name] ||= []).push(unitno)
	end
	result
end

def can_scout(unitno)
		return false if (3931..3946).include?(unitno) # 鬼道ホワイツ、円堂レッズの選手たち
		return false if get_way_scout(unitno) == 252 # 仲間不可
		true
end
