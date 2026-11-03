package body Render is

   procedure Clear
      (Frame : in out Framebuffer;
       Col   : Color := Black)
   is begin
      Frame.Data := (others => (others => Col));
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
       return Fixed_16_16
   is
      Area : constant Fixed_16_16 :=
         Fixed_16_16 (0.5)
         * ((By - Ay) * (Bx + Ax)
         +  (Cy - By) * (Cx + Bx)
         +  (Ay - Cy) * (Ax + Cx));
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
       Bx, By : Integer;
       Cx, Cy : Integer;
       Col    : Color)
   is
      --  Bounding boxes
      BBMinX : constant Integer := Integer'Min (Integer'Min (Ax, Bx), Cx);
      BBMinY : constant Integer := Integer'Min (Integer'Min (Ay, By), Cy);
      BBMaxX : constant Integer := Integer'Max (Integer'Max (Ax, Bx), Cx);
      BBMaxY : constant Integer := Integer'Max (Integer'Max (Ay, By), Cy);

      Total_Area : constant Fixed_16_16 := Tri_Area (Ax, Ay, Bx, By, Cx, Cy);
   begin
      if Total_Area < 1.0 then
         return;
      end if;
      --  TODO: Parallelize
      for X in BBMinX .. BBMaxX loop
         for Y in BBMinY .. BBMaxY loop
            declare
               Alpha : constant Fixed_16_16 := Tri_Area (X, Y, Bx, By, Cx, Cy);
               Beta  : constant Fixed_16_16 := Tri_Area (X, Y, Cx, Cy, Ax, Ay);
               Gamma : constant Fixed_16_16 := Tri_Area (X, Y, Ax, Ay, Bx, By);
            begin
               if not ((Alpha < 0.0) or (Beta < 0.0) or (Gamma < 0.0)) then
                  Put_Pixel (Frame, X, Y, Render.Blue);
               end if;
            end;
         end loop;
      end loop;
   end Tri;

end Render;
