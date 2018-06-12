merge_sorter_compare.o : ../../../src/main/vhdl/misc/merge_sorter_compare.vhd 
	ghdl -a -C $(GHDLFLAGS) --work=MERGE_SORTER ../../../src/main/vhdl/misc/merge_sorter_compare.vhd

merge_sorter_queue.o : ../../../src/main/vhdl/misc/merge_sorter_queue.vhd 
	ghdl -a -C $(GHDLFLAGS) --work=MERGE_SORTER ../../../src/main/vhdl/misc/merge_sorter_queue.vhd

merge_sorter_simple_cell.o : ../../../src/main/vhdl/simple_tree/merge_sorter_simple_cell.vhd merge_sorter_compare.o
	ghdl -a -C $(GHDLFLAGS) --work=MERGE_SORTER ../../../src/main/vhdl/simple_tree/merge_sorter_simple_cell.vhd

merge_sorter_core_fifo.o : ../../../src/main/vhdl/core/merge_sorter_core_fifo.vhd 
	ghdl -a -C $(GHDLFLAGS) --work=MERGE_SORTER ../../../src/main/vhdl/core/merge_sorter_core_fifo.vhd

merge_sorter_core_stream_intake.o : ../../../src/main/vhdl/core/merge_sorter_core_stream_intake.vhd 
	ghdl -a -C $(GHDLFLAGS) --work=MERGE_SORTER ../../../src/main/vhdl/core/merge_sorter_core_stream_intake.vhd

merge_sorter_drop_none.o : ../../../src/main/vhdl/misc/merge_sorter_drop_none.vhd 
	ghdl -a -C $(GHDLFLAGS) --work=MERGE_SORTER ../../../src/main/vhdl/misc/merge_sorter_drop_none.vhd

merge_sorter_simple_tree.o : ../../../src/main/vhdl/simple_tree/merge_sorter_simple_tree.vhd merge_sorter_simple_cell.o merge_sorter_queue.o
	ghdl -a -C $(GHDLFLAGS) --work=MERGE_SORTER ../../../src/main/vhdl/simple_tree/merge_sorter_simple_tree.vhd

merge_sorter_core.o : ../../../src/main/vhdl/core/merge_sorter_core.vhd merge_sorter_core_stream_intake.o merge_sorter_core_fifo.o merge_sorter_simple_tree.o merge_sorter_queue.o merge_sorter_drop_none.o
	ghdl -a -C $(GHDLFLAGS) --work=MERGE_SORTER ../../../src/main/vhdl/core/merge_sorter_core.vhd

merge_sorter_core_components.o : ../../../src/main/vhdl/core/merge_sorter_core_components.vhd 
	ghdl -a -C $(GHDLFLAGS) --work=MERGE_SORTER ../../../src/main/vhdl/core/merge_sorter_core_components.vhd

merge_sorter_core_test_bench.o : ../../../src/test/vhdl/merge_sorter_core_test_bench.vhd merge_sorter_core_components.o merge_sorter_core.o
	ghdl -a -C $(GHDLFLAGS) --work=MERGE_SORTER ../../../src/test/vhdl/merge_sorter_core_test_bench.vhd

