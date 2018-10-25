using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Renderer))]
public class RaymarchingTransform : MonoBehaviour
{
    private void Update()
    {
        MaterialPropertyBlock propertyBlock = new MaterialPropertyBlock();
        propertyBlock.SetVector("_WorldPos", transform.position);
        GetComponent<Renderer>().SetPropertyBlock(propertyBlock);
    }
}
