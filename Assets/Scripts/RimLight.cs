using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class RimLight : MonoBehaviour
{
    public Color color = new Color(0.75f, 0.75f, 1.0f, 0.0f);

    public float intensity = 1.0f;
    public float fresnelBias = 0.0f;
    public float fresnelScale = 5.0f;
    public float fresnelPow = 5.0f;

    public float edgeIntensity = 0.3f;
    [Range(0.0f, .99f)]
    public float edgeThreshold = 0.8f;
    public float edgeRadius = 1.0f;
    public Shader shader;
    Material material;

    public Vector4 GetLinearColor()
    {
        return new Vector4(
            Mathf.GammaToLinearSpace(color.r),
            Mathf.GammaToLinearSpace(color.g),
            Mathf.GammaToLinearSpace(color.b),
            1.0f
        );
    }

    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        if (material == null) {
            shader = Shader.Find("Hidden/Image Effects/RimLight");
            material = new Material(shader);
        }

        var cam = GetComponent<Camera>();
        var view = cam.worldToCameraMatrix;
        var proj = cam.projectionMatrix;
        var invViewProj = (view * proj).inverse;
        material.SetMatrix("_InvViewProj", invViewProj);
        material.SetVector("_Color", GetLinearColor());
        material.SetVector("_Params1", new Vector4(fresnelBias, fresnelScale, fresnelPow, intensity));
        material.SetVector("_Params2", new Vector4(edgeIntensity, edgeThreshold, edgeRadius, 0.0f));

        Graphics.Blit(src, dst, material);
    }
}