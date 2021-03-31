/******************************************************************************/
/*
  Project   - MudBun
  Publisher - Long Bunny Labs
              http://LongBunnyLabs.com
  Author    - Ming-Lun "Allen" Chou
              http://AllenChou.net
*/
/******************************************************************************/

using System.Collections.Generic;

using UnityEngine;

namespace MudBun
{
  public class MeshUtil
  {
    public static int EmissionHashUvIndex = 6;
    public static int MetallicSmoothnessUvIndex = 7;

    public static readonly float PositionTolerance = 1e-4f;
    public static readonly float NormalTolerance = 1e-2f;
    public static readonly float PositionToleranceSqr = PositionTolerance * PositionTolerance;
    public static readonly float NormalToleratnceSqr = NormalTolerance * NormalTolerance;

    struct VertKey
    {
      public Vector3 Pos;
      public Vector3 Norm;

      public override int GetHashCode()
      {
        int hash = Codec.Hash(Pos);
        hash = Codec.HashConcat(hash, Norm);
        return hash;
      }

      public override bool Equals(object obj)
      {
          return 
            obj is VertKey other 
            &&( Pos - other.Pos).sqrMagnitude < PositionToleranceSqr 
            && (Norm - other.Norm).sqrMagnitude < NormalTolerance;
      }
    }

    private static readonly Vector3[] s_aRenderBoxProxyVert = 
    {
      new Vector3(-0.5f, -0.5f, -0.5f), 
      new Vector3( 0.5f, -0.5f, -0.5f), 
      new Vector3(-0.5f,  0.5f, -0.5f), 
      new Vector3( 0.5f,  0.5f, -0.5f), 
      new Vector3(-0.5f, -0.5f,  0.5f), 
      new Vector3( 0.5f, -0.5f,  0.5f), 
      new Vector3(-0.5f,  0.5f,  0.5f), 
      new Vector3( 0.5f,  0.5f,  0.5f), 
    };

    private static readonly int[] s_aRenderBoxProxyIndex = 
    {
       0, 1, 3, 0, 3, 2, 
       0, 2, 6, 0, 6, 4, 
       0, 4, 5, 0, 5, 1, 
       7, 6, 2, 7, 2, 3, 
       7, 5, 4, 7, 4, 6, 
       7, 3, 1, 7, 1, 5, 
    };

    private static Vector3 Quantize(Vector3 v, float step)
    {
      Vector3 s = new Vector3(Mathf.Sign(v.x), Mathf.Sign(v.y), Mathf.Sign(v.z));
      v += 0.5f * step * Vector3.one;
      v = VectorUtil.CompDiv(v, step * Vector3.one);
      v = VectorUtil.Abs(v);
      v = new Vector3(Mathf.Floor(v.x), Mathf.Floor(v.y), Mathf.Floor(v.z));
      v = VectorUtil.CompMul(s * step, v);
      return v;
    }

    public static void Weld(Mesh mesh)
    {
      var aOldVert = mesh.vertices;
      var aOldNorm = mesh.normals;
      var aOldColor = mesh.colors;
      var aOldBoneWeight = mesh.boneWeights;
      var aOldBindPose = mesh.bindposes;
      var aOldEmissionHash = new List<Vector4>();
      var aOldMetallicSmoothness = new List<Vector2>();
      mesh.GetUVs(EmissionHashUvIndex, aOldEmissionHash);
      mesh.GetUVs(MetallicSmoothnessUvIndex, aOldMetallicSmoothness);

      var aOldIndex = mesh.GetIndices(0);

      //var vertToIndexMap = new Dictionary<int, int>();
      var vertToIndexMap = new Dictionary<VertKey, int>();
      var indexToIndexMap = new int[aOldVert.Length];
      for (int i = 0; i < aOldIndex.Length; ++i)
      {
        int index = aOldIndex[i];
        //int key = Codec.Hash(Quantize(aOldVert[index], PositionTolerance));
        //key = Codec.HashConcat(key, Quantize(aOldNorm[index], NormalTolerance));
        var key = new VertKey { Pos = Quantize(aOldVert[index], PositionTolerance), Norm = Quantize(aOldNorm[index], NormalTolerance) };

        int newIndex = -1;
        if (!vertToIndexMap.TryGetValue(key, out newIndex))
        {
          newIndex = vertToIndexMap.Count;
          vertToIndexMap.Add(key, newIndex);

          // debugger-friendly duplicate code
          indexToIndexMap[i] = newIndex;
        }
        else
        {
          // debugger-friendly duplicate code
          indexToIndexMap[i] = newIndex;
        }
      }

      int numUniqueVerts = vertToIndexMap.Count;
      var aNewVert = new Vector3[numUniqueVerts];
      var aNewNorm = new Vector3[numUniqueVerts];
      var aNewColor = new Color[numUniqueVerts];
      var aNewEmissionHash = new Vector4[numUniqueVerts];
      var aNewMetallicSmoothness = new Vector2[numUniqueVerts];
      var aNewBoneWeight = new BoneWeight[numUniqueVerts];
      var aNewBindPose = aOldBindPose; // bind poses aren't changed
      for (int oldIndex = 0; oldIndex < indexToIndexMap.Length; ++oldIndex)
      {
        int newIndex = indexToIndexMap[oldIndex];
        aNewVert[newIndex] = aOldVert[oldIndex];
        aNewNorm[newIndex] = aOldNorm[oldIndex];
        aNewColor[newIndex] = aOldColor[oldIndex];
        aNewEmissionHash[newIndex] = aOldEmissionHash[oldIndex];
        aNewMetallicSmoothness[newIndex] = aOldMetallicSmoothness[oldIndex];

        if (aOldBoneWeight != null && aOldBoneWeight.Length >= aOldVert.Length)
          aNewBoneWeight[newIndex] = aOldBoneWeight[oldIndex];
      }

      var aNewIndex = new int[aOldIndex.Length];
      for (int i = 0; i < aOldIndex.Length; ++i)
      {
        aNewIndex[i] = indexToIndexMap[aOldIndex[i]];
      }

      var topology = mesh.GetTopology(0);
      mesh.Clear();
      mesh.SetVertices(aNewVert);
      mesh.SetNormals(aNewNorm);
      mesh.SetColors(aNewColor);
      mesh.boneWeights = aNewBoneWeight;
      mesh.bindposes = aNewBindPose;
      mesh.SetUVs(EmissionHashUvIndex, aNewEmissionHash);
      mesh.SetUVs(MetallicSmoothnessUvIndex, aNewMetallicSmoothness);
      mesh.SetIndices(aNewIndex, topology, 0);
    }

    private static Vector3[] s_aRenderBoxProxyVertBuffer;
    public static void UpdateRenderBoxProxy(ref Mesh mesh, Aabb bounds)
    {
      if (mesh == null)
      {
        mesh = new Mesh();
      }

      if (s_aRenderBoxProxyVertBuffer == null 
         || s_aRenderBoxProxyVertBuffer.Length != s_aRenderBoxProxyVert.Length)
      {
        s_aRenderBoxProxyVertBuffer = new Vector3[s_aRenderBoxProxyVert.Length];
      }

      Vector3 size = bounds.Size;
      Vector3 center = bounds.Center;

      for (int i = 0, n = s_aRenderBoxProxyVert.Length; i < n; ++i)
      {
        s_aRenderBoxProxyVertBuffer[i] = VectorUtil.CompMul(size, s_aRenderBoxProxyVert[i]) + center;
      }

      mesh.vertices = s_aRenderBoxProxyVertBuffer;
      mesh.SetIndices(s_aRenderBoxProxyIndex, MeshTopology.Triangles, 0);
    }
  }
}

