/**********************************************************************************
    Copyright(c) 2017 Huawei Technologies Co., Ltd, All rights reserved
    Department   :   Network Product Line(NPL), R&D Logic IC Chip Department
    Filename     :   top_cib_model.sv
    Author       :   shenyue/00159590
    ===============================================================================
    Description  :   1, module example
    ===============================================================================
    Modification History:
    Date        By                      Rev.    Prj.    Change Description
    -------------------------------------------------------------------------------
    2017-10-10  shenyue                 1.0     PL501   Create
    ===============================================================================
    Called by    :  xxxxxx.v,xxxxxx.v,*
    File tree    :  xxxxxx.v
                       +---xxxxxx.v
                       +---xxxxx.v
**********************************************************************************/

`ifndef RAL_CIB_MODEL
`define RAL_CIB_MODEL

import uvm_pkg::*;

class ral_reg_cib_glb_version_v extends uvm_reg;
	uvm_reg_field version_v;

	function new(string name = "cib_glb_version_v");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.version_v = uvm_reg_field::type_id::create("version_v",,get_full_name());
      this.version_v.configure(this, 8, 0, "RO", 0, 8'h0000, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_version_v)

endclass : ral_reg_cib_glb_version_v


class ral_reg_cib_glb_version_t extends uvm_reg;
	uvm_reg_field version_t;

	function new(string name = "cib_glb_version_t");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.version_t = uvm_reg_field::type_id::create("version_t",,get_full_name());
      this.version_t.configure(this, 8, 0, "RO", 0, 8'h0000, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_version_t)

endclass : ral_reg_cib_glb_version_t


class ral_reg_cib_glb_version_b extends uvm_reg;
	uvm_reg_field version_b;

	function new(string name = "cib_glb_version_b");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.version_b = uvm_reg_field::type_id::create("version_b",,get_full_name());
      this.version_b.configure(this, 8, 0, "RO", 0, 8'h0000, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_version_b)

endclass : ral_reg_cib_glb_version_b


class ral_reg_cib_glb_lgc_id2 extends uvm_reg;
	uvm_reg_field lgc_id2;

	function new(string name = "cib_glb_lgc_id2");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.lgc_id2 = uvm_reg_field::type_id::create("lgc_id2",,get_full_name());
      this.lgc_id2.configure(this, 16, 0, "RO", 0, 16'h5344, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_lgc_id2)

endclass : ral_reg_cib_glb_lgc_id2


class ral_reg_cib_glb_lgc_id1 extends uvm_reg;
	uvm_reg_field lgc_id1;

	function new(string name = "cib_glb_lgc_id1");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.lgc_id1 = uvm_reg_field::type_id::create("lgc_id1",,get_full_name());
      this.lgc_id1.configure(this, 16, 0, "RO", 0, 16'h3033, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_lgc_id1)

endclass : ral_reg_cib_glb_lgc_id1


class ral_reg_cib_glb_lgc_id0 extends uvm_reg;
	uvm_reg_field lgc_id0;

	function new(string name = "cib_glb_lgc_id0");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.lgc_id0 = uvm_reg_field::type_id::create("lgc_id0",,get_full_name());
      this.lgc_id0.configure(this, 16, 0, "RO", 0, 16'h3032, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_lgc_id0)

endclass : ral_reg_cib_glb_lgc_id0


class ral_reg_cib_glb_year extends uvm_reg;
	uvm_reg_field year;

	function new(string name = "cib_glb_year");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.year = uvm_reg_field::type_id::create("year",,get_full_name());
      this.year.configure(this, 16, 0, "RO", 0, 16'h2016, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_year)

endclass : ral_reg_cib_glb_year


class ral_reg_cib_glb_month extends uvm_reg;
	uvm_reg_field month;

	function new(string name = "cib_glb_month");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.month = uvm_reg_field::type_id::create("month",,get_full_name());
      this.month.configure(this, 8, 0, "RO", 0, 8'h0009, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_month)

endclass : ral_reg_cib_glb_month


class ral_reg_cib_glb_day extends uvm_reg;
	uvm_reg_field day;

	function new(string name = "cib_glb_day");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.day = uvm_reg_field::type_id::create("day",,get_full_name());
      this.day.configure(this, 8, 0, "RO", 0, 8'h0016, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_day)

endclass : ral_reg_cib_glb_day


class ral_reg_cib_glb_test_reg_n extends uvm_reg;
	rand uvm_reg_field test_reg_n;

	function new(string name = "cib_glb_test_reg_n");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.test_reg_n = uvm_reg_field::type_id::create("test_reg_n",,get_full_name());
      this.test_reg_n.configure(this, 16, 0, "RW", 0, 16'h0000, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_test_reg_n)

endclass : ral_reg_cib_glb_test_reg_n


class ral_reg_cib_glb_test_reg extends uvm_reg;
	rand uvm_reg_field test_reg;

	function new(string name = "cib_glb_test_reg");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.test_reg = uvm_reg_field::type_id::create("test_reg",,get_full_name());
      this.test_reg.configure(this, 16, 0, "RW", 0, 16'h0000, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_test_reg)

endclass : ral_reg_cib_glb_test_reg


class ral_reg_cib_glb_glb_sft_rst extends uvm_reg;
	rand uvm_reg_field glb_sft_rst;

	function new(string name = "cib_glb_glb_sft_rst");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.glb_sft_rst = uvm_reg_field::type_id::create("glb_sft_rst",,get_full_name());
      this.glb_sft_rst.configure(this, 2, 0, "RW", 0, 2'h0003, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_glb_sft_rst)

endclass : ral_reg_cib_glb_glb_sft_rst


class ral_reg_cib_glb_dmac0_bit extends uvm_reg;
	rand uvm_reg_field dmac0_bit;

	function new(string name = "cib_glb_dmac0_bit");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.dmac0_bit = uvm_reg_field::type_id::create("dmac0_bit",,get_full_name());
      this.dmac0_bit.configure(this, 8, 0, "RW", 0, 8'h0000, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_dmac0_bit)

endclass : ral_reg_cib_glb_dmac0_bit


class ral_reg_cib_glb_dmac1_bit extends uvm_reg;
	rand uvm_reg_field dmac1_bit;

	function new(string name = "cib_glb_dmac1_bit");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.dmac1_bit = uvm_reg_field::type_id::create("dmac1_bit",,get_full_name());
      this.dmac1_bit.configure(this, 8, 0, "RW", 0, 8'h0011, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_dmac1_bit)

endclass : ral_reg_cib_glb_dmac1_bit


class ral_reg_cib_glb_dmac2_bit extends uvm_reg;
	rand uvm_reg_field dmac2_bit;

	function new(string name = "cib_glb_dmac2_bit");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.dmac2_bit = uvm_reg_field::type_id::create("dmac2_bit",,get_full_name());
      this.dmac2_bit.configure(this, 8, 0, "RW", 0, 8'h0022, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_dmac2_bit)

endclass : ral_reg_cib_glb_dmac2_bit


class ral_reg_cib_glb_dmac3_bit extends uvm_reg;
	rand uvm_reg_field dmac3_bit;

	function new(string name = "cib_glb_dmac3_bit");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.dmac3_bit = uvm_reg_field::type_id::create("dmac3_bit",,get_full_name());
      this.dmac3_bit.configure(this, 8, 0, "RW", 0, 8'h0033, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_glb_dmac3_bit)

endclass : ral_reg_cib_glb_dmac3_bit


class ral_block_cib_glb extends uvm_reg_block;
	rand ral_reg_cib_glb_version_v version_v;
	rand ral_reg_cib_glb_version_t version_t;
	rand ral_reg_cib_glb_version_b version_b;
	rand ral_reg_cib_glb_lgc_id2 lgc_id2;
	rand ral_reg_cib_glb_lgc_id1 lgc_id1;
	rand ral_reg_cib_glb_lgc_id0 lgc_id0;
	rand ral_reg_cib_glb_year year;
	rand ral_reg_cib_glb_month month;
	rand ral_reg_cib_glb_day day;
	rand ral_reg_cib_glb_test_reg_n test_reg_n;
	rand ral_reg_cib_glb_test_reg test_reg;
	rand ral_reg_cib_glb_glb_sft_rst glb_sft_rst;
	rand ral_reg_cib_glb_dmac0_bit dmac0_bit;
	rand ral_reg_cib_glb_dmac1_bit dmac1_bit;
	rand ral_reg_cib_glb_dmac2_bit dmac2_bit;
	rand ral_reg_cib_glb_dmac3_bit dmac3_bit;
   local uvm_reg_data_t m_offset;
	uvm_reg_field version_v_version_v;
	uvm_reg_field version_t_version_t;
	uvm_reg_field version_b_version_b;
	uvm_reg_field lgc_id2_lgc_id2;
	uvm_reg_field lgc_id1_lgc_id1;
	uvm_reg_field lgc_id0_lgc_id0;
	uvm_reg_field year_year;
	uvm_reg_field month_month;
	uvm_reg_field day_day;
	rand uvm_reg_field test_reg_n_test_reg_n;
	rand uvm_reg_field test_reg_test_reg;
	rand uvm_reg_field glb_sft_rst_glb_sft_rst;
	rand uvm_reg_field dmac0_bit_dmac0_bit;
	rand uvm_reg_field dmac1_bit_dmac1_bit;
	rand uvm_reg_field dmac2_bit_dmac2_bit;
	rand uvm_reg_field dmac3_bit_dmac3_bit;


covergroup cg_addr (input string name);
	option.per_instance = 1;
option.name = get_name();

	version_v : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h0 };
		option.weight = 1;
	}

	version_t : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h1 };
		option.weight = 1;
	}

	version_b : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h2 };
		option.weight = 1;
	}

	lgc_id2 : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h3 };
		option.weight = 1;
	}

	lgc_id1 : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h4 };
		option.weight = 1;
	}

	lgc_id0 : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h5 };
		option.weight = 1;
	}

	year : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h6 };
		option.weight = 1;
	}

	month : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h7 };
		option.weight = 1;
	}

	day : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h8 };
		option.weight = 1;
	}

	test_reg_n : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h9 };
		option.weight = 1;
	}

	test_reg : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'hA };
		option.weight = 1;
	}

	glb_sft_rst : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h10 };
		option.weight = 1;
	}

	dmac0_bit : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h20 };
		option.weight = 1;
	}

	dmac1_bit : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h21 };
		option.weight = 1;
	}

	dmac2_bit : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h22 };
		option.weight = 1;
	}

	dmac3_bit : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h23 };
		option.weight = 1;
	}
endgroup
	function new(string name = "cib_glb");
		super.new(name, build_coverage(UVM_CVR_ADDR_MAP));
		if (has_coverage(UVM_CVR_ADDR_MAP))
			cg_addr = new("cg_addr");
	endfunction: new

   virtual function void build();
      this.default_map = create_map("", 0, 2, UVM_LITTLE_ENDIAN, 0);
      this.version_v = ral_reg_cib_glb_version_v::type_id::create("version_v",,get_full_name());
      this.version_v.configure(this, null, "");
      this.version_v.build();
      this.default_map.add_reg(this.version_v, `UVM_REG_ADDR_WIDTH'h0, "RO", 0);
		this.version_v_version_v = this.version_v.version_v;
      this.version_t = ral_reg_cib_glb_version_t::type_id::create("version_t",,get_full_name());
      this.version_t.configure(this, null, "");
      this.version_t.build();
      this.default_map.add_reg(this.version_t, `UVM_REG_ADDR_WIDTH'h1, "RO", 0);
		this.version_t_version_t = this.version_t.version_t;
      this.version_b = ral_reg_cib_glb_version_b::type_id::create("version_b",,get_full_name());
      this.version_b.configure(this, null, "");
      this.version_b.build();
      this.default_map.add_reg(this.version_b, `UVM_REG_ADDR_WIDTH'h2, "RO", 0);
		this.version_b_version_b = this.version_b.version_b;
      this.lgc_id2 = ral_reg_cib_glb_lgc_id2::type_id::create("lgc_id2",,get_full_name());
      this.lgc_id2.configure(this, null, "");
      this.lgc_id2.build();
      this.default_map.add_reg(this.lgc_id2, `UVM_REG_ADDR_WIDTH'h3, "RO", 0);
		this.lgc_id2_lgc_id2 = this.lgc_id2.lgc_id2;
      this.lgc_id1 = ral_reg_cib_glb_lgc_id1::type_id::create("lgc_id1",,get_full_name());
      this.lgc_id1.configure(this, null, "");
      this.lgc_id1.build();
      this.default_map.add_reg(this.lgc_id1, `UVM_REG_ADDR_WIDTH'h4, "RO", 0);
		this.lgc_id1_lgc_id1 = this.lgc_id1.lgc_id1;
      this.lgc_id0 = ral_reg_cib_glb_lgc_id0::type_id::create("lgc_id0",,get_full_name());
      this.lgc_id0.configure(this, null, "");
      this.lgc_id0.build();
      this.default_map.add_reg(this.lgc_id0, `UVM_REG_ADDR_WIDTH'h5, "RO", 0);
		this.lgc_id0_lgc_id0 = this.lgc_id0.lgc_id0;
      this.year = ral_reg_cib_glb_year::type_id::create("year",,get_full_name());
      this.year.configure(this, null, "");
      this.year.build();
      this.default_map.add_reg(this.year, `UVM_REG_ADDR_WIDTH'h6, "RO", 0);
		this.year_year = this.year.year;
      this.month = ral_reg_cib_glb_month::type_id::create("month",,get_full_name());
      this.month.configure(this, null, "");
      this.month.build();
      this.default_map.add_reg(this.month, `UVM_REG_ADDR_WIDTH'h7, "RO", 0);
		this.month_month = this.month.month;
      this.day = ral_reg_cib_glb_day::type_id::create("day",,get_full_name());
      this.day.configure(this, null, "");
      this.day.build();
      this.default_map.add_reg(this.day, `UVM_REG_ADDR_WIDTH'h8, "RO", 0);
		this.day_day = this.day.day;
      this.test_reg_n = ral_reg_cib_glb_test_reg_n::type_id::create("test_reg_n",,get_full_name());
      this.test_reg_n.configure(this, null, "");
      this.test_reg_n.build();
      this.default_map.add_reg(this.test_reg_n, `UVM_REG_ADDR_WIDTH'h9, "RW", 0);
		this.test_reg_n_test_reg_n = this.test_reg_n.test_reg_n;
      this.test_reg = ral_reg_cib_glb_test_reg::type_id::create("test_reg",,get_full_name());
      this.test_reg.configure(this, null, "");
      this.test_reg.build();
      this.default_map.add_reg(this.test_reg, `UVM_REG_ADDR_WIDTH'hA, "RW", 0);
		this.test_reg_test_reg = this.test_reg.test_reg;
      this.glb_sft_rst = ral_reg_cib_glb_glb_sft_rst::type_id::create("glb_sft_rst",,get_full_name());
      this.glb_sft_rst.configure(this, null, "");
      this.glb_sft_rst.build();
      this.default_map.add_reg(this.glb_sft_rst, `UVM_REG_ADDR_WIDTH'h10, "RW", 0);
		this.glb_sft_rst_glb_sft_rst = this.glb_sft_rst.glb_sft_rst;
      this.dmac0_bit = ral_reg_cib_glb_dmac0_bit::type_id::create("dmac0_bit",,get_full_name());
      this.dmac0_bit.configure(this, null, "");
      this.dmac0_bit.build();
      this.default_map.add_reg(this.dmac0_bit, `UVM_REG_ADDR_WIDTH'h20, "RW", 0);
		this.dmac0_bit_dmac0_bit = this.dmac0_bit.dmac0_bit;
      this.dmac1_bit = ral_reg_cib_glb_dmac1_bit::type_id::create("dmac1_bit",,get_full_name());
      this.dmac1_bit.configure(this, null, "");
      this.dmac1_bit.build();
      this.default_map.add_reg(this.dmac1_bit, `UVM_REG_ADDR_WIDTH'h21, "RW", 0);
		this.dmac1_bit_dmac1_bit = this.dmac1_bit.dmac1_bit;
      this.dmac2_bit = ral_reg_cib_glb_dmac2_bit::type_id::create("dmac2_bit",,get_full_name());
      this.dmac2_bit.configure(this, null, "");
      this.dmac2_bit.build();
      this.default_map.add_reg(this.dmac2_bit, `UVM_REG_ADDR_WIDTH'h22, "RW", 0);
		this.dmac2_bit_dmac2_bit = this.dmac2_bit.dmac2_bit;
      this.dmac3_bit = ral_reg_cib_glb_dmac3_bit::type_id::create("dmac3_bit",,get_full_name());
      this.dmac3_bit.configure(this, null, "");
      this.dmac3_bit.build();
      this.default_map.add_reg(this.dmac3_bit, `UVM_REG_ADDR_WIDTH'h23, "RW", 0);
		this.dmac3_bit_dmac3_bit = this.dmac3_bit.dmac3_bit;
   endfunction : build

	`uvm_object_utils(ral_block_cib_glb)


function void sample(uvm_reg_addr_t offset,
                     bit            is_read,
                     uvm_reg_map    map);
  if (get_coverage(UVM_CVR_ADDR_MAP)) begin
    m_offset = offset;
    cg_addr.sample();
  end
endfunction
endclass : ral_block_cib_glb


class ral_reg_cib_test_dmac0_bit extends uvm_reg;
	rand uvm_reg_field dmac0_bit;

	function new(string name = "cib_test_dmac0_bit");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.dmac0_bit = uvm_reg_field::type_id::create("dmac0_bit",,get_full_name());
      this.dmac0_bit.configure(this, 8, 0, "RW", 0, 8'h0000, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_test_dmac0_bit)

endclass : ral_reg_cib_test_dmac0_bit


class ral_reg_cib_test_dmac1_bit extends uvm_reg;
	rand uvm_reg_field dmac1_bit;

	function new(string name = "cib_test_dmac1_bit");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.dmac1_bit = uvm_reg_field::type_id::create("dmac1_bit",,get_full_name());
      this.dmac1_bit.configure(this, 8, 0, "RW", 0, 8'h0011, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_test_dmac1_bit)

endclass : ral_reg_cib_test_dmac1_bit


class ral_reg_cib_test_dmac2_bit extends uvm_reg;
	rand uvm_reg_field dmac2_bit;

	function new(string name = "cib_test_dmac2_bit");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.dmac2_bit = uvm_reg_field::type_id::create("dmac2_bit",,get_full_name());
      this.dmac2_bit.configure(this, 8, 0, "RW", 0, 8'h0022, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_test_dmac2_bit)

endclass : ral_reg_cib_test_dmac2_bit


class ral_reg_cib_test_dmac3_bit extends uvm_reg;
	rand uvm_reg_field dmac3_bit;

	function new(string name = "cib_test_dmac3_bit");
		super.new(name, 16,build_coverage(UVM_NO_COVERAGE));
	endfunction: new
   virtual function void build();
      this.dmac3_bit = uvm_reg_field::type_id::create("dmac3_bit",,get_full_name());
      this.dmac3_bit.configure(this, 8, 0, "RW", 0, 8'h0033, 1, 0, 1);
   endfunction: build

	`uvm_object_utils(ral_reg_cib_test_dmac3_bit)

endclass : ral_reg_cib_test_dmac3_bit


class ral_block_cib_test extends uvm_reg_block;
	rand ral_reg_cib_test_dmac0_bit dmac0_bit;
	rand ral_reg_cib_test_dmac1_bit dmac1_bit;
	rand ral_reg_cib_test_dmac2_bit dmac2_bit;
	rand ral_reg_cib_test_dmac3_bit dmac3_bit;
   local uvm_reg_data_t m_offset;
	rand uvm_reg_field dmac0_bit_dmac0_bit;
	rand uvm_reg_field dmac1_bit_dmac1_bit;
	rand uvm_reg_field dmac2_bit_dmac2_bit;
	rand uvm_reg_field dmac3_bit_dmac3_bit;


covergroup cg_addr (input string name);
	option.per_instance = 1;
option.name = get_name();

	dmac0_bit : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h0 };
		option.weight = 1;
	}

	dmac1_bit : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h1 };
		option.weight = 1;
	}

	dmac2_bit : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h2 };
		option.weight = 1;
	}

	dmac3_bit : coverpoint m_offset {
		bins accessed = { `UVM_REG_ADDR_WIDTH'h3 };
		option.weight = 1;
	}
endgroup
	function new(string name = "cib_test");
		super.new(name, build_coverage(UVM_CVR_ADDR_MAP));
		if (has_coverage(UVM_CVR_ADDR_MAP))
			cg_addr = new("cg_addr");
	endfunction: new

   virtual function void build();
      this.default_map = create_map("", 0, 2, UVM_LITTLE_ENDIAN, 0);
      this.dmac0_bit = ral_reg_cib_test_dmac0_bit::type_id::create("dmac0_bit",,get_full_name());
      this.dmac0_bit.configure(this, null, "");
      this.dmac0_bit.build();
      this.default_map.add_reg(this.dmac0_bit, `UVM_REG_ADDR_WIDTH'h0, "RW", 0);
		this.dmac0_bit_dmac0_bit = this.dmac0_bit.dmac0_bit;
      this.dmac1_bit = ral_reg_cib_test_dmac1_bit::type_id::create("dmac1_bit",,get_full_name());
      this.dmac1_bit.configure(this, null, "");
      this.dmac1_bit.build();
      this.default_map.add_reg(this.dmac1_bit, `UVM_REG_ADDR_WIDTH'h1, "RW", 0);
		this.dmac1_bit_dmac1_bit = this.dmac1_bit.dmac1_bit;
      this.dmac2_bit = ral_reg_cib_test_dmac2_bit::type_id::create("dmac2_bit",,get_full_name());
      this.dmac2_bit.configure(this, null, "");
      this.dmac2_bit.build();
      this.default_map.add_reg(this.dmac2_bit, `UVM_REG_ADDR_WIDTH'h2, "RW", 0);
		this.dmac2_bit_dmac2_bit = this.dmac2_bit.dmac2_bit;
      this.dmac3_bit = ral_reg_cib_test_dmac3_bit::type_id::create("dmac3_bit",,get_full_name());
      this.dmac3_bit.configure(this, null, "");
      this.dmac3_bit.build();
      this.default_map.add_reg(this.dmac3_bit, `UVM_REG_ADDR_WIDTH'h3, "RW", 0);
		this.dmac3_bit_dmac3_bit = this.dmac3_bit.dmac3_bit;
   endfunction : build

	`uvm_object_utils(ral_block_cib_test)


function void sample(uvm_reg_addr_t offset,
                     bit            is_read,
                     uvm_reg_map    map);
  if (get_coverage(UVM_CVR_ADDR_MAP)) begin
    m_offset = offset;
    cg_addr.sample();
  end
endfunction
endclass : ral_block_cib_test


class top_cib_model extends uvm_reg_block;

   rand ral_block_cib_glb cib_glb;
   rand ral_block_cib_test cib_test;

	function new(string name = "cib_model");
		super.new(name);
	endfunction: new

	function void build();
      this.default_map = create_map("", 0, 2, UVM_LITTLE_ENDIAN, 0);
      this.cib_glb = ral_block_cib_glb::type_id::create("cib_glb",,get_full_name());
      this.cib_glb.configure(this, "");
      this.cib_glb.build();
      this.default_map.add_submap(this.cib_glb.default_map, `UVM_REG_ADDR_WIDTH'h0);
      this.cib_test = ral_block_cib_test::type_id::create("cib_test",,get_full_name());
      this.cib_test.configure(this, "");
      this.cib_test.build();
      this.default_map.add_submap(this.cib_test.default_map, `UVM_REG_ADDR_WIDTH'h100);

		//
		// Setting up backdoor access...
		//
	endfunction : build

	`uvm_object_utils(top_cib_model)
endclass : top_cib_model



`endif
