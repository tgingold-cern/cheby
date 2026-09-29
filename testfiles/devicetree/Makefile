DTB := soc-top.dtb

all: $(DTB)

$(DTB): soc-top.dts soc.dtsi
	dtc -I dts -O dtb -o $@ $<

clean:
	rm -f $(DTB)

.PHONY: all clean