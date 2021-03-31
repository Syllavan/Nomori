/******************************************************************************/
/*
  Project   - MudBun
  Publisher - Long Bunny Labs
              http://LongBunnyLabs.com
  Author    - Ming-Lun "Allen" Chou
              http://AllenChou.net
*/
/******************************************************************************/

/*
using UnityEditor;

namespace MudBun
{
  public class NoiseMenu
  {
    private static int[] NoiseCacheDimensionInts => MudRendererBase.NoiseCacheDimensionInts;

    // https://github.com/SebLague/Clouds/blob/fcc997c40d36c7bedf95a294cd2136b8c5127009/Assets/Scripts/Clouds/Noise/Save/Save3D.cs
    [MenuItem("MudBun/Bake Noise Texture")]
    private static void BakeNoiseTexture()
    {
      if (!MudRendererBase.ValidateComputeShaders())
        return;

      var noiseCache = MudRendererBase.NoiseCache;
      if (noiseCache == null)
        return;

      var tex = TextureUtil.RenderTextureToTexture3D(null, noiseCache);
      if (tex == null)
        return;

      AssetDatabase.CreateAsset(tex, "Assets/MudBun/Resources/Common/PerlinNoise.asset");
    }
  }
}
*/
