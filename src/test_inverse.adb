--  Sanity checks for Types.Det / Transpose / Inverse (adjugate method).
--
--  Strategy: for each test matrix M, form M * Inverse (M) with a plain
--  matrix multiply and check it against the identity within a fixed-point
--  tolerance. Also verifies Inverse of a pure rotation equals its
--  transpose, and that Singular_Matrix is raised for a singular input.

with Ada.Text_IO; use Ada.Text_IO;
with Types;

procedure Test_Inverse is
   use Types;

   Tol : constant Fixed_16_16 := Fixed_16_16 (2.0 ** (-13));

   ---------------------------------------------------------------------
   --  Test matrices
   ---------------------------------------------------------------------

   --  Translate (0, 0, 4).
   T4 : constant Mat4 :=
     ((1.0, 0.0, 0.0, 0.0),
      (0.0, 1.0, 0.0, 0.0),
      (0.0, 0.0, 1.0, 4.0),
      (0.0, 0.0, 0.0, 1.0));

   --  Rotation about Y by 30 degrees (orthonormal: inverse = transpose).
   C30 : constant Fixed_16_16 := Fixed_16_16 (0.866_025_4);
   S30 : constant Fixed_16_16 := Fixed_16_16 (0.5);
   RY4 : constant Mat4 :=
     (( C30, 0.0, S30, 0.0),
      (0.0, 1.0, 0.0, 0.0),
      (-S30, 0.0, C30, 0.0),
      (0.0, 0.0, 0.0, 1.0));

   --  Model-view-ish: rotation + translation + non-uniform scale.
   G4 : constant Mat4 :=
     ((Fixed_16_16 (1.0), Fixed_16_16 (2.0), 0.0, 1.0),
      (0.0, Fixed_16_16 (1.0), Fixed_16_16 (3.0), Fixed_16_16 (-2.0)),
      (Fixed_16_16 (0.5), 0.0, Fixed_16_16 (1.0), Fixed_16_16 (5.0)),
      (0.0, 0.0, 0.0, 1.0));

   --  Singular: row 3 duplicates row 1.
   Bad4 : constant Mat4 :=
     ((1.0, 0.0, 0.0, 0.0),
      (0.0, 1.0, 0.0, 0.0),
      (1.0, 0.0, 0.0, 0.0),
      (0.0, 0.0, 0.0, 1.0));

   --  Symmetric positive definite 3x3, det = 16.
   G3 : constant Mat3 :=
     ((Fixed_16_16 (2.0), Fixed_16_16 (1.0), 0.0),
      (Fixed_16_16 (1.0), Fixed_16_16 (3.0), Fixed_16_16 (2.0)),
      (0.0, Fixed_16_16 (1.0), Fixed_16_16 (4.0)));

   ---------------------------------------------------------------------
   --  Helpers
   ---------------------------------------------------------------------

   function "*" (A, B : Mat4) return Mat4 is
      R : Mat4;
   begin
      for I in 1 .. 4 loop
         for J in 1 .. 4 loop
            R (I, J) :=
              A (I, 1) * B (1, J) +
              A (I, 2) * B (2, J) +
              A (I, 3) * B (3, J) +
              A (I, 4) * B (4, J);
         end loop;
      end loop;
      return R;
   end "*";

   function "*" (A, B : Mat3) return Mat3 is
      R : Mat3;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            R (I, J) :=
              A (I, 1) * B (1, J) +
              A (I, 2) * B (2, J) +
              A (I, 3) * B (3, J);
         end loop;
      end loop;
      return R;
   end "*";

   function Max_Err (A, B : Mat4) return Fixed_16_16 is
      E, Diff : Fixed_16_16;
   begin
      E := 0.0;
      for I in 1 .. 4 loop
         for J in 1 .. 4 loop
            Diff := A (I, J) - B (I, J);
            if Diff < 0.0 then
               Diff := -Diff;
            end if;
            if Diff > E then
               E := Diff;
            end if;
         end loop;
      end loop;
      return E;
   end Max_Err;

   function Max_Err (A, B : Mat3) return Fixed_16_16 is
      E, Diff : Fixed_16_16;
   begin
      E := 0.0;
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            Diff := A (I, J) - B (I, J);
            if Diff < 0.0 then
               Diff := -Diff;
            end if;
            if Diff > E then
               E := Diff;
            end if;
         end loop;
      end loop;
      return E;
   end Max_Err;

   procedure Check (Name : String; M : Mat4) is
      E : constant Fixed_16_16 := Max_Err (M * Inverse (M), Mat_Id4);
   begin
      Put_Line
        (Name & ": max |M*Inv - I| =" & Fixed_16_16'Image (E) &
         (if E <= Tol then "  PASS" else "  FAIL"));
   end Check;

   procedure Check (Name : String; M : Mat3) is
      E : constant Fixed_16_16 := Max_Err (M * Inverse (M), Mat_Id3);
   begin
      Put_Line
        (Name & ": max |M*Inv - I| =" & Fixed_16_16'Image (E) &
         (if E <= Tol then "  PASS" else "  FAIL"));
   end Check;

begin
   Put_Line ("det (Id3) =" & Fixed_16_16'Image (Det (Mat_Id3)));
   Put_Line ("det (Id4) =" & Fixed_16_16'Image (Det (Mat_Id4)));
   Put_Line ("det (G3)  =" & Fixed_16_16'Image (Det (G3)) & "   (exact 16)");
   Put_Line ("det (G4)  =" & Fixed_16_16'Image (Det (G4)) & "   (exact 4)");
   New_Line;

   Check ("inv (Id4) ", Mat_Id4);
   Check ("inv (T4)  ", T4);
   Check ("inv (RY4) ", RY4);
   Check ("inv (G4)  ", G4);
   Check ("inv (Id3) ", Mat_Id3);
   Check ("inv (G3)  ", G3);

   --  Orthonormal rotation: inverse must equal the transpose.
   declare
      E : constant Fixed_16_16 := Max_Err (Inverse (RY4), Transpose (RY4));
   begin
      Put_Line
        ("inv (RY4) = transpose (RY4): max err =" & Fixed_16_16'Image (E) &
         (if E <= Tol then "  PASS" else "  FAIL"));
   end;

   --  Singular input: det computes to exactly 0, Inverse must raise.
   Put_Line ("det (Bad4) =" & Fixed_16_16'Image (Det (Bad4)));
   begin
      declare
         R : constant Mat4 := Inverse (Bad4);
         pragma Unreferenced (R);
      begin
         Put_Line ("singular: no exception raised  FAIL");
      end;
   exception
      when Singular_Matrix =>
         Put_Line ("singular: raised Singular_Matrix  PASS");
   end;

end Test_Inverse;
