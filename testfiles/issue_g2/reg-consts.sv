package header_block_Consts;
  localparam HEADER_BLOCK_SIZE = 8;
  localparam ADDR_HEADER_BLOCK_REG_000_DRAWING_NUMBER = 'h0;
  localparam HEADER_BLOCK_REG_000_DRAWING_NUMBER_PRESET = 32'h8000101;
  localparam ADDR_HEADER_BLOCK_REG_001_VERSION_REVISION = 'h4;
  localparam ADDR_HEADER_BLOCK_REG_001_VERSION_REVISION_VERSION = 'h4;
  localparam HEADER_BLOCK_REG_001_VERSION_REVISION_VERSION_OFFSET = 0;
  localparam HEADER_BLOCK_REG_001_VERSION_REVISION_VERSION = 32'hf;
  localparam HEADER_BLOCK_REG_001_VERSION_REVISION_VERSION_PRESET = 4'h1;
  localparam ADDR_HEADER_BLOCK_REG_001_VERSION_REVISION_REVISION = 'h4;
  localparam HEADER_BLOCK_REG_001_VERSION_REVISION_REVISION_OFFSET = 4;
  localparam HEADER_BLOCK_REG_001_VERSION_REVISION_REVISION = 32'hff0;
  localparam HEADER_BLOCK_REG_001_VERSION_REVISION_REVISION_PRESET = 8'h0;
  localparam ADDR_HEADER_BLOCK_REG_001_VERSION_REVISION_BUILD_DATE = 'h4;
  localparam HEADER_BLOCK_REG_001_VERSION_REVISION_BUILD_DATE_OFFSET = 12;
  localparam HEADER_BLOCK_REG_001_VERSION_REVISION_BUILD_DATE = 32'hfffff000;
  localparam HEADER_BLOCK_REG_001_VERSION_REVISION_BUILD_DATE_PRESET = 20'h3840f;
endpackage
