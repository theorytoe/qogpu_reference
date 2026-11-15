with Image_IO.Operations;
with Render;
with Types;
with Geometry;
with Objloader.Files;
with Ada.Numerics.Discrete_Random;
with Ada.Calendar;

procedure Qogpu_Reference is
   use Types;

   Width  : constant Positive := 640;
   Height : constant Positive := 480;

   Frame : Render.Framebuffer (Max_X => Width - 1, Max_Y => Height - 1);

   Mesh :  constant Objloader.Mesh := Objloader.Files.Load ("models/fish.obj");
   EMesh : constant Objloader.Expanded_Mesh := Objloader.Expand (Mesh);

   Palette : constant array (1 .. 3) of Color :=
      (Render.Green, Render.Red, Render.Blue);

   --  Model Transform matrix
   --  -> Rot(x, 30)
   --  -> Rot(y, 60)
   --  -> Translate(z, -3)
--   M : constant Mat4 :=
--      ((   0.5, 0.433,  0.75,  0.0),
--       (   0.0, 0.866,  -0.5,  0.0),
--       (-0.866,  0.25, 0.433, -3.0),
--       (   0.0,   0.0,   0.0,  1.0));
   M : constant Mat4 :=
      ((0.0250, 0.0000, 0.0433, -0.5000),
       (0.0217, 0.0433, -0.0125, 0.0000),
       (-0.0375, 0.0250, 0.0217, -2.0000),
       (0.0000, 0.0000, 0.0000, 1.0000));

   V : constant Mat4 := Mat_Id4;

   -- Geometry Transform
   TriBuf : constant Geometry.Vert_Buffer :=
      Geometry.Transform_Mesh (Emesh, M, V, Width, Height);

   subtype Col_Byte is Integer range 0 .. 255;
   package Random_Col is new Ada.Numerics.Discrete_Random (Col_Byte);
   Gen : Random_Col.Generator;

   function RandColor return Color is
   begin
      return
         (Red   => Image_IO.RGB_Value (Random_Col.Random (Gen)),
          Green => Image_IO.RGB_Value (Random_Col.Random (Gen)),
          Blue  => Image_IO.RGB_Value (Random_Col.Random (Gen)));
   end RandColor;
begin
   --  Seed once from the clock; Reset inside RandColor would replay the
   --  same numbers on every call (every triangle one color).
   Random_Col.Reset (Gen, Integer (Ada.Calendar.Seconds (Ada.Calendar.Clock)));
   Render.Clear (Frame);

   --  Rasterization Phase
   for T in 1 .. TriBuf'Length / 3 loop
      declare
         A : constant Geometry.Vert := TriBuf (3 * (T - 1) + 1);
         B : constant Geometry.Vert := TriBuf (3 * (T - 1) + 2);
         C : constant Geometry.Vert := TriBuf (3 * (T - 1) + 3);
      begin
         Render.Tri
            (Frame,
             A.X, A.Y, A.Inv_D,
             B.X, B.Y, B.Inv_D,
             C.X, C.Y, C.Inv_D,
             RandColor);
      end;
   end loop;

   Image_IO.Operations.Write_PNG ("framebuffer.png", Frame.Data);
   Image_IO.Operations.Write_PNG ("depth.png", Frame.Depth);
end Qogpu_Reference;
