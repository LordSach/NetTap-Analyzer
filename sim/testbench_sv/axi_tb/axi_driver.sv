class axi_driver;
virtual interface axi_if vif;
function new(virtual interface axi_if vif);
this.vif = vif;
endfunction
endclass
