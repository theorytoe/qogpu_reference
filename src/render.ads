with Interfaces;
with Image_IO;
package Render is

   --  Declare the same fixed-point type the FPGA uses internally.
   --  16 integer bits, 16 fractional bits: matches the synthesis target.
   type Fixed_16_16 is
      delta 2.0 ** (-16)
      range -(2.0 ** 15) .. (2.0 ** 15) - 2.0 ** (-16);

   --  perhaps
   subtype Byte is Interfaces.Unsigned_8;
   subtype Color is Image_IO.Color_Info;

   White  : constant Color := (Red => 255, Green => 255, Blue => 255);
   Green  : constant Color := (Red =>   0, Green => 255, Blue =>   0);
   Red    : constant Color := (Red => 255, Green =>   0, Blue =>   0);
   Blue   : constant Color := (Red =>  64, Green => 128, Blue => 255);
   Yellow : constant Color := (Red => 255, Green => 200, Blue =>   0);
   Black  : constant Color := (Red =>   0, Green =>   0, Blue =>   0);

   --  A fixed-size, 0-based framebuffer. The bounds are discriminants so the
   --  array component stays constrained (Image_Data is unconstrained).
   --  Ada requires a discriminant-dependent array bound to be the discriminant
   --  alone, so the discriminants are the last index, not the size.
   type Framebuffer (Max_X, Max_Y : Natural) is record
      Data : Image_IO.Image_Data (0 .. Max_Y, 0 .. Max_X);
   end record;

   function Width (Frame : Framebuffer) return Positive is (Frame.Max_X + 1);
   function Height (Frame : Framebuffer) return Positive is (Frame.Max_Y + 1);

   --  Fill the whole framebuffer with Col. Ada does not zero records with
   --  scalar components, so a fresh Framebuffer holds invalid pixels until
   --  this is called (TGAImage zero-fills in its constructor).
   procedure Clear
      (Frame : in out Framebuffer;
       Col   : Color := Black);

   procedure Put_Pixel_RGB
      (Frame : in out Framebuffer;
       X, Y : Integer;
       R, G, B : Image_IO.RGB_Value);

   procedure Put_Pixel
      (Frame : in out Framebuffer;
       X, Y : Integer;
       Col  : Color);


   procedure Swap (A, B : in out Integer);

   procedure Line
      (Frame : in out Framebuffer;
       AX, AY : Integer;
       BX, BY : Integer;
       Col : Color);

   procedure Tri
      (Frame  : in out Framebuffer;
       X1, Y1 : Integer;
       X2, Y2 : Integer;
       X3, Y3 : Integer;
       Col    : Color);

   --  TODO: Render procedure
   --  taken in verticies and draws a triangle

end Render;
