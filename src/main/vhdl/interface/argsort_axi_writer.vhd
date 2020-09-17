-----------------------------------------------------------------------------------
--!     @file    argsort_axi_writer.vhd
--!     @brief   Merge Sorter ArgSort AXI Writer Module :
--!     @version 0.2.0
--!     @date    2018/7/18
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2018 Ichiro Kawazome
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
use     Merge_Sorter.Interface;
entity  ArgSort_AXI_Writer is
    generic (
        REG_PARAM       :  Interface.Regs_Field_Type := Interface.Default_Regs_Param;
        AXI_ID          :  integer :=  1;
        AXI_ID_WIDTH    :  integer :=  8;
        AXI_AUSER_WIDTH :  integer :=  4;
        AXI_WUSER_WIDTH :  integer :=  4;
        AXI_BUSER_WIDTH :  integer :=  4;
        AXI_ADDR_WIDTH  :  integer := 32;
        AXI_DATA_WIDTH  :  integer := 64;
        MAX_XFER_SIZE   :  integer := 12;
        STM_NUM         :  integer :=  1;
        STM_DATA_BITS   :  integer := 64;
        STM_INDEX_LO    :  integer :=  0;
        STM_INDEX_HI    :  integer := 31;
        STM_COMP_LO     :  integer := 32;
        STM_COMP_HI     :  integer := 63
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock/Reset Signals.
    -------------------------------------------------------------------------------
        CLK             :  in  std_logic;
        RST             :  in  std_logic;
        CLR             :  in  std_logic;
    -------------------------------------------------------------------------------
    -- Register Interface
    -------------------------------------------------------------------------------
        REG_L           :  in  std_logic_vector(REG_PARAM.BITS  -1 downto 0);
        REG_D           :  in  std_logic_vector(REG_PARAM.BITS  -1 downto 0);
        REG_Q           :  out std_logic_vector(REG_PARAM.BITS  -1 downto 0);
    -------------------------------------------------------------------------------
    -- AXI Master Writer Address Channel Signals.
    -------------------------------------------------------------------------------
        AXI_AWID        :  out std_logic_vector(AXI_ID_WIDTH    -1 downto 0);
        AXI_AWADDR      :  out std_logic_vector(AXI_ADDR_WIDTH  -1 downto 0);
        AXI_AWLEN       :  out std_logic_vector(7 downto 0);
        AXI_AWSIZE      :  out std_logic_vector(2 downto 0);
        AXI_AWBURST     :  out std_logic_vector(1 downto 0);
        AXI_AWLOCK      :  out std_logic_vector(0 downto 0);
        AXI_AWCACHE     :  out std_logic_vector(3 downto 0);
        AXI_AWPROT      :  out std_logic_vector(2 downto 0);
        AXI_AWQOS       :  out std_logic_vector(3 downto 0);
        AXI_AWREGION    :  out std_logic_vector(3 downto 0);
        AXI_AWUSER      :  out std_logic_vector(AXI_AUSER_WIDTH -1 downto 0);
        AXI_AWVALID     :  out std_logic;
        AXI_AWREADY     :  in  std_logic;
    ------------------------------------------------------------------------------
    -- AXI Master Write Data Channel Signals.
    ------------------------------------------------------------------------------
        AXI_WID         :  out std_logic_vector(AXI_ID_WIDTH    -1 downto 0);
        AXI_WDATA       :  out std_logic_vector(AXI_DATA_WIDTH  -1 downto 0);
        AXI_WSTRB       :  out std_logic_vector(AXI_DATA_WIDTH/8-1 downto 0);
        AXI_WUSER       :  out std_logic_vector(AXI_WUSER_WIDTH -1 downto 0);
        AXI_WLAST       :  out std_logic;
        AXI_WVALID      :  out std_logic;
        AXI_WREADY      :  in  std_logic;
    ------------------------------------------------------------------------------
    -- AXI Write Response Channel Signals.
    ------------------------------------------------------------------------------
        AXI_BID         :  in  std_logic_vector(AXI_ID_WIDTH    -1 downto 0);
        AXI_BRESP       :  in  std_logic_vector(1 downto 0);
        AXI_BUSER       :  in  std_logic_vector(AXI_BUSER_WIDTH -1 downto 0);
        AXI_BVALID      :  in  std_logic;
        AXI_BREADY      :  out std_logic;
    -------------------------------------------------------------------------------
    -- Merge Outlet Signals.
    -------------------------------------------------------------------------------
        STM_DATA        :  in  std_logic_vector(STM_NUM*STM_DATA_BITS  -1 downto 0);
        STM_STRB        :  in  std_logic_vector(STM_NUM*STM_DATA_BITS/8-1 downto 0);
        STM_LAST        :  in  std_logic;
        STM_VALID       :  in  std_logic;
        STM_READY       :  out std_logic;
    -------------------------------------------------------------------------------
    -- Status Output.
    -------------------------------------------------------------------------------
        BUSY            :  out std_logic;
        DONE            :  out std_logic
    );
end ArgSort_AXI_Writer;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library Merge_Sorter;
use     Merge_Sorter.Interface;
use     Merge_Sorter.Interface_Components.ArgSort_Writer;
library PIPEWORK;
use     PIPEWORK.AXI4_COMPONENTS.AXI4_MASTER_WRITE_INTERFACE;
architecture RTL of ArgSort_AXI_Writer is
    ------------------------------------------------------------------------------
    -- 
    ------------------------------------------------------------------------------
    constant  BUF_DATA_BITS     :  integer := AXI_DATA_WIDTH;
    constant  BUF_DEPTH         :  integer := MAX_XFER_SIZE+1;
    constant  XFER_SIZE_BITS    :  integer := BUF_DEPTH+1;
    constant  REQ_SIZE_BITS     :  integer := REG_PARAM.SIZE_BITS;
    constant  REQ_MODE_BITS     :  integer := REG_PARAM.MODE_BITS;
    ------------------------------------------------------------------------------
    -- 
    ------------------------------------------------------------------------------
    constant  REQ_ID            :  std_logic_vector(AXI_ID_WIDTH   -1 downto 0)
                                := std_logic_vector(to_unsigned(AXI_ID, AXI_ID_WIDTH));
    constant  REQ_LOCK          :  std_logic_vector(0 downto 0) := (others => '0');
    constant  REQ_PROT          :  std_logic_vector(2 downto 0) := (others => '0');
    constant  REQ_QOS           :  std_logic_vector(3 downto 0) := (others => '0');
    constant  REQ_REGION        :  std_logic_vector(3 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    req_addr          :  std_logic_vector(AXI_ADDR_WIDTH -1 downto 0);
    signal    req_size          :  std_logic_vector(REQ_SIZE_BITS  -1 downto 0);
    signal    req_buf_ptr       :  std_logic_vector(BUF_DEPTH      -1 downto 0);
    signal    req_mode          :  std_logic_vector(REQ_MODE_BITS  -1 downto 0);
    signal    req_cache         :  std_logic_vector(3 downto 0);
    signal    req_speculative   :  std_logic;
    signal    req_safety        :  std_logic;
    signal    req_first         :  std_logic;
    signal    req_last          :  std_logic;
    signal    req_valid         :  std_logic;
    signal    req_ready         :  std_logic;
    signal    xfer_busy         :  std_logic;
    signal    xfer_done         :  std_logic;
    signal    xfer_error        :  std_logic;
    signal    ack_valid         :  std_logic;
    signal    ack_error         :  std_logic;
    signal    ack_next          :  std_logic;
    signal    ack_last          :  std_logic;
    signal    ack_stop          :  std_logic;
    signal    ack_none          :  std_logic;
    signal    ack_size          :  std_logic_vector(XFER_SIZE_BITS -1 downto 0);
    signal    flow_pause        :  std_logic;
    signal    flow_stop         :  std_logic;
    signal    flow_last         :  std_logic;
    signal    flow_size         :  std_logic_vector(XFER_SIZE_BITS -1 downto 0);
    signal    pull_fin_valid    :  std_logic;
    signal    pull_fin_error    :  std_logic;
    signal    pull_fin_last     :  std_logic;
    signal    pull_fin_size     :  std_logic_vector(XFER_SIZE_BITS -1 downto 0);
    signal    pull_rsv_valid    :  std_logic;
    signal    pull_rsv_error    :  std_logic;
    signal    pull_rsv_last     :  std_logic;
    signal    pull_rsv_size     :  std_logic_vector(XFER_SIZE_BITS -1 downto 0);
    signal    pull_buf_valid    :  std_logic;
    signal    pull_buf_ready    :  std_logic;
    signal    pull_buf_reset    :  std_logic;
    signal    pull_buf_error    :  std_logic;
    signal    pull_buf_last     :  std_logic;
    signal    pull_buf_size     :  std_logic_vector(XFER_SIZE_BITS -1 downto 0);
    signal    buf_ren           :  std_logic;
    signal    buf_rdata         :  std_logic_vector(BUF_DATA_BITS  -1 downto 0);
    signal    buf_rptr          :  std_logic_vector(BUF_DEPTH      -1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    AXI_IF: AXI4_MASTER_WRITER_INTERFACE                 -- 
        generic map (                                    -- 
            AXI4_ADDR_WIDTH     => AXI_ADDR_WIDTH      , -- 
            AXI4_DATA_WIDTH     => AXI_DATA_WIDTH      , -- 
            AXI4_ID_WIDTH       => AXI_ID_WIDTH        , -- 
            VAL_BITS            => 1                   , -- 
            REQ_SIZE_BITS       => REQ_SIZE_BITS       , -- 
            REQ_SIZE_VALID      => 1                   , -- 
            FLOW_VALID          => 1                   , -- 
            BUF_DATA_WIDTH      => BUF_DATA_BITS       , -- 
            BUF_PTR_BITS        => BUF_DEPTH           , -- 
            XFER_SIZE_BITS      => XFER_SIZE_BITS      , -- 
            XFER_MIN_SIZE       => MAX_XFER_SIZE       , -- 
            XFER_MAX_SIZE       => MAX_XFER_SIZE       , -- 
            REQ_REGS            => 1                   , -- 
            ACK_REGS            => 1                   , -- 
            QUEUE_SIZE          => 4                   , -- 
            RESP_REGS           => 1                     -- 
        )                                                -- 
        port map (                                       -- 
        --------------------------------------------------------------------------
        -- Clock and Reset Signals.
        --------------------------------------------------------------------------
            CLK                 => CLK                 , -- In  :
            CLR                 => CLR                 , -- In  :
            RST                 => RST                 , -- In  :
        --------------------------------------------------------------------------
        -- AXI4 Write Address Channel Signals.
        --------------------------------------------------------------------------
            AWID                => AXI_AWID            , -- Out :
            AWADDR              => AXI_AWADDR          , -- Out :
            AWLEN               => AXI_AWLEN           , -- Out :
            AWSIZE              => AXI_AWSIZE          , -- Out :
            AWBURST             => AXI_AWBURST         , -- Out :
            AWLOCK              => AXI_AWLOCK          , -- Out :
            AWCACHE             => AXI_AWCACHE         , -- Out :
            AWPROT              => AXI_AWPROT          , -- Out :
            AWQOS               => AXI_AWQOS           , -- Out :
            AWREGION            => AXI_AWREGION        , -- Out :
            AWVALID             => AXI_AWVALID         , -- Out :
            AWREADY             => AXI_AWREADY         , -- In  :
        --------------------------------------------------------------------------
        -- AXI4 Write Data Channel Signals.
        --------------------------------------------------------------------------
            WID                 => AXI_WID             , -- Out :
            WDATA               => AXI_WDATA           , -- Out :
            WSTRB               => AXI_WSTRB           , -- Out :
            WLAST               => AXI_WLAST           , -- Out :
            WVALID              => AXI_WVALID          , -- Out :
            WREADY              => AXI_WREADY          , -- In  :
        --------------------------------------------------------------------------
        -- AXI4 Write Response Channel Signals.
        --------------------------------------------------------------------------
            BID                 => AXI_BID             , -- In  :
            BRESP               => AXI_BRESP           , -- In  :
            BVALID              => AXI_BVALID          , -- In  :
            BREADY              => AXI_BREADY          , -- Out :
        ---------------------------------------------------------------------------
        -- Command Request Signals.
        ---------------------------------------------------------------------------
            REQ_ADDR            => req_addr            , -- In  :
            REQ_SIZE            => req_size            , -- In  :
            REQ_ID              => REQ_ID              , -- In  :
            REQ_BURST           => AXI4_ABURST_INCR    , -- In  :
            REQ_LOCK            => REQ_LOCK            , -- In  :
            REQ_CACHE           => req_cache           , -- In  :
            REQ_PROT            => REQ_PROT            , -- In  :
            REQ_QOS             => REQ_QOS             , -- In  :
            REQ_REGION          => REQ_REGION          , -- In  :
            REQ_BUF_PTR         => req_buf_ptr         , -- In  :
            REQ_FIRST           => req_first           , -- In  :
            REQ_LAST            => req_last            , -- In  :
            REQ_SPECULATIVE     => req_speculative     , -- In  :
            REQ_SAFETY          => req_safety          , -- In  :
            REQ_VAL(0)          => req_valid           , -- In  :
            REQ_RDY             => req_ready           , -- Out :
            XFER_SIZE_SEL       => "1"                 , -- In  :
        ---------------------------------------------------------------------------
        -- Response Signals.
        ---------------------------------------------------------------------------
            ACK_VAL(0)          => ack_valid           , -- Out :
            ACK_ERROR           => ack_error           , -- Out :
            ACK_NEXT            => ack_next            , -- Out :
            ACK_LAST            => ack_last            , -- Out :
            ACK_STOP            => ack_stop            , -- Out :
            ACK_NONE            => ack_none            , -- Out :
            ACK_SIZE            => ack_size            , -- Out :
        ---------------------------------------------------------------------------
        -- Transfer Status Signal.
        ---------------------------------------------------------------------------
            XFER_BUSY(0)        => xfer_busy           , -- Out :
            XFER_DONE(0)        => xfer_done           , -- Out :
            XFER_ERROR(0)       => xfer_error          , -- Out :
        ---------------------------------------------------------------------------
        -- Flow Control Signals.
        ---------------------------------------------------------------------------
            FLOW_PAUSE          => flow_pause          , -- In  :
            FLOW_STOP           => flow_stop           , -- In  :
            FLOW_LAST           => flow_last           , -- In  :
            FLOW_SIZE           => flow_size           , -- In  :
        ---------------------------------------------------------------------------
        -- Reserve Size Signals.
        ---------------------------------------------------------------------------
            PULL_RSV_VAL        => open                , -- Out :
            PULL_RSV_SIZE       => open                , -- Out :
            PULL_RSV_LAST       => open                , -- Out :
            PULL_RSV_ERROR      => open                , -- Out :
        ---------------------------------------------------------------------------
        -- Pull Size Signals.
        ---------------------------------------------------------------------------
            PULL_FIN_VAL(0)     => pull_fin_valid      , -- Out :
            PULL_FIN_SIZE       => pull_fin_size       , -- Out :
            PULL_FIN_LAST       => pull_fin_last       , -- Out :
            PULL_FIN_ERROR      => pull_fin_error      , -- Out :
        ---------------------------------------------------------------------------
        -- Pull Buffer Size Signals.
        ---------------------------------------------------------------------------
            PULL_BUF_RESET(0)   => pull_buf_reset      , -- Out :
            PULL_BUF_VAL(0)     => pull_buf_valid      , -- Out :
            PULL_BUF_SIZE       => pull_buf_size       , -- Out :
            PULL_BUF_LAST       => pull_buf_last       , -- Out :
            PULL_BUF_ERROR      => pull_buf_error      , -- Out :
            PULL_BUF_RDY(0)     => pull_buf_ready      , -- Out :
        ---------------------------------------------------------------------------
        -- Read Buffer Interface Signals.
        ---------------------------------------------------------------------------
            BUF_REN             => buf_ren             , -- Out :
            BUF_DATA            => buf_rdata           , -- In  :
            BUF_PTR             => buf_rptr              -- Out :
        );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    REQ_MODE_BLK: block
        constant  REQ_MODE_CACHE_HI   :  integer := REG_PARAM.MODE_CACHE_HI   - REG_PARAM.MODE_LO;
        constant  REQ_MODE_CACHE_LO   :  integer := REG_PARAM.MODE_CACHE_LO   - REG_PARAM.MODE_LO;
        constant  REQ_MODE_AUSER_HI   :  integer := REG_PARAM.MODE_AUSER_HI   - REG_PARAM.MODE_LO;
        constant  REQ_MODE_AUSER_LO   :  integer := REG_PARAM.MODE_AUSER_LO   - REG_PARAM.MODE_LO;
        constant  REQ_MODE_SPECUL_POS :  integer := REG_PARAM.MODE_SPECUL_POS - REG_PARAM.MODE_LO;
        constant  REQ_MODE_SAFETY_POS :  integer := REG_PARAM.MODE_SAFETY_POS - REG_PARAM.MODE_LO;
    begin 
        process (CLK, RST) begin
            if (RST = '1') then
                    AXI_AWUSER <= (others => '0');
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    AXI_AWUSER <= (others => '0');
                elsif (req_valid = '1' and req_ready = '1') then
                    AXI_AWUSER <= std_logic_vector(resize(unsigned(req_mode(REQ_MODE_AUSER_HI downto REQ_MODE_AUSER_LO)), AXI_AUSER_WIDTH));
                end if;
            end if;
        end process;
        req_cache       <= req_mode(REQ_MODE_CACHE_HI downto REQ_MODE_CACHE_LO);
        req_speculative <= req_mode(REQ_MODE_SPECUL_POS);
        req_safety      <= req_mode(REQ_MODE_SAFETY_POS);
    end block;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    WRITER:  ArgSort_Writer                              -- 
        generic map (                                    -- 
            REG_PARAM           => REG_PARAM           , -- 
            REQ_ADDR_BITS       => AXI_ADDR_WIDTH      , --   
            REQ_SIZE_BITS       => REQ_SIZE_BITS       , --   
            BUF_DATA_BITS       => BUF_DATA_BITS       , --   
            BUF_DEPTH           => BUF_DEPTH           , --   
            MAX_XFER_SIZE       => MAX_XFER_SIZE       , --   
            STM_NUM             => STM_NUM             , --   
            STM_DATA_BITS       => STM_DATA_BITS       , --   
            STM_INDEX_LO        => STM_INDEX_LO        , --   
            STM_INDEX_HI        => STM_INDEX_HI        , --   
            STM_COMP_LO         => STM_COMP_LO         , --   
            STM_COMP_HI         => STM_COMP_HI           --   
        )                                                -- 
        port map (                                       -- 
        -------------------------------------------------------------------------------
        -- Clock/Reset Signals.
        -------------------------------------------------------------------------------
            CLK                 => CLK                 , --  In  :
            RST                 => RST                 , --  In  :
            CLR                 => CLR                 , --  In  :
        -------------------------------------------------------------------------------
        -- Register Interface
        -------------------------------------------------------------------------------
            REG_L               => REG_L               , --  In  :
            REG_D               => REG_D               , --  In  :
            REG_Q               => REG_Q               , --  Out :
        -------------------------------------------------------------------------------
        -- Transaction Command Request Signals.
        -------------------------------------------------------------------------------
            REQ_VALID           => req_valid           , --  Out :
            REQ_ADDR            => req_addr            , --  Out :
            REQ_SIZE            => req_size            , --  Out :
            REQ_BUF_PTR         => req_buf_ptr         , --  Out :
            REQ_MODE            => req_mode            , --  Out :
            REQ_FIRST           => req_first           , --  Out :
            REQ_LAST            => req_last            , --  Out :
            REQ_READY           => req_ready           , --  In  :
        -------------------------------------------------------------------------------
        -- Transaction Command Acknowledge Signals.
        -------------------------------------------------------------------------------
            ACK_VALID           => ack_valid           , --  In  :
            ACK_SIZE            => ack_size            , --  In  :
            ACK_ERROR           => ack_error           , --  In  :
            ACK_NEXT            => ack_next            , --  In  :
            ACK_LAST            => ack_last            , --  In  :
            ACK_STOP            => ack_stop            , --  In  :
            ACK_NONE            => ack_none            , --  In  :
        -------------------------------------------------------------------------------
        -- Transfer Status Signals.
        -------------------------------------------------------------------------------
            XFER_BUSY           => xfer_busy           , --  In  :
            XFER_DONE           => xfer_done           , --  In  :
            XFER_ERROR          => xfer_error          , --  In  :
        -------------------------------------------------------------------------------
        -- Intake Flow Control Signals.
        -------------------------------------------------------------------------------
            FLOW_READY          => flow_ready          , --  Out :
            FLOW_PAUSE          => flow_pause          , --  Out :
            FLOW_STOP           => flow_stop           , --  Out :
            FLOW_LAST           => flow_last           , --  Out :
            FLOW_SIZE           => flow_size           , --  Out :
            PULL_FIN_VALID      => pull_fin_valid      , --  In  :
            PULL_FIN_LAST       => pull_fin_last       , --  In  :
            PULL_FIN_ERROR      => pull_fin_error      , --  In  :
            PULL_FIN_SIZE       => pull_fin_size       , --  In  :
            PULL_BUF_RESET      => pull_buf_reset      , --  In  :
            PULL_BUF_VALID      => pull_buf_valid      , --  In  :
            PULL_BUF_LAST       => pull_buf_last       , --  In  :
            PULL_BUF_ERROR      => pull_buf_error      , --  In  :
            PULL_BUF_SIZE       => pull_buf_size       , --  In  :
            PULL_BUF_READY      => pull_buf_ready      , --  Out :
        -------------------------------------------------------------------------------
        -- Buffer Interface Signals.
        -------------------------------------------------------------------------------
            BUF_REN             => buf_ren             , --  In  :
            BUF_DATA            => buf_rdata           , --  Out :
            BUF_PTR             => buf_rptr            , --  In  :
        -------------------------------------------------------------------------------
        -- Merge Outlet Signals.
        -------------------------------------------------------------------------------
            STM_DATA            => STM_DATA            , --  In  :
            STM_STRB            => STM_STRB            , --  In  :
            STM_LAST            => STM_LAST            , --  In  :
            STM_VALID           => STM_VALID           , --  In  :
            STM_READY           => STM_READY           , --  Out :
        -------------------------------------------------------------------------------
        -- Status Output.
        -------------------------------------------------------------------------------
            BUSY                => BUSY                , --  Out :
            DONE                => DONE                  --  Out :
        );
end RTL;