with Types;

--  Fixed-point math primitives. Everything works on Types.Fixed_16_16
--  only: no Float, no Ada.Numerics library calls. Trigonometry is CORDIC
--  (rotation mode), which is shift/add only -- the same algorithm an FPGA
--  core can synthesize directly.
package Numerics is
   use Types;

   type Sin_Cos_Pair is record
      Sin, Cos : Fixed_16_16;
   end record;

   --  Compute Sin and Cos together (CORDIC yields both at once; calling
   --  Sin16 and Cos16 separately would run the iteration twice).
   function Sin_Cos (Angle : Fixed_16_16) return Sin_Cos_Pair;

   --  Convenience wrappers around Sin_Cos.
   function Sin16 (Angle : Fixed_16_16) return Fixed_16_16 is
      (Sin_Cos (Angle).Sin);

   function Cos16 (Angle : Fixed_16_16) return Fixed_16_16 is
      (Sin_Cos (Angle).Cos);

end Numerics;
