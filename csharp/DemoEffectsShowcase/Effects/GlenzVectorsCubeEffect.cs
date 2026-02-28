using DemoEffectsShowcase.Core;
using System.Numerics;

namespace DemoEffectsShowcase.Effects;

public sealed class GlenzVectorsCubeEffect : DemoSceneEffect
{
    private readonly WireframeCubeEffect _base = new();
    private float _alpha = 1f;
    private readonly IReadOnlyList<EffectParameterDefinition> _params;

    public GlenzVectorsCubeEffect()
    {
        _params =
        [
            // Reserved for future blending support.
            // Kept as a visible knob so UI and parameter contracts remain stable.
            EffectParameters.Float("alpha", "Transparency", () => _alpha, v => _alpha = v, 0.2f, 2f)
        ];
    }

    public string Id => "glenz-cube";
    public string Name => "Glenz Vectors Cube";
    public string Description => "Transparent glenz-style rotating cube faces.";
    public IReadOnlyList<string> Tags => ["glenz", "cube", "transparent"];

    public void Initialize(in EffectInitContext context) => _base.Initialize(context);

    public void Resize(int width, int height) => _base.Resize(width, height);

    public void Update(double deltaSeconds)
    {
        // Slightly slower than base wireframe for a softer "glenz" feel.
        _base.Update(deltaSeconds * 0.9);
    }

    public void Render(IntPtr renderer)
    {
        // Current implementation reuses the wireframe cube renderer.
        _base.Render(renderer);
    }

    public void Dispose() => _base.Dispose();

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _params;
}
