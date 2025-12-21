# Clock Architecture

Consistent with the synchronous design conventions established in NUS CG3207, the Mach-V processor operates within a single clock domain. All registers and sequential logic are driven by a single global clock signal to simplify timing analysis.

## Clock Frequency Scaling

<!-- md:version 2.0 -->
<!-- md:plugin -->
<!-- md:feature -->

The default clock is only 100MHz maximum. To improve the performance of Mach-V, I utilize the AMD Clocking Wizard IP core to synthesize a higher frequency clock from this base input.

### Generate the IP Core

To use the IP in Vivado, click the "IP Catalog" on the left flow navigator. Then, search for "clocking wizard". Click the only option available. And then configure the IP to use the following settings:

1. In the "Clocking Options" tab:
    - Make sure the primary input clock is `clk_in1` with a frequency of `100 MHz`.
    - Make sure the primary input clock source is "Single ended clock capable pin".
2. In the "Output Clocks" tab:
    - Click the `clk_out1` and set the frequency that you want to achieve.
    - Make sure the "Reset Type" is set to "Active High".
    - Make sure the "locked" option is enabled under the "Enable Optional Inputs".

### Use the IP Core

The clock generation logic must be instantiated in the top-level entity (TOP_Nexys.vhd).

---

#### Component Declaration

Add the component declaration before the architecture begin keyword:

```vhdl title="Top_Nexys.vhd"
----------------------------------------------------------------------------
-- Component: Clocking Wizard
----------------------------------------------------------------------------
component clk_wiz_0
port (
    -- Clock in ports
    clk_in1  : in  std_logic;
    -- Clock out ports
    clk_out1 : out std_logic;
    -- Status and control signals
    reset    : in  std_logic;
    locked   : out std_logic
);
end component;

----------------------------------------------------------------------------
-- Signals: Clock & Reset Management
----------------------------------------------------------------------------
signal clk_sys    : std_logic; -- The synthesized high-speed system clock
signal clk_locked : std_logic; -- High ('1') when the clock is stable
signal sys_reset  : std_logic; -- Combined effective system reset
```

---

#### Instantiation

Instantiate the IP core within the architecture body, mapping the board's raw clock to the input:

```vhdl title="Top_Nexys.vhd"
----------------------------------------------------------------
-- Instance: Clocking Wizard
----------------------------------------------------------------
clk_wiz_inst : clk_wiz_0
port map ( 
    clk_in1  => CLK_undiv,  -- Raw 100MHz from physical board pin
    clk_out1 => clk_sys,    -- Synthesized Fast Clock
    reset    => RESET,      -- Raw button reset (Active High)
    locked   => clk_locked  -- Status signal
);
```

---

#### System Reset Logic

It is critical to hold the processor in reset until the clock signal is stable. The `locked` signal from the Clocking Wizard indicates when the output frequency is stable.

I generate a `RESET_EFF` (Effective Reset) signal that is asserted (High) if either:

1. The physical reset button is pressed (`RESET_INT` / `RESET_EXT`).
2. The clock is not yet locked (not `clk_locked`).

```vhdl title="Top_Nexys.vhd"
-- Original Logic (Raw Button only)
-- RESET_EFF <= RESET_INT or RESET_EXT;

-- New Logic (Button + Clock Stability Guard)
RESET_EFF <= RESET_INT or RESET_EXT or (not clk_locked);
```

---

#### Frequency Constant Update

Finally, ensure the software-visible frequency constant matches the new hardware configuration. This is often used for UART baud rate calculations or timer peripherals.

```vhdl title="Top_Nexys.vhd"
-- Update this value to match the Clocking Wizard output
constant CLOCK_FREQUENCY : positive := 115000000;
```

!!! warning
    The `CLOCK_FREQUENCY` constant is not automatically linked to the IP Core settings. If you reconfigure the Clocking Wizard to a different frequency (e.g., changing from 120MHz to 150MHz), you **must manually update** the `CLOCK_FREQUENCY` constant in `TOP_Nexys.vhd` to ensure correct timing for peripherals like UART.
