-----------------------------------------------------------------------------------
--!     @file    bitonic_sorting_network.vhd
--!     @brief   Bitonic Sorting Network Package :
--!     @version 1.4.0
--!     @date    2022/10/22
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
use     Merge_Sorter.Sorting_Network;
package Bitonic_Sorting_Network is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   New_Sorter_Network(LO,HI,ORDER,QUEUE:integer) return Sorting_Network.Param_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   New_Merger_Network(LO,HI,ORDER,QUEUE:integer) return Sorting_Network.Param_Type;
end Bitonic_Sorting_Network;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library Merge_Sorter;
use     Merge_Sorter.Sorting_Network;
package body Bitonic_Sorting_Network is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    procedure bitonic_merge(
        variable  NETWORK     :  inout Sorting_Network.Param_Type;
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
                Sorting_Network.Add_Comparator(NETWORK, START_STAGE, index, index+dist, UP);
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
        variable  NETWORK     :  inout Sorting_Network.Param_Type;
                  START_STAGE :  in    integer;
                  LO          :  in    integer;
                  HI          :  in    integer;
                  UP          :  in    boolean
    ) is
        variable  dist        :        integer;
        variable  first       :        Sorting_Network.Param_Type;
        variable  second      :        Sorting_Network.Param_Type;
        variable  next_stage  :        integer;
    begin
        if (HI - LO > 0) then
            dist   := ((HI-LO+1)+1)/2;
            first  := NETWORK;
            second := NETWORK;
            bitonic_sort (first  , START_STAGE, LO        , LO + dist-1, TRUE );
            bitonic_sort (second , START_STAGE, LO + dist , HI         , FALSE);
            Sorting_Network.Merge_Network_Stage_List(NETWORK, first , START_STAGE);
            Sorting_Network.Merge_Network_Stage_List(NETWORK, second, START_STAGE);
            next_stage := NETWORK.Stage_Hi + 1;
            bitonic_merge(NETWORK, next_stage , LO        , HI         , UP   );
        end if;
    end procedure;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   New_Sorter_Network(LO,HI,ORDER,QUEUE:integer) return Sorting_Network.Param_Type
    is
        variable  network     :        Sorting_Network.Param_Type;
    begin
        network := Sorting_Network.New_Network(LO,HI,ORDER);
        bitonic_sort(network, network.Stage_Lo, network.Lo, network.Hi, TRUE);
        Sorting_Network.Add_Queue_Params(network, QUEUE);
        return network;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function   New_Merger_Network(LO,HI,ORDER,QUEUE:integer) return Sorting_Network.Param_Type
    is
        variable  network     :        Sorting_Network.Param_Type;
    begin
        network := Sorting_Network.New_Network(LO,HI,ORDER);
        bitonic_merge(network, network.Stage_Lo, network.Lo, network.Hi, TRUE);
        Sorting_Network.Add_Queue_Params(network, QUEUE);
        return network;
    end function;
end Bitonic_Sorting_Network;