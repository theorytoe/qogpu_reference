with Image_IO.Operations;
with Render;
with Types;
with Objloader.Files;

procedure Qogpu_Reference is
   use Types;

   Width  : constant Positive := 640;
   Height : constant Positive := 480;

   Frame : Render.Framebuffer (Max_X => Width - 1, Max_Y => Height - 1);

   --  Triangle vertices from the reference program.
   Ax : constant Natural :=  14;
   Ay : constant Natural :=   9;
   Az : constant Natural :=  13;
   Bx : constant Natural :=  53;
   By : constant Natural :=  28;
   Bz : constant Natural := 152;
   Cx : constant Natural :=  29;
   Cy : constant Natural :=  55;
   Cz : constant Natural := 255;

   Mesh :  constant Objloader.Mesh := Objloader.Files.Load ("cube.obj");
   EMesh : constant Objloader.Expanded_Mesh := Objloader.Expand (Mesh);

   Palette : constant array (1 .. 3) of Color :=
      (Render.Green, Render.Red, Render.Blue);

   --  Model / View transform matricies pre-compute
   M : constant Mat4 :=
      ((1.0, 0.0, 0.0, 0.0),
       (0.0, 1.0, 0.0, 0.0),
       (0.0, 0.0, 1.0, 0.0),
       (0.0, 0.0, 0.0, 1.0));

   V : constant Mat4 :=
      ((0.4472, 0.0000, -0.8944, 0.0000),
        (0.0000, 1.0000, 0.0000, 0.0000),
        (0.8944, 0.0000, 0.4472, -2.2361),
        (0.0000, 0.0000, 0.0000, 1.0000));

   --  Local->Camera coord transform matrix
   MV : constant Mat4 := V * M;

   --  some camera values
   Near  : constant Fixed_16_16 := 1.0;
   Inv_T : constant Fixed_16_16 := 1.0;
   Inv_R : constant Fixed_16_16 := 0.75;

   type Pixel_Vert is record
      Px, Py : Integer;
      Inv_D  : Fixed_16_16;
   end record;

   Projected : array ( 1..3 ) of Pixel_Vert;
   Visible   : Boolean;
begin
   Render.Clear (Frame);
   --  TODO: Depth Buffer

   for I in EMesh'Range loop
      declare
         Tri : constant  Objloader.Expanded_Triangle := EMesh (I);
         Col : constant Color := Palette ((I - 1) mod Palette'Length + 1);
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
               if D <= Near then
                  Visible := false;
               else
                  declare
                     Inv_D : constant Fixed_16_16 := 1.0 / D;
                     Sx    : constant Fixed_16_16 := PC.X * Inv_D;
                     Sy    : constant Fixed_16_16 := PC.Y * Inv_D;
                     Ndx   : constant Fixed_16_16 := Sx * Inv_R;
                     Ndy   : constant Fixed_16_16 := Sy * Inv_T;
                     Px    : constant Integer := Integer ((Ndx + 1.0) * 320);
                     Py    : constant Integer := Integer ((1.0 - Ndy) * 240);
                  begin
                     Projected (C) :=
                        (Px => Integer'Min (Integer'Max (Px, 0), Width - 1),
                         Py => Integer'Min (Integer'Max (Py, 0), Height - 1),
                         Inv_D => Inv_D);
                  end;
               end if;
            end;
         end loop;

         --  Primitive culling
         declare
            Area : constant Fixed_16_16 :=
               Render.Tri_Area (Projected (1).Px, Projected (1).Py,
                                Projected (2).Px, Projected (2).Py,
                                Projected (3).Px, Projected (3).Py);
         begin
            if Area >= 0.0 then       -- back-facing (flip the sign if the
               Visible := False;      -- whole cube vanishes!)
            end if;
         end;

         if Visible then
            Render.Tri
               (Frame,
                Projected (1).Px, Projected (1).Py, 0,
                Projected (2).Px, Projected (2).Py, 0,
                Projected (3).Px, Projected (3).Py, 0,
                Col);
         end if;
      end;
   end loop;

   --  image_io has no TGA writer, so the framebuffer goes out as PNG.
   Image_IO.Operations.Write_PNG ("framebuffer.png", Frame.Data);
end Qogpu_Reference;
