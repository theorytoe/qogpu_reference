with Image_IO.Operations;
with Render;
with Types;
with Geometry;
with Objloader.Files;
with Ada.Numerics.Discrete_Random;

procedure Qogpu_Reference is
   use Types;

   Width  : constant Positive := 640;
   Height : constant Positive := 480;

   Frame : Render.Framebuffer (Max_X => Width - 1, Max_Y => Height - 1);

   Mesh :  constant Objloader.Mesh := Objloader.Files.Load ("cube.obj");
   EMesh : constant Objloader.Expanded_Mesh := Objloader.Expand (Mesh);

   Palette : constant array (1 .. 3) of Color :=
      (Render.Green, Render.Red, Render.Blue);

   --  Model Transform matrix
   --  -> Rot(x, 30)
   --  -> Rot(y, 60)
   --  -> Translate(z, -3)
   M : constant Mat4 :=
      ((   0.5, 0.433,  0.75,  0.0),
       (   0.0, 0.866,  -0.5,  0.0),
       (-0.866,  0.25, 0.433, -3.0),
       (   0.0,   0.0,   0.0,  1.0));

   V : constant Mat4 := Mat_Id4;

   -- Geometry Transform
   TriBuf : constant Geometry.Vert_Buffer :=
      Geometry.Transform_Mesh (Emesh, M, V, Width, Height);

   function RandColor return Color is
      subtype Col is Integer range 0 .. 255;
      package Random_Col is new Ada.Numerics.Discrete_Random (Col);
      Gen : Random_Col.Generator;
      Result : Color;
   begin
      Random_Col.Reset (Gen);
      Result :=
         (Red   => Image_IO.RGB_Value (Random_Col.Random (Gen)),
          Green => Image_IO.RGB_Value (Random_Col.Random (Gen)),
          Blue  => Image_IO.RGB_Value (Random_Col.Random (Gen)));
      return Result;
   end RandColor;
begin
   Render.Clear (Frame);

   --  Geometry Transforms (see declarative portion)
   --  TODO: Depth Buffer

   --  Rasterization Phase
   for T in 1 .. TriBuf'Length / 3 loop
      declare
         A : constant Geometry.Vert := TriBuf (3 * (T - 1) + 1);
         B : constant Geometry.Vert := TriBuf (3 * (T - 1) + 2);
         C : constant Geometry.Vert := TriBuf (3 * (T - 1) + 3);
      begin
         Render.Tri
            (Frame,
             A.X, A.Y, 0,
             B.X, B.Y, 0,
             C.X, C.Y, 0,
             RandColor);
      end;
   end loop;

   Image_IO.Operations.Write_PNG ("framebuffer.png", Frame.Data);
end Qogpu_Reference;
