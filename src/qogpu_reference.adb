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

   --  NOTE: TriBuf below is a constant, so M must be initialized with the
   --  transform here; assigning it later would leave TriBuf with identity.
   M : Mat4 := Geometry.Cartesian_Transform
      (Position => (   -1.0,     0.5, -3.0),
       Rotation => (-0.5236, -1.0472,  0.0),
       Scale    => (    0.1,     0.1,  0.1));
   V : Mat4 := Mat_Id4;

   -- Geometry Transform
   TriBuf : constant Vert_Buffer :=
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
         A : constant Vert := TriBuf (3 * (T - 1) + 1);
         B : constant Vert := TriBuf (3 * (T - 1) + 2);
         C : constant Vert := TriBuf (3 * (T - 1) + 3);
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
