with Objloader;
with Types;
with Render;

package Geometry is
   use Types;

   --  Transform cartesian position, rotation, & scale vectors
   --  to a single model transform Matrix
   function Cartesian_Transform
      (Position    : Vec3;
       Rotation    : Vec3;
       Scale       : Vec3) return Mat4;

   --  Transform Mesh with Local Coord Mesh `Coord_Mesh`
   --  Using View defined by `Coord_View`. Generally speaking
   --  just use 4x4 identity for Coord_View.
   function Transform_Mesh
      (Mesh        : Objloader.Expanded_Mesh;
       Coord_Mesh  : Mat4;
       Coord_View  : Mat4;
       Width       : Integer;
       Height      : Integer) return Vert_Buffer;


end Geometry;
