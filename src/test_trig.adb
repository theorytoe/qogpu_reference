with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Ada.Text_IO;
with Numerics;
with Types;

--  Validation harness for Numerics.Sin_Cos. Sweeps angles and compares
--  the fixed-point results against the Float oracle from
--  Ada.Numerics.Elementary_Functions. The Float oracle lives ONLY here;
--  the library itself is fixed-point add/shift only.
--
--  The reference uses the QUANTIZED angle (Fixed_16_16 (Deg) radians), so
--  the measured error is pure CORDIC error, not test-side input rounding.
--  The quantization floor is 0.5 ulp; pass threshold is 2 ulp.

procedure Test_Trig is
   use Ada.Numerics.Elementary_Functions;
   use Ada.Text_IO;
   use Numerics;
   use Types;

   Ulp : constant Float := 2.0 ** (-16);
   Tol : constant := 2.0;

   --  Sweep Deg from First to Last (Step at a time) and report the worst
   --  sin/cos deviation from the oracle, in ulp.
   function Sweep
      (Label         : String;
       First, Last   : Integer;
       Step          : Integer) return Boolean
   is
      Max_S : Float  := 0.0;
      Max_C : Float  := 0.0;
      Worst : Integer := First;
      Deg   : Integer := First;
   begin
      while Deg <= Last loop
         declare
            Ang : constant Float := Float (Deg) * Ada.Numerics.Pi / 180.0;
            A   : constant Fixed_16_16 := Fixed_16_16 (Ang);
            ES  : constant Float :=
               abs (Float (Sin16 (A)) - Sin (Float (A)));
            EC  : constant Float :=
               abs (Float (Cos16 (A)) - Cos (Float (A)));
         begin
            if ES > Max_S then
               Max_S := ES;
               Worst := Deg;
            end if;
            if EC > Max_C then
               Max_C := EC;
               Worst := Deg;
            end if;
         end;
         Deg := Deg + Step;
      end loop;

      Put (Label
           & ": max sin err" & Float'Image (Max_S) & " ("
           & Float'Image (Max_S / Ulp) & " ulp), max cos err"
           & Float'Image (Max_C) & " ("
           & Float'Image (Max_C / Ulp) & " ulp), worst"
           & Integer'Image (Worst) & " deg");
      New_Line;
      return Max_S <= Tol * Ulp and Max_C <= Tol * Ulp;
   end Sweep;

   Ok : Boolean := True;
begin
   --  Primary sweep: just under one full turn, covers the quadrant fold.
   Ok := Sweep ("fine sweep  (-359..359, step 1)", -359, 359, 1) and Ok;
   --  Multi-turn sweep: several wraps through the fold loops, staying
   --  inside the datapath's ~+/-32 rad pre-fold range.
   Ok := Sweep ("turns sweep (-1755..1755, step 37)", -1755, 1755, 37)
      and Ok;

   Put_Line (if Ok then "PASS" else "FAIL");
   Ada.Command_Line.Set_Exit_Status
      (if Ok then Ada.Command_Line.Success
       else Ada.Command_Line.Failure);
end Test_Trig;
