using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Renderer))]
public class RaymarchingTransform : MonoBehaviour
{
    [SerializeField] private Transform _firstTransform;
    [SerializeField] private Transform _secondTransform;
    [SerializeField] private Transform _thirdTransform;

    private void Update()
    {
        MaterialPropertyBlock propertyBlock = new MaterialPropertyBlock();

        propertyBlock.SetVector("_FirstPos", _firstTransform.position);
        propertyBlock.SetVector("_FirstScale", _firstTransform.localScale);

        propertyBlock.SetVector("_SecondPos", _secondTransform.position);
        propertyBlock.SetVector("_SecondScale", _secondTransform.localScale);

        propertyBlock.SetVector("_WorldPos", transform.position);

        GetComponent<Renderer>().SetPropertyBlock(propertyBlock);
    }
}
