# module of functions for translating files
require 'pg'
DB ||= PG::Connection.new(dbname: 'sivers', user: 'sivers')

module Tr8
	# INPUT: filename of original
	# Puts translation lines into PostgreSQL database
	# OUTPUT: ARRAY with template text, Gengo translate text, reference file for later matching
	def parse(infilename)
		alllines = []
		txnlines = []
		reflines = []
		File.readlines(infilename).each do |line|
			line.rstrip!
			puts "seeing #{line}"
			if line[0] == "\t"
				code = en2code(line.strip)
				alllines << '{%s}' % code
				txnlines << line.strip
				reflines << "%s\t%s" % [code, line.strip]
			else
				alllines << line
			end
		end
		[alllines.join("\n"), txnlines.join("\r\n"), reflines.join("\n")]
	end

	def unparse(template_filename, lang)
		newlines = []
		File.readlines(template_filename).each do |line|
			line.strip!
			if m = /\{([A-Za-z0-9]{8})\}/.match(line)
				newlines << line.gsub(m[0], code2lang(m[1], lang))
			else
				newlines << line
			end
		end
		newlines.join("\n")
	end

	# INPUT: English
	# Inserts it into the PostgreSQL database
	# OUTPUT: code : primary key
	def en2code(en)
		res = DB.exec_params("INSERT INTO translations(en) VALUES ($1) RETURNING code", [en.strip])
		raise "ERROR WITH #{en}" unless /[A-Za-z0-9]{8}/ === res[0]['code']
		res[0]['code']
	end

	# INPUT: unique code & 2-letter lang
	# OUTPUT: translated text
	def code2lang(code, lang)
		res = DB.exec_params("SELECT * FROM translations WHERE code = $1", [code])
		res[0][lang]
	end

	# DESTRUCTIVE: PARSES ORIGINAL. INSERTS INTO DB. WRITES OUTFILES.
	def translate(infilename)
		tpl_file = infilename + '.tpl'
		tl8_file = infilename + '.txt'
		ref_file = infilename + '.ref'
		raise "#{tpl_file} exists" if File.exist?(tpl_file)
		raise "#{tl8_file} exists" if File.exist?(tl8_file)
		tpl, tl8, ref = parse(infilename)
		File.open(tpl_file, 'w') {|f| f.puts tpl}
		File.open(tl8_file, 'w') {|f| f.puts tl8}
		File.open(ref_file, 'w') {|f| f.puts ref}
		[tpl_file, tl8_file, ref_file].join(' + ')
	end

	# INPUT: Filename of already-parsed template + 2-letter lang code
	def merge_to(template_filename, langcode)
		outfilename = template_filename.gsub(/\.tpl\Z/, "-#{langcode}")
		outfile = unparse(template_filename, langcode)
		File.open(outfilename, 'w') {|f| f.puts outfile}
		outfilename
	end

	# TODO: input translated file from Gengo. compare to original reference.
	def lang2db(ref_file, translated, langcode)
		# get reference & translated file, with no blank lines
		ref = File.readlines(ref_file).map(&:strip).reject {|x| '' == x}
		txn = File.readlines(translated).map(&:strip).reject {|x| '' == x}
		# count from 0 to highest line number between them
		Range.new(0, [ref.size, txn.size].max, true).each do |i|
			# reference line has 8-char code, then tab, then English
			puts ref[i]
			# so add 8-space padding, then tab, to translated file
			puts "%s\t%s" % [' ' * 8, txn[i]]
			# and a blank line:
			puts
		end
	end
end
