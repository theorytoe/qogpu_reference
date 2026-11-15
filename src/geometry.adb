with Numerics;

package body Geometry is
   use Types;

   function Cartesian_Transform
      (Position    : Vec3;
       Rotation    : Vec3;
       Scale       : Vec3) return Mat4
   is
      use Numerics;

      --  One CORDIC call per angle: Sin_Cos returns both results, so no
      --  angle is iterated twice.
      SX : constant Sin_Cos_Pair := Sin_Cos (Rotation.X);
      SY : constant Sin_Cos_Pair := Sin_Cos (Rotation.Y);
      SZ : constant Sin_Cos_Pair := Sin_Cos (Rotation.Z);

      T : Mat4 := Mat_Id4;
      S : Mat4 := Mat_Id4;
      R : Mat4 := Mat_Id4;

      Result : Mat4 := Mat_Id4;
   begin

      --  Transformation Matrix
      T (1, 4) := Position.X;
      T (2, 4) := Position.Y;
      T (3, 4) := Position.Z;

      -- Rotation Matrix (Rx * Ry * Rz combined form). Fixed * fixed yields
      -- universal_fixed, so each 3-factor chain is split with an explicit
      -- conversion; sums and 2-factor products convert implicitly here.
      R (1,1) := SY.Cos * SZ.Cos;
      R (1,2) := Fixed_16_16 (SX.Sin * SY.Sin) * SZ.Cos + SX.Cos * SZ.Sin;
      R (1,3) := SX.Sin * SZ.Sin - Fixed_16_16 (SX.Cos * SY.Sin) * SZ.Cos;

      R (2,1) := -SY.Cos * SZ.Sin;
      R (2,2) := SX.Cos * SZ.Cos - Fixed_16_16 (SX.Sin * SY.Sin) * SZ.Sin;
      R (2,3) := Fixed_16_16 (SX.Cos * SY.Sin) * SZ.Sin + SX.Sin * SZ.Cos;

      R (3,1) := SY.Sin;
      R (3,2) := -SX.Sin * SY.Cos;
      R (3,3) := SX.Cos * SY.Cos;

      -- Scale Matrix
      S (1,1) := Scale.X;
      S (2,2) := Scale.Y;
      S (3,3) := Scale.Z;

      --  right->left for transformation order
      Result := T * R * S;
      return Result;
   end Cartesian_Transform;


   function Transform_Mesh
      (Mesh        : Objloader.Expanded_Mesh;
       Coord_Mesh  : Types.Mat4;
       Coord_View  : Types.Mat4;
       Width       : Integer;
       Height      : Integer) return Vert_Buffer
   is
      MV : constant Mat4 := Coord_View * Coord_Mesh;

      --  TODO: demagic magic consts
      Near  : constant Fixed_16_16 := 1.0;
      Inv_T : constant Fixed_16_16 := 1.0;
      Inv_R : constant Fixed_16_16 :=
         Fixed_16_16(Height) / Fixed_16_16(Width);

      Buf   : Vert_Buffer (1 .. Mesh'Length * 3);
      Count : Integer := 0;

      Projected : array ( 1..3 ) of Vert;
      Visible : Boolean; --  TODO: proper depth buffer

      Half_W : constant Integer := Width  / 2;
      Half_H : constant Integer := Height / 2;

      procedure Append (V : Vert) is
      begin
         Count := Count + 1;
         Buf (Count) := V;
      end Append;
   begin
      for Tri of Mesh loop
         declare
            Verts : constant array ( 1..3 ) of Objloader.Vertex :=
               (Tri.A.Position, Tri.B.Position, Tri.C.Position);
         begin
            Visible := true;
            for C in 1..3 loop
               declare
                  P : constant Vec3 :=
                     (X => Fixed_16_16 (Verts (C).X),
                      Y => Fixed_16_16 (Verts (C).Y),
                      Z => Fixed_16_16 (Verts (C).Z));
                  PC : constant Vec3 := Transform_Point (MV, P);
                  D  : constant Fixed_16_16 := -PC.Z; --  Camera depth
               begin
                  if D <= near then
                     Visible := false;
                  else
                     declare
                        Inv_D : constant Fixed_16_16 := 1.0 / D;
                        Sx    : constant Fixed_16_16 := PC.X * Inv_D;
                        Sy    : constant Fixed_16_16 := PC.Y * Inv_D;
                        Ndx   : constant Fixed_16_16 := Sx * Inv_R;
                        Ndy   : constant Types.Fixed_16_16 := Sy * Inv_T;
                        Px    : constant Integer := Integer ((Ndx + 1.0) * Half_W);
                        Py    : constant Integer := Integer ((1.0 - Ndy) * Half_H);
                     begin
                        Projected (C) :=
                           (X => Integer'Min (Integer'Max (Px, 0), Width - 1),
                            Y => Integer'Min (Integer'Max (Py, 0), Height - 1),
                            Inv_D => Inv_D);
                     end;
                  end if;
               end;
            end loop;

            -- TODO: Depth Buffer
            declare
               Area : constant Integer :=
                  Render.Tri_Area (Projected (1).X, Projected (1).Y,
                                   Projected (2).X, Projected (2).Y,
                                   Projected (3).X, Projected (3).Y);
            begin
               if Area >= 0 then
                  Visible := false;
               end if;
            end;

            for C in 1 .. 3 loop
               if Visible then
                  Append (Projected (C));
               end if;
            end loop;
         end;
      end loop;

      return Buf (1 .. Count);
   end Transform_Mesh;
end Geometry;
