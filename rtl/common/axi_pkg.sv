package axi_pkg;
typedef struct packed {
logic [31:0] data;
logic valid;
logic ready;
logic last;
logic [3:0] keep;
} axis_t;


typedef struct packed {
logic [31:0] addr;
logic [7:0] len;
logic [2:0] size;
logic valid;
logic ready;
} axi_aw_t;
endpackage
