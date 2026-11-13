with Interfaces;
with Image_IO;

package Types is
   pragma Elaborate_Body;

   --  Declare the same fixed-point type the FPGA uses internally.
   --  16 integer bits, 16 fractional bits: matches the synthesis target.
   type Fixed_16_16 is
      delta 2.0 ** (-16)
      range -(2.0 ** 15) .. (2.0 ** 15) - 2.0 ** (-16);

   --  perhaps
   subtype Byte is Interfaces.Unsigned_8;
   subtype Color is Image_IO.Color_Info;

   subtype Mat4_Index is Positive range 1..4;
   subtype Mat3_Index is Positive range 1..3;
   type Mat4 is array ( Mat4_Index, Mat4_Index ) of Fixed_16_16;
   type Mat3 is array ( Mat3_Index, Mat3_Index ) of Fixed_16_16;

   Mat_Id3 : constant Mat3 :=
      ((1.0, 0.0, 0.0),
       (0.0, 1.0, 0.0),
       (0.0, 0.0, 1.0));

   Mat_Id4 : constant Mat4 :=
      ((1.0, 0.0, 0.0, 0.0),
       (0.0, 1.0, 0.0, 0.0),
       (0.0, 0.0, 1.0, 0.0),
       (0.0, 0.0, 0.0, 1.0));

   --  Fixed-point matrix ops: only Fixed_16_16 arithmetic, no libraries,
   --  no floating point. Inverses use the adjugate (cofactor) method for
   --  both sizes: inverse = transpose (cofactors) / determinant. Mat3
   --  cofactors are written out; Mat4 cofactors are 3x3 minors from a
   --  Laplace expansion along the first row. Raises Singular_Matrix if M
   --  is singular, and Constraint_Error if any intermediate or result
   --  overflows the 16.16 range (fine for translation/rotation matrices;
   --  watch out with large entries).
   Singular_Matrix : exception;

   --  3-element vector
   type Vec3 is record
      X, Y, Z : Fixed_16_16;
   end record;

   function Det (M : Mat3) return Fixed_16_16;
   function Det (M : Mat4) return Fixed_16_16;

   function Transpose (M : Mat3) return Mat3;
   function Transpose (M : Mat4) return Mat4;

   function Inverse (M : Mat3) return Mat3;
   function Inverse (M : Mat4) return Mat4;

   function "*" (Left, Right : Mat3) return Mat3;
   function "*" (Left, Right : Mat4) return Mat4;

   function Transform_Point
      (Transform : Mat4;
       Point     : Vec3) return Vec3;

end Types;
