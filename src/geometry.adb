package body Geometry is
   use Types;

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
