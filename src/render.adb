package body Render is

   procedure Clear
      (Frame : in out Framebuffer;
       Col   : Color := Black)
   is begin
      Frame.Data := (others => (others => Col));
   end Clear;

   procedure Put_Pixel_RGB
      (Frame : in out Framebuffer;
       X, Y : Natural;
       R, G, B : Image_IO.RGB_Value)
   is begin
      Frame.Data (Y, X) := (Red => R, Green => G, Blue => B);
   end Put_Pixel_RGB;

   procedure Put_Pixel
      (Frame : in out Framebuffer;
       X, Y : Natural;
       Col : Color)
   is begin
      Frame.Data (Y, X) :=
         (Red   => Col.Red,
          Green => Col.Green,
          Blue  => Col.Blue);
   end Put_Pixel;
end Render;
