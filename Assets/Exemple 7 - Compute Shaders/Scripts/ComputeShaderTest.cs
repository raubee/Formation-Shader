using UnityEngine;

public class ComputeShaderTest : MonoBehaviour
{
    [SerializeField] private Vector2Int _textureSize;
    [SerializeField] private float _Speed;
    [SerializeField] private ComputeShader _cs;
    [SerializeField] private Material _material;

    private RenderTexture _renderTexture;
    private int _kernelId;

    private const int TEXTURE_DEPTH = 24;

    private uint _kernelX;
    private uint _kernelY;
    private uint _kernelZ;

    public static class MyStrings
    {
        public const string KernelName = "CSMain";
        public const string ResultTexture = "Result";
        public const string Time = "Time";
        public const string Speed = "Speed";
        public const string MaterialMainTex = "_MainTex";
    }

    private void Start()
    {
        // Run kernel
        //
        _renderTexture = new RenderTexture(_textureSize.x, _textureSize.y, TEXTURE_DEPTH)
        {
            enableRandomWrite = true
        };

        _renderTexture.Create();

        _kernelId = _cs.FindKernel(MyStrings.KernelName);
        _cs.SetTexture(_kernelId, MyStrings.ResultTexture, _renderTexture);

        _cs.GetKernelThreadGroupSizes(_kernelId, out _kernelX, out _kernelY, out _kernelZ);
        Debug.LogFormat("[ComputeShaderTest] Kernel Id {0} size : ( X : {1}, Y : {2}, Z : {3} )", _kernelId, _kernelX, _kernelY, _kernelZ);

        _material.SetTexture(MyStrings.MaterialMainTex, _renderTexture);
    }

    private void Update()
    {
        _cs.SetFloat(MyStrings.Time, Time.time);
        _cs.SetFloat(MyStrings.Speed, _Speed);
        _cs.Dispatch(_kernelId, (int)(_textureSize.x / _kernelX), (int)(_textureSize.y / _kernelY), (int)_kernelZ);
    }

    private void OnDestroy()
    {
        _renderTexture.Release();
        DestroyImmediate(_renderTexture);
    }
}
