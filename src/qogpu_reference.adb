with Image_IO.Operations;
with Render;

procedure Qogpu_Reference is
   Width  : constant Positive := 64;
   Height : constant Positive := 64;

   Frame : Render.Framebuffer (Max_X => Width - 1, Max_Y => Height - 1);

   --  Triangle vertices from the reference program.
   Ax : constant Natural := 7;
   Ay : constant Natural := 3;
   Bx : constant Natural := 12;
   By : constant Natural := 37;
   Cx : constant Natural := 62;
   Cy : constant Natural := 53;
begin
   Render.Clear (Frame);

   Render.Put_Pixel (Frame, Ax, Ay, Render.White);
   Render.Put_Pixel (Frame, Bx, By, Render.White);
   Render.Put_Pixel (Frame, Cx, Cy, Render.White);

   --  image_io has no TGA writer, so the framebuffer goes out as PNG.
   Image_IO.Operations.Write_PNG ("framebuffer.png", Frame.Data);
end Qogpu_Reference;
