-----------------------------------------------------------------------------------
--!     @file    sorting_network.vhd
--!     @brief   Sorting Network Package :
--!     @version 2.0.0
--!     @date    2022/10/19
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2020-2022 Ichiro Kawazome
--      All rights reserved.
--
--      Redistribution and use in source and binary forms, with or without
--      modification, are permitted provided that the following conditions
--      are met:
--
--        1. Redistributions of source code must retain the above copyright
--           notice, this list of conditions and the following disclaimer.
--
--        2. Redistributions in binary form must reproduce the above copyright
--           notice, this list of conditions and the following disclaimer in
--           the documentation and/or other materials provided with the
--           distribution.
--
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
--      A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
--      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
--      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library Merge_Sorter;
use     Merge_Sorter.Word;
package Sorting_Network is
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    constant  Max_Network_Size      :  integer := 256;
    constant  Max_Stage_Size        :  integer := 256;
    constant  Max_Stage_Queue_Size  :  integer := 2;
    constant  Stage_Queue_Ctrl_Bits :  integer := Max_Stage_Queue_Size+1;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    type      Operator              is (OP_NONE, OP_PASS, OP_COMP_UP, OP_COMP_DOWN);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    type      Operator_Type         is record
                  STEP              :  integer;
                  OP                :  Operator;
    end record;
    constant  Operator_None         :  Operator_Type := (
                  STEP              => 0,
                  OP                => OP_NONE
              );
    type      Operator_Vector       is array (integer range <>) of Operator_Type;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  Operator_Is_Comp     (OP: Operator_Type) return boolean;
    function  Operator_Is_Comp_Up  (OP: Operator_Type) return boolean;
    function  Operator_Is_Comp_Down(OP: Operator_Type) return boolean;
    function  Operator_Is_Pass     (OP: Operator_Type) return boolean;
    function  Operator_Is_None     (OP: Operator_Type) return boolean;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    type      Stage_Type            is record
                  Operator_List     :  Operator_Vector(0 to Max_Network_Size-1);
                  Queue_Size        :  integer range 0 to Max_Stage_Queue_Size;
    end record;
    constant  Stage_Null            :  Stage_Type := (
                  Operator_List     => (others => Operator_None),
                  Queue_Size        => 0
              );
    type      Stage_Vector          is array (integer range <>) of Stage_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      Param_Type            is record
                  Stage_List        :  Stage_Vector( 1 to Max_Stage_Size);
                  Stage_Size        :  integer range 0 to Max_Stage_Size;
                  Stage_Lo          :  integer range 0 to Max_Stage_Size;
                  Stage_Hi          :  integer range 0 to Max_Stage_Size;
                  Stage_Ctrl_Lo     :  integer range 0 to Max_Stage_Size*Stage_Queue_Ctrl_Bits;
                  Stage_Ctrl_Hi     :  integer range 0 to Max_Stage_Size*Stage_Queue_Ctrl_Bits;
                  Sort_Order        :  integer;
                  Size              :  integer range 0 to Max_Network_Size;
                  Lo                :  integer range 0 to Max_Network_Size-1;
                  Hi                :  integer range 0 to Max_Network_Size-1;
    end record;
    constant  Param_Null            :  Param_Type := (
                  Stage_List        => (others => Stage_Null),
                  Stage_Size        => 0,
                  Stage_Lo          => 0,
                  Stage_Hi          => 0,
                  Stage_Ctrl_Lo     => 0,
                  Stage_Ctrl_Hi     => 0,
                  Sort_Order        => 0,
                  Size              => 0,
                  Lo                => 0,
                  Hi                => 0
              );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    procedure  Add_Comparator(
        variable  NETWORK     :  inout Param_Type;
                  STAGE       :  in    integer;
                  LO          :  in    integer;
                  HI          :  in    integer;
                  UP          :  in    boolean
    );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure  Add_Queue_Params(
        variable  NETWORK     :  inout Param_Type;
                  QUEUE_SIZE  :  in    integer
    );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure Merge_Network_Stage(
        variable  NETWORK     :  inout Param_Type;
                  A           :  in    Param_Type;
                  STAGE       :  in    integer
    );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure Merge_Network_Stage_List(
        variable  NETWORK     :  inout Param_Type;
                  A           :  in    Param_Type;
                  START_STAGE :  in    integer
    );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure Reverse_Network_Stage_List(
        variable  NETWORK     :  inout Param_Type
    );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   New_Bitonic_Sorter_Network(LO,HI,ORDER,QUEUE:integer) return Param_Type;
    function   New_Bitonic_Merger_Network(LO,HI,ORDER,QUEUE:integer) return Param_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   New_OddEven_Sorter_Network(LO,HI,ORDER,QUEUE:integer) return Param_Type;
    function   New_OddEven_Merger_Network(LO,HI,ORDER,QUEUE:integer) return Param_Type;
end Sorting_Network;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
package body Sorting_Network is
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  Operator_Is_Comp     (OP: Operator_Type) return boolean is
    begin
        return (Operator_Is_Comp_Up(OP) or Operator_Is_Comp_Down(OP));
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  Operator_Is_Comp_Up  (OP: Operator_Type) return boolean is
    begin
        return (OP.OP = OP_COMP_UP);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  Operator_Is_Comp_Down(OP: Operator_Type) return boolean is
    begin
        return (OP.OP = OP_COMP_DOWN);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  Operator_Is_Pass     (OP: Operator_Type) return boolean is
    begin
        return (OP.OP = OP_PASS);
    end function;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    function  Operator_Is_None     (OP: Operator_Type) return boolean is
    begin
        return (OP.OP = OP_NONE);
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure Add_Comparator(
        variable  NETWORK     :  inout Param_Type;
                  STAGE       :  in    integer;
                  LO          :  in    integer;
                  HI          :  in    integer;
                  UP          :  in    boolean
    ) is
        variable  op          :        Operator;
    begin
        if (UP = TRUE) then
            op := OP_COMP_UP;
        else
            op := OP_COMP_DOWN;
        end if;
        assert (HI - LO > 0)
            report "Add_Operator error" severity ERROR;
        assert ((NETWORK.Stage_List(STAGE).Operator_List(LO).STEP = 0      ) or
                (NETWORK.Stage_List(STAGE).Operator_List(LO).OP   = OP_NONE) or
                ((NETWORK.Stage_List(STAGE).Operator_List(LO).STEP = HI-LO) and
                 (NETWORK.Stage_List(STAGE).Operator_List(LO).OP   = op   )))
            report "Add_Operator error" severity ERROR;
        assert ((NETWORK.Stage_List(STAGE).Operator_List(HI).STEP = 0      ) or
                (NETWORK.Stage_List(STAGE).Operator_List(HI).OP   = OP_NONE) or
                ((NETWORK.Stage_List(STAGE).Operator_List(HI).STEP = LO-HI) and
                 (NETWORK.Stage_List(STAGE).Operator_List(HI).OP   = op   )))
            report "Add_Operator error" severity ERROR;
        NETWORK.Stage_List(STAGE).Operator_List(LO).STEP  := HI-LO;
        NETWORK.Stage_List(STAGE).Operator_List(LO).OP    := op;
        NETWORK.Stage_List(STAGE).Operator_List(HI).STEP  := LO-HI;
        NETWORK.Stage_List(STAGE).Operator_List(HI).OP    := op;
    end procedure;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure  Add_Queue_Params(
        variable  NETWORK     :  inout Param_Type;
                  QUEUE_SIZE  :  in    integer
    ) is
    begin
        NETWORK.Stage_Ctrl_Lo := NETWORK.Stage_Lo*Stage_Queue_Ctrl_Bits;
        NETWORK.Stage_Ctrl_Hi := NETWORK.Stage_Hi*Stage_Queue_Ctrl_Bits;
        for stage in NETWORK.Stage_Lo to NETWORK.Stage_Hi loop
            NETWORK.Stage_List(stage).Queue_Size := QUEUE_SIZE;
        end loop;
    end procedure;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure Merge_Network_Stage(
        variable  NETWORK     :  inout Param_Type;
                  A           :  in    Param_Type;
                  STAGE       :  in    integer
    ) is
        variable  n_op        :        Operator_Type;
        variable  a_op        :        Operator_Type;
    begin
        for i in NETWORK.Lo to NETWORK.Hi loop
            n_op := NETWORK.Stage_List(STAGE).Operator_List(i);
            a_op := A      .Stage_List(STAGE).Operator_List(i);
            if (Operator_Is_None(a_op) = FALSE) then
                assert (Operator_Is_None(n_op) or (n_op = a_op))
                    report "Merge_Network_Stage error" severity ERROR;
                NETWORK.Stage_List(STAGE).Operator_List(i) := a_op;
            end if;
        end loop;
    end procedure;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure Merge_Network_Stage_List(
        variable  NETWORK     :  inout Param_Type;
                  A           :  in    Param_Type;
                  START_STAGE :  in    integer
    ) is
        variable  stage_size  :        integer;
        variable  stage_hi    :        integer;
    begin
        if (NETWORK.Stage_Hi <= A.Stage_Hi) then
            NETWORK.Stage_Hi := A.Stage_Hi;
        end if;
        for stage in START_STAGE to NETWORK.Stage_Hi loop
            if (stage <= A.Stage_Hi) then
                Merge_Network_Stage(NETWORK, A, stage);
            end if;
        end loop;
        NETWORK.Stage_Size := NETWORK.Stage_Hi - NETWORK.Stage_Lo + 1;
    end procedure;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure bitonic_merge(
        variable  NETWORK     :  inout Param_Type;
                  START_STAGE :  in    integer;
                  LO          :  in    integer;
                  HI          :  in    integer;
                  UP          :  in    boolean
    ) is
        variable  dist        :        integer;
        variable  index       :        integer;
    begin
        if (HI - LO > 0) then
            dist   := ((HI-LO+1)+1)/2;
            index  := LO;
            while (index+dist <= HI) loop
                Add_Comparator(NETWORK, START_STAGE, index, index+dist, UP);
                index := index + 1;
            end loop;
            if (START_STAGE > NETWORK.Stage_Hi) then
                NETWORK.Stage_Hi   := START_STAGE;
                NETWORK.Stage_Size := NETWORK.Stage_Hi - NETWORK.Stage_Lo + 1;
            end if;
            bitonic_merge(NETWORK, START_STAGE + 1, LO     , LO+dist-1, UP);
            bitonic_merge(NETWORK, START_STAGE + 1, LO+dist, HI       , UP);
        end if;
    end procedure;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure bitonic_sort(
        variable  NETWORK     :  inout Param_Type;
                  START_STAGE :  in    integer;
                  LO          :  in    integer;
                  HI          :  in    integer;
                  UP          :  in    boolean
    ) is
        variable  dist        :        integer;
        variable  first       :        Param_Type;
        variable  second      :        Param_Type;
        variable  next_stage  :        integer;
    begin
        if (HI - LO > 0) then
            dist   := ((HI-LO+1)+1)/2;
            first  := NETWORK;
            second := NETWORK;
            bitonic_sort (first  , START_STAGE, LO        , LO + dist-1, TRUE );
            bitonic_sort (second , START_STAGE, LO + dist , HI         , FALSE);
            Merge_Network_Stage_List(NETWORK, first , START_STAGE);
            Merge_Network_Stage_List(NETWORK, second, START_STAGE);
            next_stage := NETWORK.Stage_Hi + 1;
            bitonic_merge(NETWORK, next_stage , LO        , HI         , UP   );
        end if;
    end procedure;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   New_Bitonic_Sorter_Network(LO,HI,ORDER,QUEUE:integer) return Param_Type
    is
        variable  network  :  Param_Type;
    begin
        network            := Param_Null;
        network.Size       := HI - LO + 1;
        network.Lo         := LO;
        network.Hi         := HI;
        network.Sort_Order := ORDER;
        network.Stage_Lo   := 1;
        network.Stage_Hi   := 0;
        bitonic_sort(network, network.Stage_Lo, network.Lo, network.Hi, TRUE);
        Add_Queue_Params(network, QUEUE);
        return network;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   New_Bitonic_Merger_Network(LO,HI,ORDER,QUEUE:integer) return Param_Type
    is
        variable  network  :  Param_Type;
    begin
        network            := Param_Null;
        network.Size       := HI - LO + 1;
        network.Lo         := LO;
        network.Hi         := HI;
        network.Sort_Order := ORDER;
        network.Stage_Lo   := 1;
        network.Stage_Hi   := 0;
        bitonic_merge(network, network.Stage_Lo, network.Lo, network.Hi, TRUE);
        Add_Queue_Params(network, QUEUE);
        return network;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure oddeven_merge(
        variable  NETWORK     :  inout Param_Type;
                  START_STAGE :  in    integer;
                  LO          :  in    integer;
                  HI          :  in    integer;
                  R           :  in    integer
    ) is
        variable  step        :        integer;
        variable  index       :        integer;
    begin
        step := R * 2;
        if (HI - LO > step) then
            oddeven_merge(NETWORK, START_STAGE + 1, LO    , HI, step);
            oddeven_merge(NETWORK, START_STAGE + 1, LO + R, HI, step);
            index  := LO + R;
            while (index <= HI - R) loop
                Add_Comparator(NETWORK, START_STAGE, index, index + R, TRUE);
                index := index + step;
            end loop;
        else
            Add_Comparator(NETWORK, START_STAGE, LO, LO + R, TRUE);
        end if;
        if (START_STAGE > NETWORK.Stage_Hi) then
            NETWORK.Stage_Hi   := START_STAGE;
            NETWORK.Stage_Size := NETWORK.Stage_Hi - NETWORK.Stage_Lo + 1;
        end if;
    end procedure;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure oddeven_sort(
        variable  NETWORK     :  inout Param_Type;
                  START_STAGE :  in    integer;
                  LO          :  in    integer;
                  HI          :  in    integer
    ) is
        variable  mid         :        integer;
    begin
        if (HI - LO > 0) then
            mid := LO + ((HI - LO) / 2);
            oddeven_merge(NETWORK, START_STAGE         , LO   , HI , 1);
            oddeven_sort (NETWORK, NETWORK.Stage_HI + 1, LO   , mid   );
            oddeven_sort (NETWORK, NETWORK.Stage_HI + 1, mid+1, HI    );
        end if;
    end procedure;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure Reverse_Network_Stage_List(
        variable  NETWORK     :  inout Param_Type
    ) is
        variable  stage_list  :        Stage_Vector(NETWORK.Stage_LO to NETWORK.Stage_HI);
    begin
        stage_list(NETWORK.Stage_LO to NETWORK.Stage_HI) := NETWORK.Stage_List(NETWORK.Stage_LO to NETWORK.Stage_HI);
        for i in 0 to NETWORK.Stage_Size-1 loop
            NETWORK.Stage_List(NETWORK.Stage_Lo+i) := stage_list(NETWORK.Stage_Hi-i);
        end loop;
    end procedure;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   New_OddEven_Sorter_Network(LO,HI,ORDER,QUEUE:integer) return Param_Type
    is
        variable  network  :  Param_Type;
    begin
        network            := Param_Null;
        network.Size       := HI - LO + 1;
        network.Lo         := LO;
        network.Hi         := HI;
        network.Sort_Order := ORDER;
        network.Stage_Lo   := 1;
        network.Stage_Hi   := 0;
        oddeven_sort(network, network.Stage_Lo, network.Lo, network.Hi);
        Reverse_Network_Stage_List(network);
        Add_Queue_Params(network, QUEUE);
        return network;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   New_OddEven_Merger_Network(LO,HI,ORDER,QUEUE:integer) return Param_Type
    is
        variable  network  :  Param_Type;
    begin
        network            := Param_Null;
        network.Size       := HI - LO + 1;
        network.Lo         := LO;
        network.Hi         := HI;
        network.Sort_Order := ORDER;
        network.Stage_Lo   := 1;
        network.Stage_Hi   := 0;
        oddeven_merge(network, network.Stage_Lo, network.Lo, network.Hi, 1);
        Reverse_Network_Stage_List(network);
        Add_Queue_Params(network, QUEUE);
        return network;
    end function;
end Sorting_Network;
