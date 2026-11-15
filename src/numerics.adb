package body Numerics is

   --  Internal CORDIC datapath: wider than Fixed_16_16 so the atan table
   --  and shift steps carry sub-LSB precision (the software equivalent of
   --  the extra pipeline bits a hardware CORDIC core uses). I/O stays
   --  Fixed_16_16. The range holds pre-fold angles up to ~32 rad (~5
   --  turns; larger inputs raise Constraint_Error) and post-fold Z up to
   --  ~Pi + convergence bound; 6 integer bits + 24 fraction bits = 30
   --  bits, so GNAT can keep all arithmetic in 32-bit integers.
   --  TODO: Not sure if this is within spec for types
   type Wide is delta 2.0 ** (-24) range -32.0 .. 32.0;

   function Sin_Cos (Angle : Fixed_16_16) return Sin_Cos_Pair is
      --  atan (2**-I) for I = 0..19, rounded to nearest Wide small.
      Atan : constant array (Integer range 0 .. 19) of Wide :=
         (0.7853981633974483,
          0.4636476090008061,
          0.2449786631268641,
          0.1243549945467614,
          0.0624188099959573,
          0.0312398334302682,
          0.0156237286204768,
          0.0078123410601013,
          0.0039062301319670,
          0.0019531225164788,
          0.0009765621895593,
          0.0004882812111949,
          0.0002441406201494,
          0.0001220703118937,
          0.0000610351561742,
          0.0000305175781155,
          0.0000152587890679,
          0.0000076293945314,
          0.0000038146972656,
          0.0000019073496329);

      --  CORDIC gain for 20 iterations: prod (1/sqrt (1 + 2**(-2*I))).
      Gain : constant Wide := 0.6072529350088813;

      Pi      : constant Wide := 3.1415926535897932;
      Half_Pi : constant Wide := 1.5707963267948966;
      Two_Pi  : constant Wide := 6.2831853071795865;

      X      : Wide := Gain;
      Y      : Wide := 0.0;
      Z      : Wide := Wide (Angle);
      X_Old  : Wide;
      Negate : Boolean := False;
   begin
      --  Fold the angle into [-Pi/2, +Pi/2], the CORDIC convergence range.
      while Z > Pi loop
         Z := Z - Two_Pi;
      end loop;
      while Z < -Pi loop
         Z := Z + Two_Pi;
      end loop;
      if Z > Half_Pi then
         Z := Z - Pi;
         Negate := True;
      elsif Z < -Half_Pi then
         Z := Z + Pi;
         Negate := True;
      end if;

      --  Rotate (Gain, 0) by the residual angle. Dividing by 2**I is the
      --  shift step; exact for a binary fixed point type.
      for I in Integer range 0 .. 19 loop
         if Z > 0.0 then
            X_Old := X;
            X := X - Y / 2**I;
            Y := Y + X_Old / 2**I;
            Z := Z - Atan (I);
         else
            X_Old := X;
            X := X + Y / 2**I;
            Y := Y - X_Old / 2**I;
            Z := Z + Atan (I);
         end if;
      end loop;

      --  Undo the quadrant fold: both outputs flip sign past +/- Pi/2.
      if Negate then
         return (Sin => Fixed_16_16 (-Y), Cos => Fixed_16_16 (-X));
      else
         return (Sin => Fixed_16_16 (Y), Cos => Fixed_16_16 (X));
      end if;
   end Sin_Cos;

end Numerics;
