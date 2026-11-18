with Ada.Unchecked_Conversion;
with Interfaces;

package body Numerics is

   --  Internal CORDIC datapath: a 32-bit register pattern holding a raw
   --  fixed-point value with 24 fraction bits and 6 integer bits (range
   --  about +/-32.0, covering pre-fold angles up to ~5 turns). Add and
   --  subtract on the modular type produce the two's-complement pattern a
   --  signed adder would, and modular 'Shift_Right_Arithmetic is the
   --  sign-replicating shifter -- so add/subtract + shift are the only
   --  datapath operations. No multiply, divide, or exponentiation runs
   --  here; extra fraction bits carry sub-LSB precision the way a
   --  hardware CORDIC core widens its pipeline behind its 16.16 ports.
   subtype I32 is Interfaces.Integer_32;
   subtype Raw is Interfaces.Unsigned_32;
   use type I32;
   use type Raw;
   use Interfaces;

   --  Reinterpret the same register bits as signed at the I/O ports.
   function To_Pattern is new Ada.Unchecked_Conversion (I32, Raw);
   function To_Signed is new Ada.Unchecked_Conversion (Raw, I32);

   function Is_Neg (V : Raw) return Boolean is
      (V >= 16#8000_0000#);

   --  Exact Fixed_16_16 quantum: 1 / 65536 = 2**-16. Used only at the
   --  boundary to reinterpret a raw scaled integer as a real value.
   Quantum : constant Fixed_16_16 := Fixed_16_16 (1) / 65536;

   function Sin_Cos (Angle : Fixed_16_16) return Sin_Cos_Pair is
      --  atan (2**-I), scaled by 2**24 and rounded to nearest. From I = 8
      --  up the true value rounds to an exact power of two.
      Atan : constant array (Integer range 0 .. 19) of Raw :=
         (16#0C90FDB#,   --  0.7853981633974483
          16#076B19C#,   --  0.4636476090008061
          16#03EB6EC#,   --  0.2449786631268641
          16#01FD5BB#,   --  0.1243549945467614
          16#00FFAAE#,   --  0.0624188099959573
          16#007FF55#,   --  0.0312398334302682
          16#003FFEB#,   --  0.0156237286204768
          16#001FFFD#,   --  0.0078123410601013
          16#0010000#,   --  0.0039062301319670
          16#0008000#,   --  0.0019531225164788
          16#0004000#,   --  0.0009765621895593
          16#0002000#,   --  0.0004882812111949
          16#0001000#,   --  0.0002441406201494
          16#0000800#,   --  0.0001220703118937
          16#0000400#,   --  0.0000610351561742
          16#0000200#,   --  0.0000305175781155
          16#0000100#,   --  0.0000152587890613
          16#0000080#,   --  0.0000076293945311
          16#0000040#,   --  0.0000038146972656
          16#0000020#);  --  0.0000019073486328

      --  CORDIC gain for 20 iterations: prod (1/sqrt (1 + 2**(-2*I))).
      Gain    : constant Raw := 16#09B74EE#;   --  0.6072529350088813

      Pi      : constant Raw := 16#03243F6B#;  --  3.1415926535897932
      Half_Pi : constant Raw := 16#01921FB5#;  --  1.5707963267948966
      Two_Pi  : constant Raw := 16#06487ED5#;  --  6.2831853071795865

      --  Round a raw 24-bit-fraction value to the nearest Fixed_16_16
      --  small: add 128 (half of 256) to the magnitude, then drop the low
      --  8 bits. The final * Quantum is an exact representation access
      --  (scaled integer -> real value), not datapath arithmetic.
      function To_Fixed_16_16 (V : Raw) return Fixed_16_16 is
         Mag : constant Raw := (if Is_Neg (V) then 0 - V else V);
         Res : constant Raw := Shift_Right (Mag + 128, 8);
      begin
         return
            Fixed_16_16
               (Integer (To_Signed (if Is_Neg (V) then 0 - Res else Res)) *
                Quantum);
      end To_Fixed_16_16;

      --  In boundary: Fixed_16_16 -> raw. Dividing by 'Small is the exact
      --  representation access (real value -> count of quanta); the shift
      --  widens 16 fraction bits to 24.
      Z : Raw :=
         Shift_Left (To_Pattern (I32 (Angle / Fixed_16_16'Small)), 8);

      X      : Raw := Gain;
      Y      : Raw := 0;
      X_Old  : Raw;
      Negate : Boolean := False;
   begin
      --  Fold the angle into [-Pi/2, +Pi/2], the CORDIC convergence range.
      while not Is_Neg (Z) and Z > Pi loop
         Z := Z - Two_Pi;
      end loop;
      while Is_Neg (Z) and Pi < 0 - Z loop
         Z := Z + Two_Pi;
      end loop;
      if not Is_Neg (Z) and Z > Half_Pi then
         Z := Z - Pi;
         Negate := True;
      elsif Is_Neg (Z) and Half_Pi < 0 - Z then
         Z := Z + Pi;
         Negate := True;
      end if;

      --  Rotate (Gain, 0) by the residual angle: shift + add only.
      --  'Shift_Right_Arithmetic replicates the sign bit, matching the
      --  arithmetic shifter of a hardware core (exact for I <= 24).
      for I in Integer range 0 .. 19 loop
         if not Is_Neg (Z) then
            X_Old := X;
            X := X - Shift_Right_Arithmetic (Y, I);
            Y := Y + Shift_Right_Arithmetic (X_Old, I);
            Z := Z - Atan (I);
         else
            X_Old := X;
            X := X + Shift_Right_Arithmetic (Y, I);
            Y := Y - Shift_Right_Arithmetic (X_Old, I);
            Z := Z + Atan (I);
         end if;
      end loop;

      --  Undo the quadrant fold: both outputs flip sign past +/- Pi/2.
      if Negate then
         X := 0 - X;
         Y := 0 - Y;
      end if;

      return (Sin => To_Fixed_16_16 (Y), Cos => To_Fixed_16_16 (X));
   end Sin_Cos;

end Numerics;
