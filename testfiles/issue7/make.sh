gena2cheby code_fields.xml > code_fields.cheby

cheby --gen-gena-memmap=memmap_code_fields.vhd -i code_fields.cheby
cheby --gen-gena-regctrl=regctrl_code_fields.vhd -i code_fields.cheby

ghdl -i *.vhd
ghdl -m RegCtrl_codeFields
