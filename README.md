clocksync
=========

Basic, self-contained example of synchronizing two clocks.

In many cases it is important to be able to lock the frequency and phase of a clock to a
second reference clock. Communications systems are often required to do this to properly
receive incoming data. Measurement systems may need to do this to synchronize measurements
to an external reference. In my particular case, I am interested in synchronizing a
high-speed clock inside an FPGA to a PPS signal from a GPS module, to allow for very
accurate timing of an ADC.

Note that this is essentially what a PLL does.

The code in this repository is a very basic example of how two clocks can be made to run
in sync. The example is self-contained, in that it requires only an FPGA and a single
clock, but this also means it is not entirely complete as the two test clock signals are
actually derived from a common source. A more advanced example would use an external
free-running clock to show how the slave clock follows dynamic changes in the reference
clock.

What this code does:
* Two clocks are generated from the master FPGA clock, both with a rate of about 1.5 kHz
  but of course with a slight difference. One of these two is a digital VCO, with the
  instantaneous frequency controlled by a setpoint value.
* A phase detector block returns a signed value: the number of ticks between the rising
  edges of the two clocks. The sign indicates which clock leads.
* The phase difference is fed into a PID controller that sets the rate of one of the two
  clocks by varying the reset value of the clock divider counter.
  * The phase can be used as is (proportional control) to modify the set point, allowing
    the two clocks to lock. There will be a non-zero phase error on lock, however: see PID
    theory and *droop* for a further explanation.
  * A counter, updated only on the rising edge of the reference clock, is used to
    implement an integrator. Properly weighted, this makes it possible to compensate
    for the offset between the two clocks, allowing the system to lock with zero phase
    error.
  * A fixed bias is also included, which without additional feedback will set the
    VCO to about 1.5 kHz. This improves the speed of locking, but could be replaced with
    a forward-fed measurement of the reference clock frequency.
