with Objloader;
with Types;
with Render;

package Geometry is

   type Vert is record
      X, Y   : Integer;
      Inv_D  : Types.Fixed_16_16;
   end record;

   type Vert_Buffer is array (Positive range <>) of Vert;

   --  XXX: Tri Buffer?

   --  Transform Mesh with Local Coord Mesh `Coord_Mesh`
   --  Using View defined by `Coord_View`. Generally speaking
   --  just use 4x4 identity for Coord_View.
   function Transform_Mesh
      (Mesh        : Objloader.Expanded_Mesh;
       Coord_Mesh  : Types.Mat4;
       Coord_View  : Types.Mat4;
       Width       : Integer;
       Height      : Integer) return Vert_Buffer;


end Geometry;
