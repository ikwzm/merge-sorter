-----------------------------------------------------------------------------------
--!     @file    merge_sorter_core.vhd
--!     @brief   Merge Sorter Core Module :
--!     @version 0.3.0
--!     @date    2020/9/17
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2018-2020 Ichiro Kawazome
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
library Merge_Sorter;
entity  Merge_Sorter_Core is
    generic (
        MRG_IN_ENABLE   :  boolean := TRUE;
        MRG_WAYS        :  integer :=    8;
        MRG_FIFO_SIZE   :  integer :=  128;
        MRG_LEVEL_SIZE  :  integer :=   64;
        STM_IN_ENABLE   :  boolean := TRUE;
        STM_WAYS        :  integer :=    1;
        STM_FEEDBACK    :  integer :=    1;
        SORT_ORDER      :  integer :=    0;
        DATA_BITS       :  integer :=   64;
        COMP_HIGH       :  integer :=   63;
        COMP_LOW        :  integer :=    0;
        COMP_SIGN       :  boolean := FALSE
    );
    port (
        CLK             :  in  std_logic;
        RST             :  in  std_logic;
        CLR             :  in  std_logic;
        STM_REQ_VALID   :  in  std_logic;
        STM_REQ_READY   :  out std_logic;
        STM_RES_VALID   :  out std_logic;
        STM_RES_READY   :  in  std_logic;
        STM_IN_DATA     :  in  std_logic_vector(STM_WAYS*DATA_BITS-1 downto 0);
        STM_IN_STRB     :  in  std_logic_vector(STM_WAYS          -1 downto 0);
        STM_IN_LAST     :  in  std_logic;
        STM_IN_VALID    :  in  std_logic;
        STM_IN_READY    :  out std_logic;
        STM_OUT_DATA    :  out std_logic_vector(           DATA_BITS-1 downto 0);
        STM_OUT_LAST    :  out std_logic;
        STM_OUT_VALID   :  out std_logic;
        STM_OUT_READY   :  in  std_logic;
        MRG_REQ_VALID   :  in  std_logic;
        MRG_REQ_READY   :  out std_logic;
        MRG_RES_VALID   :  out std_logic;
        MRG_RES_READY   :  in  std_logic;
        MRG_IN_DATA     :  in  std_logic_vector(MRG_WAYS*DATA_BITS-1 downto 0);
        MRG_IN_NONE     :  in  std_logic_vector(MRG_WAYS          -1 downto 0);
        MRG_IN_EBLK     :  in  std_logic_vector(MRG_WAYS          -1 downto 0);
        MRG_IN_LAST     :  in  std_logic_vector(MRG_WAYS          -1 downto 0);
        MRG_IN_VALID    :  in  std_logic_vector(MRG_WAYS          -1 downto 0);
        MRG_IN_READY    :  out std_logic_vector(MRG_WAYS          -1 downto 0);
        MRG_IN_LEVEL    :  out std_logic_vector(MRG_WAYS          -1 downto 0);
        MRG_OUT_DATA    :  out std_logic_vector(         DATA_BITS-1 downto 0);
        MRG_OUT_LAST    :  out std_logic;
        MRG_OUT_VALID   :  out std_logic;
        MRG_OUT_READY   :  in  std_logic
    );
end Merge_Sorter_Core;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library Merge_Sorter;
use     Merge_Sorter.Word;
use     Merge_Sorter.Core_Components.Word_Queue;
use     Merge_Sorter.Core_Components.Drop_None;
use     Merge_Sorter.Core_Components.Core_Intake_Fifo;
use     Merge_Sorter.Core_Components.Core_Stream_Intake;
architecture RTL of Merge_Sorter_Core is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    component Single_Word_Tree
        generic (
            WORD_PARAM      :  Word.Param_Type := Word.Default_Param;
            WAYS            :  integer :=  8;
            INFO_BITS       :  integer :=  1;
            SORT_ORDER      :  integer :=  0;
            QUEUE_SIZE      :  integer :=  2
        );
        port (
            CLK             :  in  std_logic;
            RST             :  in  std_logic;
            CLR             :  in  std_logic;
            I_WORD          :  in  std_logic_vector(WAYS*WORD_PARAM.BITS-1 downto 0);
            I_INFO          :  in  std_logic_vector(WAYS*INFO_BITS      -1 downto 0) := (others => '0');
            I_LAST          :  in  std_logic_vector(WAYS                -1 downto 0);
            I_VALID         :  in  std_logic_vector(WAYS                -1 downto 0);
            I_READY         :  out std_logic_vector(WAYS                -1 downto 0);
            O_WORD          :  out std_logic_vector(     WORD_PARAM.BITS-1 downto 0);
            O_INFO          :  out std_logic_vector(     INFO_BITS      -1 downto 0);
            O_LAST          :  out std_logic;
            O_VALID         :  out std_logic;
            O_READY         :  in  std_logic
        );
    end component;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  or_reduce(Arg : std_logic_vector) return std_logic is
        variable result : std_logic;
    begin
        result := '0';
        for i in Arg'range loop
            result := result or Arg(i);
        end loop;
        return result;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  CALC_MAX_FBK_OUT_SIZE(FBK,NUM:integer) return integer is
        variable add  : integer;
        variable size : integer;
    begin
        if (FBK > 0) then
            size := 0;
            add  := 1;
            for i in 1 to FBK loop
                size := size + add;
                add  := add  * NUM;
            end loop;
        else
            size := 1;
        end if;
        return size;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  CALC_FIFO_SIZE return integer is
        variable fifo_size : integer;
    begin
        if (STM_IN_ENABLE = TRUE) then
            if    (STM_FEEDBACK = 0) then
                fifo_size := 0;
            elsif (STM_FEEDBACK = 1) then
                fifo_size := MRG_WAYS;
            else
                fifo_size := 2*(MRG_WAYS**STM_FEEDBACK);
            end if;
        else
            fifo_size := 0;
        end if;
        if (MRG_IN_ENABLE = TRUE and fifo_size < MRG_FIFO_SIZE) then
            fifo_size := MRG_FIFO_SIZE;
        end if;
        return fifo_size;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  NUM_TO_BITS(NUM:integer) return integer is
        variable value : integer;
    begin
        value := 0;
        while (2**value <= NUM) loop
            value := value + 1;
        end loop;
        return value;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  max(A,B:integer) return integer is
    begin
        if (A > B) then return A;
        else            return B;
        end if;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  FIFO_SIZE             :  integer := CALC_FIFO_SIZE;
    constant  MAX_FBK_OUT_SIZE      :  integer := CALC_MAX_FBK_OUT_SIZE(STM_FEEDBACK,MRG_WAYS);
    constant  SIZE_BITS             :  integer := NUM_TO_BITS(max(MAX_FBK_OUT_SIZE, max(MRG_WAYS**STM_FEEDBACK,MRG_WAYS)));
    constant  MRG_WAYS_BITS         :  integer := NUM_TO_BITS(MRG_WAYS-1);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  INFO_EBLK_POS         :  integer := 0;
    constant  INFO_FBK_POS          :  integer := 1;
    constant  INFO_FBK_NUM_LO       :  integer := 2;
    constant  INFO_FBK_NUM_HI       :  integer := INFO_FBK_NUM_LO + MRG_WAYS_BITS - 1;
    constant  INFO_BITS             :  integer := INFO_FBK_NUM_HI + 1;
    constant  WORD_PARAM            :  Word.Param_Type
                                    := Word.New_Param(DATA_BITS, COMP_LOW, COMP_HIGH, COMP_SIGN);
    constant  WORD_BITS             :  integer := WORD_PARAM.BITS;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    stream_intake_word    :  std_logic_vector(MRG_WAYS*WORD_BITS-1 downto 0);
    signal    stream_intake_info    :  std_logic_vector(MRG_WAYS*INFO_BITS-1 downto 0);
    signal    stream_intake_last    :  std_logic_vector(MRG_WAYS          -1 downto 0);
    signal    stream_intake_valid   :  std_logic_vector(MRG_WAYS          -1 downto 0);
    signal    stream_intake_ready   :  std_logic_vector(MRG_WAYS          -1 downto 0);
    signal    stream_intake_start   :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    fifo_intake_word      :  std_logic_vector(MRG_WAYS*WORD_BITS-1 downto 0);
    signal    fifo_intake_info      :  std_logic_vector(MRG_WAYS*INFO_BITS-1 downto 0);
    signal    fifo_intake_last      :  std_logic_vector(MRG_WAYS          -1 downto 0);
    signal    fifo_intake_valid     :  std_logic_vector(MRG_WAYS          -1 downto 0);
    signal    fifo_intake_ready     :  std_logic_vector(MRG_WAYS          -1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    sort_intake_word      :  std_logic_vector(MRG_WAYS*WORD_BITS-1 downto 0);
    signal    sort_intake_info      :  std_logic_vector(MRG_WAYS*INFO_BITS-1 downto 0);
    signal    sort_intake_last      :  std_logic_vector(MRG_WAYS          -1 downto 0);
    signal    sort_intake_valid     :  std_logic_vector(MRG_WAYS          -1 downto 0);
    signal    sort_intake_ready     :  std_logic_vector(MRG_WAYS          -1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    sort_outlet_word      :  std_logic_vector(WORD_BITS-1 downto 0);
    signal    sort_outlet_info      :  std_logic_vector(INFO_BITS-1 downto 0);
    signal    sort_outlet_last      :  std_logic;
    signal    sort_outlet_valid     :  std_logic;
    signal    sort_outlet_ready     :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    fifo_stream_req       :  std_logic;
    signal    fifo_stream_ack       :  std_logic_vector(MRG_WAYS -1 downto 0);
    signal    fifo_stream_done      :  std_logic_vector(MRG_WAYS -1 downto 0);
    signal    fifo_merge_req        :  std_logic;
    signal    fifo_merge_ack        :  std_logic_vector(MRG_WAYS -1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    feedback_out_start    :  std_logic;
    signal    feedback_out_size     :  std_logic_vector(SIZE_BITS-1 downto 0);
    signal    feedback_out_last     :  std_logic;
    signal    feedback_word         :  std_logic_vector(WORD_BITS-1 downto 0);
    signal    feedback_last         :  std_logic;
    signal    feedback_valid        :  std_logic_vector(MRG_WAYS -1 downto 0);
    signal    feedback_ready        :  std_logic_vector(MRG_WAYS -1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    outlet_i_word         :  std_logic_vector(WORD_BITS-1 downto 0);
    signal    outlet_i_eblk         :  std_logic;
    signal    outlet_i_last         :  std_logic;
    signal    outlet_i_valid        :  std_logic;
    signal    outlet_i_ready        :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    stream_out_req        :  std_logic;
    signal    stream_out_done       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    merge_out_req         :  std_logic;
    signal    merge_out_done        :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      STATE_TYPE            is (IDLE_STATE,
                                        STREAM_INIT_STATE,
                                        STREAM_RUN_STATE,
                                        STREAM_NEXT_STATE,
                                        STREAM_EXIT_STATE,
                                        STREAM_RES_STATE,
                                        MERGE_INIT_STATE,
                                        MERGE_RUN_STATE,
                                        MERGE_EXIT_STATE,
                                        MERGE_RES_STATE
                                       );
    signal    curr_state           :  STATE_TYPE;
    constant  ACK_ALL_1            :  std_logic_vector(MRG_WAYS-1 downto 0) := (others => '1');
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    FSM: process (CLK, RST) begin
        if (RST = '1') then
                curr_state <= IDLE_STATE;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state <= IDLE_STATE;
            else
                case curr_state is
                    when IDLE_STATE         =>
                        if    (STM_IN_ENABLE = TRUE and STM_REQ_VALID = '1') then
                            curr_state <= STREAM_INIT_STATE;
                        elsif (MRG_IN_ENABLE = TRUE and MRG_REQ_VALID = '1') then
                            curr_state <= MERGE_INIT_STATE;
                        else
                            curr_state <= IDLE_STATE;
                        end if;
                    when STREAM_INIT_STATE  =>
                        if (STM_IN_ENABLE = FALSE) then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= STREAM_RUN_STATE;
                        end if;
                    when STREAM_RUN_STATE   =>
                        if    (STM_IN_ENABLE = FALSE) then
                            curr_state <= IDLE_STATE;
                        elsif (STM_FEEDBACK = 0) then
                            if    (feedback_out_start = '1' and feedback_out_last = '1') then
                                curr_state <= STREAM_EXIT_STATE;
                            elsif (feedback_out_start = '1' and feedback_out_last = '0') then
                                curr_state <= STREAM_NEXT_STATE;
                            else
                                curr_state <= STREAM_RUN_STATE;
                            end if;
                        else
                            if    (fifo_stream_ack = ACK_ALL_1 and fifo_stream_done  = ACK_ALL_1) then
                                curr_state <= STREAM_EXIT_STATE;
                            elsif (fifo_stream_ack = ACK_ALL_1 and fifo_stream_done /= ACK_ALL_1) then
                                curr_state <= STREAM_NEXT_STATE;
                            else
                                curr_state <= STREAM_RUN_STATE;
                            end if;
                        end if;
                    when STREAM_NEXT_STATE  =>
                        if    (STM_IN_ENABLE = FALSE) then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= STREAM_RUN_STATE;
                        end if;
                    when STREAM_EXIT_STATE  =>
                        if    (STM_IN_ENABLE = FALSE) then
                            curr_state <= IDLE_STATE;
                        elsif (stream_out_done = '1') then
                            curr_state <= STREAM_RES_STATE;
                        else
                            curr_state <= STREAM_EXIT_STATE;
                        end if;
                    when STREAM_RES_STATE   =>
                        if    (STM_IN_ENABLE = FALSE) then
                            curr_state <= IDLE_STATE;
                        elsif (STM_RES_READY = '1') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= STREAM_RES_STATE;
                        end if;
                    when MERGE_INIT_STATE   =>
                        if (MRG_IN_ENABLE = FALSE) then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= MERGE_RUN_STATE;
                        end if;
                    when MERGE_RUN_STATE    =>
                        if    (MRG_IN_ENABLE = FALSE) then
                            curr_state <= IDLE_STATE;
                        elsif (fifo_merge_ack = ACK_ALL_1) then
                            curr_state <= MERGE_EXIT_STATE;
                        else
                            curr_state <= MERGE_RUN_STATE;
                        end if;
                    when MERGE_EXIT_STATE   =>
                        if    (MRG_IN_ENABLE = FALSE) then
                            curr_state <= IDLE_STATE;
                        elsif (merge_out_done = '1') then
                            curr_state <= MERGE_RES_STATE;
                        else
                            curr_state <= MERGE_EXIT_STATE;
                        end if;
                    when MERGE_RES_STATE   =>
                        if    (MRG_IN_ENABLE = FALSE) then
                            curr_state <= IDLE_STATE;
                        elsif (MRG_RES_READY = '1') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= MERGE_RES_STATE;
                        end if;
                    when others =>
                        curr_state <= IDLE_STATE;
                end case;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    STM_REQ_READY <= '1' when (curr_state = STREAM_INIT_STATE) else '0';
    STM_RES_VALID <= '1' when (curr_state = STREAM_RES_STATE ) else '0';
    MRG_REQ_READY <= '1' when (curr_state = MERGE_INIT_STATE ) else '0';
    MRG_RES_VALID <= '1' when (curr_state = MERGE_RES_STATE  ) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    stream_intake_start <= '1' when (curr_state = STREAM_INIT_STATE) or
                                    (curr_state = STREAM_NEXT_STATE) else '0';
    fifo_stream_req     <= '1' when (curr_state = STREAM_INIT_STATE) or
                                    (curr_state = STREAM_NEXT_STATE) or
                                    (curr_state = STREAM_RUN_STATE and fifo_stream_ack /= ACK_ALL_1) else '0';
    fifo_merge_req      <= '1' when (curr_state = MERGE_INIT_STATE ) or
                                    (curr_state = MERGE_RUN_STATE  ) else '0';
    stream_out_req      <= '1' when (curr_state = STREAM_INIT_STATE) or
                                    (curr_state = STREAM_NEXT_STATE) or
                                    (curr_state = STREAM_RUN_STATE ) or
                                    (curr_state = STREAM_EXIT_STATE) else '0';
    merge_out_req       <= '1' when (curr_state = MERGE_INIT_STATE ) or
                                    (curr_state = MERGE_RUN_STATE  ) or
                                    (curr_state = MERGE_EXIT_STATE ) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    STM_INTAKE: if (STM_IN_ENABLE = TRUE) generate       -- 
        QUEUE: Core_Stream_Intake                        -- 
            generic map (                                --
                WORD_PARAM      => WORD_PARAM          , -- 
                MRG_WAYS        => MRG_WAYS            , -- 
                STM_WAYS        => STM_WAYS            , -- 
                FEEDBACK        => STM_FEEDBACK        , -- 
                MRG_WAYS_BITS   => MRG_WAYS_BITS       , -- 
                SIZE_BITS       => SIZE_BITS           , --
                INFO_BITS       => INFO_BITS           , --
                INFO_EBLK_POS   => INFO_EBLK_POS       , -- 
                INFO_FBK_POS    => INFO_FBK_POS        , -- 
                INFO_FBK_NUM_LO => INFO_FBK_NUM_LO     , -- 
                INFO_FBK_NUM_HI => INFO_FBK_NUM_HI       -- 
            )                                            -- 
            port map (                                   -- 
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
                START           => stream_intake_start , -- In  :
                BUSY            => open                , -- Out :
                DONE            => open                , -- Out :
                FBK_OUT_START   => feedback_out_start  , -- Out :
                FBK_OUT_SIZE    => feedback_out_size   , -- Out :
                FBK_OUT_LAST    => feedback_out_last   , -- Out :
                I_DATA          => STM_IN_DATA         , -- In  :
                I_STRB          => STM_IN_STRB         , -- In  :
                I_LAST          => STM_IN_LAST         , -- In  :
                I_VALID         => STM_IN_VALID        , -- In  :
                I_READY         => STM_IN_READY        , -- Out :
                O_WORD          => stream_intake_word  , -- Out :
                O_INFO          => stream_intake_info  , -- Out :
                O_LAST          => stream_intake_last  , -- Out :
                O_VALID         => stream_intake_valid , -- Out :
                O_READY         => stream_intake_ready   -- In  :
            );
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    STM_INTAKE_OFF: if (STM_IN_ENABLE = FALSE) generate
        stream_intake_word  <= (others => '0');
        stream_intake_info  <= (others => '0');
        stream_intake_last  <= (others => '0');
        stream_intake_valid <= (others => '0');
        feedback_out_start  <= '0';
        feedback_out_size   <= (others => '0');
        feedback_out_last   <= '0';
        STM_IN_READY        <= '0';
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    FIFO: for i in 0 to MRG_WAYS-1 generate
        signal   mrg_in_word    :  std_logic_vector(WORD_PARAM.BITS-1 downto 0);
    begin
        mrg_in_word(WORD_PARAM.DATA_HI downto WORD_PARAM.DATA_LO) <= MRG_IN_DATA((i+1)*DATA_BITS-1 downto i*DATA_BITS);
        mrg_in_word(WORD_PARAM.ATRB_NONE_POS    ) <= MRG_IN_NONE(i);
        mrg_in_word(WORD_PARAM.ATRB_PRIORITY_POS) <= '0';
        mrg_in_word(WORD_PARAM.ATRB_POSTPEND_POS) <= MRG_IN_NONE(i);
        U: Core_Intake_Fifo                              -- 
            generic map (                                -- 
                WORD_PARAM      => WORD_PARAM          , --
                FBK_IN_ENABLE   => (STM_IN_ENABLE = TRUE and STM_FEEDBACK > 0), -- 
                MRG_IN_ENABLE   => MRG_IN_ENABLE       , -- 
                SIZE_BITS       => SIZE_BITS           , -- 
                FIFO_SIZE       => FIFO_SIZE           , -- 
                LEVEL_SIZE      => MRG_LEVEL_SIZE      , --
                INFO_BITS       => INFO_BITS           , --
                INFO_EBLK_POS   => INFO_EBLK_POS       , -- 
                INFO_FBK_POS    => INFO_FBK_POS        , -- 
                INFO_FBK_NUM_LO => INFO_FBK_NUM_LO     , -- 
                INFO_FBK_NUM_HI => INFO_FBK_NUM_HI       -- 
            )                                            -- 
            port map (                                   -- 
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
                FBK_REQ         => fifo_stream_req     , -- In  :
                FBK_ACK         => fifo_stream_ack  (i), -- Out :
                FBK_DONE        => fifo_stream_done (i), -- Out :
                FBK_OUT_START   => feedback_out_start  , -- In  :
                FBK_OUT_SIZE    => feedback_out_size   , -- In  :
                FBK_OUT_LAST    => feedback_out_last   , -- In  :
                FBK_IN_WORD     => feedback_word       , -- In  :
                FBK_IN_LAST     => feedback_last       , -- In  :
                FBK_IN_VALID    => feedback_valid   (i), -- In  :
                FBK_IN_READY    => feedback_ready   (i), -- Out :
                MRG_REQ         => fifo_merge_req      , -- In  :
                MRG_ACK         => fifo_merge_ack   (i), -- Out :
                MRG_IN_WORD     => mrg_in_word         , -- In  :
                MRG_IN_EBLK     => MRG_IN_EBLK      (i), -- In  :
                MRG_IN_LAST     => MRG_IN_LAST      (i), -- In  :
                MRG_IN_VALID    => MRG_IN_VALID     (i), -- In  :
                MRG_IN_READY    => MRG_IN_READY     (i), -- Out :
                MRG_IN_LEVEL    => MRG_IN_LEVEL     (i), -- Out :
                OUTLET_WORD     => fifo_intake_word ((i+1)*WORD_BITS-1 downto i*WORD_BITS), -- Out :
                OUTLET_INFO     => fifo_intake_info ((i+1)*INFO_BITS-1 downto i*INFO_BITS), -- Out :
                OUTLET_LAST     => fifo_intake_last (i), -- Out :
                OUTLET_VALID    => fifo_intake_valid(i), -- Out :
                OUTLET_READY    => fifo_intake_ready(i)  -- In  :
            );                                           -- 
    end generate;                                        -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    INTAKE_WORD_SELECT: block
    begin
        sort_intake_word    <= stream_intake_word  or fifo_intake_word;
        sort_intake_info    <= stream_intake_info  or fifo_intake_info;
        sort_intake_last    <= stream_intake_last  or fifo_intake_last;
        sort_intake_valid   <= stream_intake_valid or fifo_intake_valid;
        stream_intake_ready <= sort_intake_ready;
        fifo_intake_ready   <= sort_intake_ready;
    end block;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    SORT: block                                          -- 
    begin                                                -- 
        TREE: Single_Word_Tree                           -- 
            generic map (                                --
                WORD_PARAM      => WORD_PARAM          , -- 
                WAYS            => MRG_WAYS            , -- 
                SORT_ORDER      => SORT_ORDER          , -- 
                QUEUE_SIZE      => 2                   , -- 
                INFO_BITS       => INFO_BITS             -- 
            )                                            -- 
            port map (                                   -- 
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
                I_WORD          => sort_intake_word    , -- In  :
                I_INFO          => sort_intake_info    , -- In  :
                I_LAST          => sort_intake_last    , -- In  :
                I_VALID         => sort_intake_valid   , -- In  :
                I_READY         => sort_intake_ready   , -- Out :
                O_WORD          => sort_outlet_word    , -- Out :
                O_INFO          => sort_outlet_info    , -- Out :
                O_LAST          => sort_outlet_last    , -- Out :
                O_VALID         => sort_outlet_valid   , -- Out :
                O_READY         => sort_outlet_ready     -- In  :
            );                                           -- 
    end block;                                           -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    FEEDBACK_ON: if (STM_IN_ENABLE = TRUE and STM_FEEDBACK > 0) generate
        signal    queue_i_mask          :  std_logic_vector(MRG_WAYS-1 downto 0);
        signal    queue_i_valid         :  std_logic;
        signal    queue_i_ready         :  std_logic;
        signal    queue_o_mask          :  std_logic_vector(MRG_WAYS-1 downto 0);
        signal    queue_o_valid         :  std_logic;
        signal    queue_o_ready         :  std_logic;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (sort_outlet_info)
            variable num : unsigned(MRG_WAYS_BITS-1 downto 0);
        begin
            num := to_01(unsigned(sort_outlet_info(INFO_FBK_NUM_HI downto INFO_FBK_NUM_LO)), '0');
            for i in queue_i_mask'range loop
                if (i = num) then
                    queue_i_mask(i) <= '1';
                else
                    queue_i_mask(i) <= '0';
                end if;
            end loop;
        end process;
        sort_outlet_ready <= '1' when (sort_outlet_info(INFO_FBK_POS) = '0' and outlet_i_ready    = '1') or
                                      (sort_outlet_info(INFO_FBK_POS) = '1' and queue_i_ready     = '1') else '0';
        outlet_i_valid    <= '1' when (sort_outlet_info(INFO_FBK_POS) = '0' and sort_outlet_valid = '1') else '0';
        queue_i_valid     <= '1' when (sort_outlet_info(INFO_FBK_POS) = '1' and sort_outlet_valid = '1') else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        QUEUE: Word_Queue                                -- 
            generic map (                                --
                WORD_PARAM      => WORD_PARAM          , -- 
                QUEUE_SIZE      => 2                   , -- 
                INFO_BITS       => MRG_WAYS              -- 
            )                                            -- 
            port map (                                   -- 
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
                I_WORD          => sort_outlet_word    , -- In  :
                I_INFO          => queue_i_mask        , -- In  :
                I_LAST          => sort_outlet_last    , -- In  :
                I_VALID         => queue_i_valid       , -- In  :
                I_READY         => queue_i_ready       , -- Out :
                O_WORD          => feedback_word       , -- Out :
                O_INFO          => queue_o_mask        , -- Out :
                O_LAST          => feedback_last       , -- Out :
                O_VALID         => queue_o_valid       , -- Out :
                O_READY         => queue_o_ready         -- In  :
            );                                           --
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        feedback_valid <= queue_o_mask when (queue_o_valid = '1') else (others => '0');
        queue_o_ready  <= or_reduce(queue_o_mask and feedback_ready);
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    FEEDBACK_OFF: if (STM_IN_ENABLE = FALSE or STM_FEEDBACK = 0) generate
        outlet_i_valid    <= sort_outlet_valid;
        sort_outlet_ready <= outlet_i_ready;
        feedback_word     <= (others => '0');
        feedback_valid    <= (others => '0');
        feedback_last     <= '0';
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    OUTLET: block
        signal    outlet_o_word  :  std_logic_vector(WORD_PARAM.BITS-1 downto 0);
        signal    outlet_o_last  :  std_logic;
        signal    outlet_o_valid :  std_logic;
        signal    outlet_o_ready :  std_logic;
        signal    stream_q_valid :  std_logic;
        signal    stream_q_ready :  std_logic;
        signal    merge_q_valid  :  std_logic;
        signal    merge_q_ready  :  std_logic;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        outlet_i_word <= sort_outlet_word;
        outlet_i_eblk <= sort_outlet_info(INFO_EBLK_POS);
        outlet_i_last <= '1' when (sort_outlet_last = '1' and outlet_i_eblk = '1') else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        QUEUE: Drop_None                                     -- 
            generic map (                                    -- 
                WORD_PARAM      => WORD_PARAM              , -- 
                INFO_BITS       => 1                         -- 
            )                                                -- 
            port map (                                       -- 
                CLK             => CLK                     , -- In  :
                RST             => RST                     , -- In  :
                CLR             => CLR                     , -- In  :
                I_WORD          => outlet_i_word           , -- In  :
                I_INFO          => "0"                     , -- In  :
                I_LAST          => outlet_i_last           , -- In  :
                I_VALID         => outlet_i_valid          , -- In  :
                I_READY         => outlet_i_ready          , -- Out :
                O_WORD          => outlet_o_word           , -- Out :
                O_INFO          => open                    , -- Out :
                O_LAST          => outlet_o_last           , -- Out :
                O_VALID         => outlet_o_valid          , -- Out :
                O_READY         => outlet_o_ready            -- In  :
            );                                               --
        outlet_o_ready <= stream_q_ready or merge_q_ready;   -- 
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        STM_ON: if (STM_IN_ENABLE = TRUE) generate
            signal   stream_o_done :  std_logic;
            signal   stream_q_done :  std_logic;
        begin 
            STM_OUT_DATA    <= outlet_o_word(WORD_PARAM.DATA_HI downto WORD_PARAM.DATA_LO);
            STM_OUT_LAST    <= outlet_o_last;
            STM_OUT_VALID   <= stream_q_valid;
            stream_q_valid  <= '1' when (stream_out_req = '1' and outlet_o_valid = '1') else '0';
            stream_q_ready  <= '1' when (stream_out_req = '1' and STM_OUT_READY  = '1') else '0';
            stream_o_done   <= '1' when (stream_q_valid = '1' and stream_q_ready = '1' and outlet_o_last = '1') else '0';
            stream_out_done <= '1' when (stream_out_req = '1' and stream_o_done  = '1') or
                                        (stream_out_req = '1' and stream_q_done  = '1') else '0';
            process (CLK, RST) begin
                if (RST = '1') then
                    stream_q_done <= '0';
                elsif (CLK'event and CLK = '1') then
                    if (CLR = '1' or stream_out_req = '0') then
                        stream_q_done <= '0';
                    else
                        stream_q_done <= stream_o_done;
                    end if;
                end if;
            end process;
        end generate;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        STM_OFF: if (STM_IN_ENABLE = FALSE) generate
            STM_OUT_DATA    <= (others => '0');
            STM_OUT_LAST    <= '0';
            STM_OUT_VALID   <= '0';
            stream_q_valid  <= '0';
            stream_q_ready  <= '0';
            stream_out_done <= '0';
        end generate;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        MRG_ON: if (MRG_IN_ENABLE = TRUE) generate
            signal   merge_o_done :  std_logic;
            signal   merge_q_done :  std_logic;
        begin
            MRG_OUT_DATA    <= outlet_o_word(WORD_PARAM.DATA_HI downto WORD_PARAM.DATA_LO);
            MRG_OUT_LAST    <= outlet_o_last;
            MRG_OUT_VALID   <= merge_q_valid;
            merge_q_valid   <= '1' when (merge_out_req = '1' and outlet_o_valid = '1') else '0';
            merge_q_ready   <= '1' when (merge_out_req = '1' and MRG_OUT_READY  = '1') else '0';
            merge_o_done    <= '1' when (merge_q_valid = '1' and merge_q_ready  = '1' and outlet_o_last = '1') else '0';
            merge_out_done  <= '1' when (merge_out_req = '1' and merge_o_done   = '1') or
                                        (merge_out_req = '1' and merge_q_done   = '1') else '0';
            process (CLK, RST) begin
                if (RST = '1') then
                    merge_q_done <= '0';
                elsif (CLK'event and CLK = '1') then
                    if (CLR = '1' or merge_out_req = '0') then
                        merge_q_done <= '0';
                    else
                        merge_q_done <= merge_o_done;
                    end if;
                end if;
            end process;
        end generate;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        MRG_OFF: if (MRG_IN_ENABLE = FALSE) generate
            MRG_OUT_DATA    <= (others => '0');
            MRG_OUT_LAST    <= '0';
            MRG_OUT_VALID   <= '0';
            merge_q_valid   <= '0';
            merge_q_ready   <= '0';
            merge_out_done  <= '0';
        end generate;
    end block;
end RTL;