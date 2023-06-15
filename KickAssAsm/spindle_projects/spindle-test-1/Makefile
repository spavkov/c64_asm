all:		disk.d64

demo.prg:	demo.s
		xa -o $@ $<

disk.d64:	script demo.prg
		../../src/spin -vv -o $@ $<
