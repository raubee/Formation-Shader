using UnityEngine;

public class ComputeShaderMeshDampling : MonoBehaviour
{
    [SerializeField] private float _Speed;
    [SerializeField] private ComputeShader _cs;
    [SerializeField] private Material _material;

    private Mesh _mesh;

    private int _kernelId;
    private uint _kernelX;
    private uint _kernelY;
    private uint _kernelZ;

    private const int STRIDE_FLOAT3 = sizeof(float) * 3;

    public static class MyStrings
    {
        public const string KernelName = "CSMain";
        public const string Time = "Time";
        public const string Speed = "Speed";
        public const string Vertices = "Vertices";
        public const string Normals = "Normals";
    }

    private ComputeBuffer _verticesBuffer;
    private ComputeBuffer _normalsBuffer;

    private void Awake()
    {
        _mesh = GetComponent<MeshFilter>().mesh;
    }

    private void Start()
    {
        _kernelId = _cs.FindKernel(MyStrings.KernelName);

        _cs.GetKernelThreadGroupSizes(_kernelId, out _kernelX, out _kernelY, out _kernelZ);

        Debug.LogFormat("[ComputeShaderDampling] Kernel Id {0}, size : ( X : {1}, Y : {2}, Z : {3} )", _kernelId, _kernelX, _kernelY, _kernelZ);

        _verticesBuffer = new ComputeBuffer(_mesh.vertexCount, STRIDE_FLOAT3);
        _normalsBuffer = new ComputeBuffer(_mesh.vertexCount, STRIDE_FLOAT3);

        Debug.LogFormat("[ComputeShaderDampling] Vertices count : {0}", _mesh.vertexCount);

        _verticesBuffer.SetData(_mesh.vertices);
        _normalsBuffer.SetData(_mesh.normals);

        _cs.SetBuffer(_kernelId, MyStrings.Vertices, _verticesBuffer);
        _cs.SetBuffer(_kernelId, MyStrings.Normals, _normalsBuffer);
    }

    private void Update()
    {
        _cs.SetFloat(MyStrings.Time, Time.time);
        _cs.SetFloat(MyStrings.Speed, _Speed);

        _cs.Dispatch(_kernelId, (int)(_mesh.vertexCount / _kernelX), (int)_kernelY, (int)_kernelZ);

        Vector3[] vertices = new Vector3[_mesh.vertexCount];
        _verticesBuffer.GetData(vertices);

        _mesh.vertices = vertices;
    }

    private void OnDestroy()
    {
        _verticesBuffer.Release();
        _normalsBuffer.Release();

        _verticesBuffer.Dispose();
        _normalsBuffer.Dispose();
    }
}
