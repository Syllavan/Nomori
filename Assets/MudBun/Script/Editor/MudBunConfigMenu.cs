/******************************************************************************/
/*
  Project   - MudBun
  Publisher - Long Bunny Labs
              http://LongBunnyLabs.com
  Author    - Ming-Lun "Allen" Chou
              http://AllenChou.net
*/
/******************************************************************************/

using UnityEditor;
using UnityEngine;

namespace MudBun
{
  public class MudBunConfigMenu
  {
    [MenuItem("MudBun/Update Compatibility")]
    public static void UpdateCompatibility()
    {
      #if !MUDBUN_DEV
        CompatibilityManager.CheckCompatibility();
      #endif
    }

    //[MenuItem("MudBun/Configure MudBun")]
    public static void SelectConfigFile()
    {
      var config = Resources.Load("MudBun Config");
      if (config == null)
        return;

      Selection.activeObject = config;
    }
  }
}