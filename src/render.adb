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
       X1, Y1 : Integer;
       X2, Y2 : Integer;
       X3, Y3 : Integer;
       Col    : Color)
   is
      Ay : Integer := Y1;
      By : Integer := Y2;
      Cy : Integer := Y3;

      Ax : Integer := X1;
      Bx : Integer := X2;
      Cx : Integer := X3;

      Total_Height : Integer;
   begin
      --  Bubblesort (does complexity even matter for 3 items?)
      if Ay > By then
         Swap (Ay, By);
         Swap (Ax, Bx);
      end if;

      if Ay > Cy then
         Swap (Ay, Cy);
         Swap (Ax, Cx);
      end if;

      if By > Cy then
         Swap (By, Cy);
         Swap (Bx, Cx);
      end if;

      --  Only valid once the vertices are sorted.
      Total_Height := Cy - Ay;

      if Ay /= By then
         declare
            Segment_Height : constant Integer := By - Ay;
         begin
            for Y in Ay .. By loop
               declare
                  X1 : constant Integer := Ax + ((Cx - Ax) * (Y - Ay)) / Total_Height;
                  X2 : constant Integer := Ax + ((Bx - Ax) * (Y - Ay)) / Segment_Height;
               begin
                  for X in Integer'Min (X1, X2) .. (Integer'Max (X1, X2) - 1) loop
                     Put_Pixel (Frame, X, Y, Col);
                  end loop;
               end;
            end loop;
         end;
      end if;

      if By /= Cy then
         declare
            Segment_Height : constant Integer := Cy - By;
         begin
            for Y in By .. Cy loop
               declare
                  X1 : constant Integer := Ax + ((Cx - Ax) * (Y - Ay)) / Total_Height;
                  X2 : constant Integer := Bx + ((Cx - Bx) * (Y - By)) / Segment_Height;
               begin
                  for X in Integer'Min (X1, X2) .. (Integer'Max (X1, X2) - 1) loop
                     Put_Pixel (Frame, X, Y, Col);
                  end loop;
               end;
            end loop;
         end;
      end if;

      --  Line (Frame, X1, Y1, X2, Y2, Render.Green);
      --  Line (Frame, X2, Y2, X3, Y3, Render.Green);
      --  Line (Frame, X3, Y3, X1, Y1, Render.Red);
   end Tri;

end Render;
