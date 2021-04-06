using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MudBunShellPlacer : MonoBehaviour
{

    public Transform CameraShell;
    public Transform CameraLocation;
    public Transform CubeShell;
    public Transform CubeLocation;

    // Start is called before the first frame update
    void Start()
    {
        CubeShell.position = CubeLocation.position;
    }

    // Update is called once per frame
    void Update()
    {
        CameraShell.position = CameraLocation.position;
    }
}
