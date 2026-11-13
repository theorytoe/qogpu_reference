package body Types is

   ---------------------------------------------------------------------
   --  3x3 minor of a 4x4 matrix: the entries with Row and Col removed.
   --  Used by Det (Mat4) and the adjugate inverse below.
   ---------------------------------------------------------------------

   function Minor3 (M : Mat4; Row, Col : Positive) return Mat3 is
      R : Mat3;
      I : Positive := 1;
   begin
      for Mi in 1 .. 4 loop
         if Mi /= Row then
            declare
               J : Positive := 1;
            begin
               for Mj in 1 .. 4 loop
                  if Mj /= Col then
                     R (I, J) := M (Mi, Mj);
                     J := J + 1;
                  end if;
               end loop;
            end;
            I := I + 1;
         end if;
      end loop;
      return R;
   end Minor3;

   ---------------------------------------------------------------------
   --  Determinants
   ---------------------------------------------------------------------

   --  Rule of Sarrus. Each triple product needs the first pair wrapped in
   --  an explicit conversion: Fixed * Fixed yields universal_fixed, which
   --  cannot directly feed another * with a fixed operand.
   function Det (M : Mat3) return Fixed_16_16 is
      T1 : constant Fixed_16_16 :=
         Fixed_16_16 (M (1, 1) * M (2, 2)) * M (3, 3);
      T2 : constant Fixed_16_16 :=
         Fixed_16_16 (M (1, 2) * M (2, 3)) * M (3, 1);
      T3 : constant Fixed_16_16 :=
         Fixed_16_16 (M (1, 3) * M (2, 1)) * M (3, 2);
      T4 : constant Fixed_16_16 :=
         Fixed_16_16 (M (1, 3) * M (2, 2)) * M (3, 1);
      T5 : constant Fixed_16_16 :=
         Fixed_16_16 (M (1, 2) * M (2, 1)) * M (3, 3);
      T6 : constant Fixed_16_16 :=
         Fixed_16_16 (M (1, 1) * M (2, 3)) * M (3, 2);
   begin
      return T1 + T2 + T3 - T4 - T5 - T6;
   end Det;

   --  Laplace expansion along the first row; each term is the signed
   --  determinant of the 3x3 minor with row 1 and column J struck out.
   --  Sign pattern: + - + -.
   function Det (M : Mat4) return Fixed_16_16 is
      Total : Fixed_16_16 := 0.0;
   begin
      for J in 1 .. 4 loop
         declare
            Term : constant Fixed_16_16 := M (1, J) * Det (Minor3 (M, 1, J));
         begin
            if J mod 2 = 1 then
               Total := Total + Term;
            else
               Total := Total - Term;
            end if;
         end;
      end loop;
      return Total;
   end Det;

   ---------------------------------------------------------------------
   --  Transpose
   ---------------------------------------------------------------------

   function Transpose (M : Mat3) return Mat3 is
      R : Mat3;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            R (I, J) := M (J, I);
         end loop;
      end loop;
      return R;
   end Transpose;

   function Transpose (M : Mat4) return Mat4 is
      R : Mat4;
   begin
      for I in 1 .. 4 loop
         for J in 1 .. 4 loop
            R (I, J) := M (J, I);
         end loop;
      end loop;
      return R;
   end Transpose;

   ---------------------------------------------------------------------
   --  Inverses: adjugate (cofactor) method, inverse = adj (M) / det (M).
   --  No pivoting, no Gauss-Jordan; fine for the translation/rotation/
   --  projection-style matrices this renderer uses.
   ---------------------------------------------------------------------

   function Inverse (M : Mat3) return Mat3 is
      D : constant Fixed_16_16 := Det (M);
      R : Mat3;

      --  Cofactor matrix: cof (I, J) = (-1)**(I+J) * minor (I, J).
      C11 : constant Fixed_16_16 :=  M (2, 2) * M (3, 3) - M (2, 3) * M (3, 2);
      C12 : constant Fixed_16_16 := -(M (2, 1) * M (3, 3) - M (2, 3) * M (3, 1));
      C13 : constant Fixed_16_16 :=  M (2, 1) * M (3, 2) - M (2, 2) * M (3, 1);
      C21 : constant Fixed_16_16 := -(M (1, 2) * M (3, 3) - M (1, 3) * M (3, 2));
      C22 : constant Fixed_16_16 :=  M (1, 1) * M (3, 3) - M (1, 3) * M (3, 1);
      C23 : constant Fixed_16_16 := -(M (1, 1) * M (3, 2) - M (1, 2) * M (3, 1));
      C31 : constant Fixed_16_16 :=  M (1, 2) * M (2, 3) - M (1, 3) * M (2, 2);
      C32 : constant Fixed_16_16 := -(M (1, 1) * M (2, 3) - M (1, 3) * M (2, 1));
      C33 : constant Fixed_16_16 :=  M (1, 1) * M (2, 2) - M (1, 2) * M (2, 1);

      --  Adjugate = transpose of the cofactor matrix.
      Adj : constant Mat3 :=
        ((C11, C21, C31),
         (C12, C22, C32),
         (C13, C23, C33));
   begin
      if D = 0.0 then
         raise Singular_Matrix;
      end if;

      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            R (I, J) := Adj (I, J) / D;
         end loop;
      end loop;

      return R;
   end Inverse;

   function Inverse (M : Mat4) return Mat4 is
      D : constant Fixed_16_16 := Det (M);
      R : Mat4;
   begin
      if D = 0.0 then
         raise Singular_Matrix;
      end if;

      --  R (I, J) = adjugate (I, J) / D = cofactor (J, I) / D.
      --  Cofactor (J, I) is (-1)**(I+J) times the det of the 3x3 minor
      --  with row J and col I struck out. Storing cofactor (J, I) at
      --  (I, J) is what transposes the cofactors into the adjugate.
      for I in 1 .. 4 loop
         for J in 1 .. 4 loop
            declare
               C : constant Fixed_16_16 := Det (Minor3 (M, J, I));
            begin
               if (I + J) mod 2 = 0 then
                  R (I, J) := C / D;
               else
                  R (I, J) := -C / D;
               end if;
            end;
         end loop;
      end loop;

      return R;
   end Inverse;

   -- Other more "optomized" methods of matrix multiplication
   -- dont really scale at these small sizes
   function "*" (Left, Right : Mat3) return Mat3
   is
      Result : Mat3;
      Sum    : Fixed_16_16;
   begin
      for I in Mat3_Index loop
         for J in Mat3_Index loop
            Sum := 0.0;
            for K in Mat3_Index loop
               Sum := Sum + Left (I, K) * Right (K, J);
            end loop;
            Result (I, J) := Sum;
         end loop;
      end loop;
      return Result;
   end "*";

   function "*" (Left, Right : Mat4) return Mat4
   is
      Result : Mat4;
      Sum    : Fixed_16_16;
   begin
      for I in Mat4_Index loop
         for J in Mat4_Index loop
            Sum := 0.0;
            for K in Mat4_Index loop
               Sum := Sum + Left (I, K) * Right (K, J);
            end loop;
            Result (I, J) := Sum;
         end loop;
      end loop;
      return Result;
   end "*";

   function Transform_Point
      (Transform : Mat4;
       Point     : Vec3) return Vec3
   is
      X : constant Fixed_16_16 :=
         Transform(1,1) * Point.X +
         Transform(1,2) * Point.Y +
         Transform(1,3) * Point.Z +
         Transform(1,4);
      Y : constant Fixed_16_16 :=
         Transform(2,1) * Point.X +
         Transform(2,2) * Point.Y +
         Transform(2,3) * Point.Z +
         Transform(2,4);
      Z : constant Fixed_16_16 :=
         Transform(3,1) * Point.X +
         Transform(3,2) * Point.Y +
         Transform(3,3) * Point.Z +
         Transform(3,4);
      Result : constant Vec3 :=
         (X => X, Y => Y, Z => Z);
   begin
      return Result;
   end Transform_Point;

end Types;
