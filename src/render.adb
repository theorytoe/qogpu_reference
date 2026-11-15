package body Render is

   procedure Clear
      (Frame : in out Framebuffer;
       Col   : Color := Black)
   is begin
      Frame.Data  := (others => (others => Col));
      --  Depth is NOT Col: reset to "everything far". Bigger stored value
      --  = nearer, so 0 means the far side of the frustum.
      Frame.Depth :=
         (others => (others => (Red => 0, Green => 0, Blue => 0)));
   end Clear;

   procedure Put_Pixel_RGB
      (Frame : in out Framebuffer;
       X, Y : Integer;
       R, G, B : Image_IO.RGB_Value)
   is begin
      Frame.Data (Y, X) := (Red => R, Green => G, Blue => B);
   end Put_Pixel_RGB;

   procedure Put_Pixel
      (Frame : in out Framebuffer;
       X, Y  : Integer;
       Col   : Color)
   is begin
      Frame.Data (Y, X) :=
         (Red   => Col.Red,
          Green => Col.Green,
          Blue  => Col.Blue);
   end Put_Pixel;

   procedure Put_ZBuf
      (Frame : in out Framebuffer;
       X, Y  : Integer;
       Depth : Image_IO.RGB_Value)
   is begin
      --  Store gray so depth.png comes out as a grayscale depth map.
      Frame.Depth (Y, X) :=
         (Red => Depth, Green => Depth, Blue => Depth);
   end Put_ZBuf;

   procedure Swap (A, B : in out Integer)
   is
      buf : constant Integer := A;
   begin
      A := B;
      B := buf;
   end Swap;

   function Tri_Area
       (Ax, Ay : Integer;
        Bx, By : Integer;
        Cx, Cy : Integer)
       return Integer
   is
      Area : constant Integer :=
         ((By - Ay) * (Bx + Ax) +
          (Cy - By) * (Cx + Bx) +
          (Ay - Cy) * (Ax + Cx));
   begin
      return Area;
   end Tri_Area;

   procedure Line
      (Frame : in out Framebuffer;
       AX, AY : Integer;
       BX, BY : Integer;
       Col : Color)
   is
      X1 : Integer := AX;
      X2 : Integer := BX;
      Y1 : Integer := AY;
      Y2 : Integer := BY;
      Steep : constant Boolean := abs (X1 - X2) < abs (Y1 - Y2);
   begin
      if Steep then
         Swap (X1, Y1);
         Swap (X2, Y2);
      end if;

      if X1 > X2 then
         Swap (X1, X2);
         Swap (Y1, Y2);
      end if;

      --  TODO: Branch optomization
      for X in X1 .. X2 loop
         declare
            T : constant Fixed_16_16 :=
               (if X1 = X2 then 0.0
                else Fixed_16_16 (X - X1) / Fixed_16_16 (X2 - X1));
            Y : constant Integer := Integer
               (Fixed_16_16 (Y1) + Fixed_16_16 (Y2 - Y1) * T);
         begin
            if Steep then
               Put_Pixel (Frame, X => Y, Y => X, Col => Col);
            else
               Put_Pixel (Frame, X => X, Y => Y, Col => Col);
            end if;
         end;
      end loop;
   end Line;

   procedure Tri
      (Frame  : in out Framebuffer;
       Ax, Ay : Integer;
       Az     : Fixed_16_16;
       Bx, By : Integer;
       Bz     : Fixed_16_16;
       Cx, Cy : Integer;
       Cz     : Fixed_16_16;
       Col    : Color)
   is
      use Image_IO;

      --  Quantize Inv_D (1 / camera depth) to 0..255. The near-plane cull
      --  in Geometry.Transform_Mesh guarantees D > 1.0, so Inv_D < 1.0
      --  fits; clamp anyway so a stray vertex can't overflow RGB_Value.
      function Q (Inv_D : Fixed_16_16) return Integer is
         Raw : constant Integer :=
            Integer (Long_Long_Float (Inv_D) * 255.0);
      begin
         return Integer'Min (Integer'Max (Raw, 0), 255);
      end Q;

      --  Bounding boxes
      BBMinX : constant Integer := Integer'Min (Integer'Min (Ax, Bx), Cx);
      BBMinY : constant Integer := Integer'Min (Integer'Min (Ay, By), Cy);
      BBMaxX : constant Integer := Integer'Max (Integer'Max (Ax, Bx), Cx);
      BBMaxY : constant Integer := Integer'Max (Integer'Max (Ay, By), Cy);

      Total_Area : constant Integer := Tri_Area (Ax, Ay, Bx, By, Cx, Cy);
      TS         : constant Integer := (if Total_Area < 0 then -1 else 1);
      TA         : constant Integer := abs (Total_Area);

      --  Per-vertex quantized depth. Bigger = nearer.
      QA         : constant Integer := Q (Az);
      QB         : constant Integer := Q (Bz);
      QC         : constant Integer := Q (Cz);
   begin
      if TA < 2 then
         return;
      end if;
      --  TODO: Parallelize
      for X in BBMinX .. BBMaxX loop
         for Y in BBMinY .. BBMaxY loop
            declare
               --  Barycentric Coordinates
               Alpha : constant Integer :=
                  TS * Tri_Area (X, Y, Bx, By, Cx, Cy);
               Beta  : constant Integer :=
                  TS * Tri_Area (X, Y, Cx, Cy, Ax, Ay);
               Gamma : constant Integer :=
                  TS * Tri_Area (X, Y, Ax, Ay, Bx, By);

               --  Perspective-correct depth: interpolate Inv_D, which is
               --  linear in screen space (raw Z is not). Depth_N is
               --  unnormalized: divide by TA (constant per triangle) to
               --  get the pixel's quantized depth. Max value check:
               --  TA * 255 fits comfortably in Integer for 640x480.
               Depth_N : constant Integer :=
                  Alpha * QA +
                  Beta  * QB +
                  Gamma * QC;
            begin
               if not ((Alpha < 0) or (Beta < 0) or (Gamma < 0)) then
                  --  Depth test against the stored quantized value,
                  --  rescaled by TA to defer the division: one divide per
                  --  pixel that actually passes, none for failures.
                  if Depth_N > Integer (Frame.Depth (Y, X).Red) * TA then
                     Put_Pixel (Frame, X, Y, Col);
                     Put_ZBuf  (Frame, X, Y,
                                Image_IO.RGB_Value (Depth_N / TA));
                  end if;
               end if;
            end;
         end loop;
      end loop;
   end Tri;

end Render;
