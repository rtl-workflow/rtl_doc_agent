class loopback_env_cfg extends uvm_object;
  `uvm_object_utils(loopback_env_cfg)
  int unsigned count = 4;
  function new(string name = "loopback_env_cfg");
    super.new(name);
  endfunction
endclass
