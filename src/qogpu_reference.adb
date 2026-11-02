with Image_IO.Operations;
with Render;

procedure Qogpu_Reference is
   Width  : constant Positive := 64;
   Height : constant Positive := 64;

   Frame : Render.Framebuffer (Max_X => Width - 1, Max_Y => Height - 1);

   --  Triangle vertices from the reference program.
   Ax : constant Natural := 14;
   Ay : constant Natural :=  9;
   Bx : constant Natural := 53;
   By : constant Natural := 28;
   Cx : constant Natural := 29;
   Cy : constant Natural := 55;
begin
   Render.Clear (Frame);

   --  Render.Put_Pixel (Frame, 0, 0, Render.White);
   --  Render.Put_Pixel (Frame, 32, 32, Render.Green);

   --  Render.Line (Frame, Ax, Ay, Bx, By, Render.Blue);
   --  Render.Line (Frame, Cx, Cy, Bx, By, Render.Green);
   --  Render.Line (Frame, Ax, Ay, Ax, Ay, Render.Yellow);
   --  Render.Line (Frame, Ax, Ay, Cx, Cy, Render.Red);
   --  Render.Tri (Frame, Ax, Ay, Bx, By, Cx, Cy, Render.Red);

   Render.Tri (Frame, Ax, Ay, Bx, By, Cx, Cy, Render.Green);

   --  image_io has no TGA writer, so the framebuffer goes out as PNG.
   Image_IO.Operations.Write_PNG ("framebuffer.png", Frame.Data);
end Qogpu_Reference;
