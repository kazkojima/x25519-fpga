
ARCH=ecp5
DEVICE=um5g-85k
PACKAGE=CABGA381
PINCONSTRAINTS=ecp5-evn.lpf
BITSTREAM=top_ecp5.svf

#QUIET=-q
#QUIET=--verbose --debug

.PHONY: all prog sim clean

.PRECIOUS: %.json %.asc %.bin %.rpt %.txtcfg

X25519_RTL = csa.v addmod.v submod.v multmod.v inv_montgomery.v point_add.v \
	scalarmultB.v

all: $(BITSTREAM)

prog: $(BITSTREAM)
	openocd -f ecp5-evn.openocd.conf -c "transport select jtag; init; svf progress quiet $<; exit"

clean:
	-rm -f *.json
	-rm -f *.asc
	-rm -f *.bin
	-rm -f *.rpt
	-rm -f *.txtcfg
	-rm -f *.svf
	-rm -f *_tb.test
	-rm -f *.vvp
	-rm -f *.vcd
	-rm -f *.out
	-rm -f *~

top_$(ARCH).json: top.v $(X25519_RTL)


tb.vvp: tb.v $(X25519_RTL)
	iverilog -s testbench -o $@ $^

sim: tb.vvp
	vvp -N $<
	gtkwave testbench.vcd soc.gtkw

%_ecp5.json: %.v $(X25519_RTL)
	yosys -Q $(QUIET) -p 'synth_ecp5 -nomux -top $(subst .v,,$<) -json $@' $^

%_ecp5.txtcfg: %_ecp5.json
	nextpnr-ecp5 $(QUIET) --ignore-loops --placer heap --$(DEVICE) --package $(PACKAGE) --lpf $(PINCONSTRAINTS) --json $< --textcfg $@

%_ecp5.svf: %_ecp5.txtcfg
	ecppack --svf $@ $<
