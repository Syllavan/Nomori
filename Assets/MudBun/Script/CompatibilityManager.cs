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
using System.IO;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.PackageManager.Requests;
#endif

using UnityEngine;

namespace MudBun
{
#if UNITY_EDITOR
  [InitializeOnLoad]
#endif
  public class CompatibilityManager
  {
    static CompatibilityManager()
    {
      TryCheckCompatibility();
    }

    public static void TryCheckCompatibility()
    {
#if UNITY_EDITOR
      if (Application.isPlaying)
        return;

#if !MUDBUN_DEV
      var config = GetConfig();
      if (config == null)
      {
        Debug.LogWarning("MudBun: Config file not found.");
        return;
      }

      if (!config.CheckCompatibility)
        return;

      LoadPackageList();
#endif
#endif
    }

    public static void EndCompatibilityCheck()
    {
#if UNITY_EDITOR
      if (Application.isPlaying)
        return;

      if (s_loadingPackageList)
      {
        EditorApplication.update -= UpdateLoadPackageList;
        s_loadingPackageList = false;
      }
#endif
    }

#if UNITY_EDITOR
    private static readonly string HDRPPackageId = "com.unity.render-pipelines.high-definition";

    private enum SRPVersion
    {
      SRP_10_0_0 = 100000,
      SRP_10_1_0 = 100100,
      SRP_10_2_2 = 100202,
      SRP_RECENT = 999999,
    }

    private static Dictionary<string, SRPVersion> s_srpVersionTable = new Dictionary<string, SRPVersion>()
    {
      { "10.0.0-preview.26", SRPVersion.SRP_10_0_0 }, 
      { "10.0.0-preview.27", SRPVersion.SRP_10_0_0 }, 
      { "10.1.0",            SRPVersion.SRP_10_1_0 }, 
      { "10.2.2",            SRPVersion.SRP_10_2_2 }, 
    };

    private static Dictionary<SRPVersion, string> s_hdrpPackageTable = new Dictionary<SRPVersion, string>()
    {
      { SRPVersion.SRP_10_0_0, "3ff13cd87f98e6f4cae38dac0e0f632b" }, 
      { SRPVersion.SRP_10_1_0, "3ff13cd87f98e6f4cae38dac0e0f632b" }, 
      { SRPVersion.SRP_10_2_2, "3ff13cd87f98e6f4cae38dac0e0f632b" }, 
      { SRPVersion.SRP_RECENT, "3ff13cd87f98e6f4cae38dac0e0f632b" }, 
    };

    private static bool s_loadingPackageList = false;
    private static ListRequest s_packageListRequest;

    private static MudBunConfig GetConfig()
    {
      return (MudBunConfig) Resources.Load("MudBun Config");
    }

    public static void CheckCompatibility()
    {
      LoadPackageList();
    }

    private static void LoadPackageList()
    {
      if (!s_loadingPackageList)
      {
        EditorApplication.update += UpdateLoadPackageList;
        s_loadingPackageList = true;
      }
    }

    private static void UpdateLoadPackageList()
    {
      if (s_packageListRequest == null)
      {
        s_packageListRequest = UnityEditor.PackageManager.Client.List(true);
      }

      if (s_packageListRequest == null)
      {
        EditorApplication.update -= UpdateLoadPackageList;
        s_loadingPackageList = false;
        return;
      }

      if (!s_packageListRequest.IsCompleted)
        return;

      EditorApplication.update -= UpdateLoadPackageList;
      s_loadingPackageList = false;

      if (!Application.isPlaying)
      {
        DoCompatibilityCheck();
      }

      var config = GetConfig();
      config.CheckCompatibility = false;
      AssetDatabase.SaveAssets();
    }

    private static bool DoCompatibilityCheck()
    {
      SRPVersion version = SRPVersion.SRP_RECENT;
      string versionString = "";
      string srpPackageId = "";
      string packageGuid = "";
      string packagePath = "";

      foreach (var info in s_packageListRequest.Result)
      {
        if (info.name.Equals(HDRPPackageId))
        {
          if (s_srpVersionTable.ContainsKey(info.version))
          {
            versionString = info.version;
            version = s_srpVersionTable[versionString];
            srpPackageId = HDRPPackageId;
            packageGuid = s_hdrpPackageTable[version];
            packagePath = AssetDatabase.GUIDToAssetPath(packageGuid);
            break;
          }
        }
      }

      if (!File.Exists(packagePath))
      {
        if (!packageGuid.Equals(""))
        {
          Debug.LogWarning($"MudBun: Compatibility package not found for \"{srpPackageId}\" version {versionString}.\nDid you forget to import the MudBun/Compatibility folder?");
        }

        return true;
      }

      AssetDatabase.ImportPackage(packagePath, false);
      Debug.Log($"MudBun: Updated compatibility to \"{srpPackageId}\" version {versionString}.");

      MudRendererBase.ReloadAllShaders();

      return true;
    }
#endif
  }
}

