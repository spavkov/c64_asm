using DemoEffectsShowcase.Core;
using System.Numerics;

namespace DemoEffectsShowcase.Effects;

public sealed class SpecularPlasmaEffect : DemoSceneEffect
{
    private int _width;
    private int _height;
    private double _time;

    private float _speed = 1.0f;
    private float _zoom = 1.0f;
    private float _specular = 1.0f;
    private Vector3 _tint = Vector3.One;

    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;
    private const int BaseBlock = 5;

    public SpecularPlasmaEffect()
    {
        _parameters =
        [
            EffectParameters.Float("speed", "Speed", () => _speed, v => _speed = v, 0.2f, 4.0f),
            EffectParameters.Float("zoom", "Zoom", () => _zoom, v => _zoom = v, 0.4f, 2.0f),
            EffectParameters.Float("specular", "Specular", () => _specular, v => _specular = v, 0.0f, 2.5f),
            EffectParameters.Color3("tint", "Color Tint", () => _tint, v => _tint = v)
        ];
    }

    public string Id => "specular-plasma";
    public string Name => "Specular Plasma";
    public string Description => "Cosine-palette plasma with glossy specular highlights.";
    public IReadOnlyList<string> Tags => ["plasma", "specular", "palette", "shader-style"];

    public void Initialize(in EffectInitContext context)
    {
        Resize(context.Width, context.Height);
        _time = 0;
    }

    public void Resize(int width, int height)
    {
        _width = Math.Max(1, width);
        _height = Math.Max(1, height);
    }

    public void Update(double deltaSeconds) => _time += deltaSeconds * _speed;

    public void Render(IntPtr renderer)
    {
        // We sample in small blocks to keep this CPU effect smooth at higher resolutions.
        var block = Math.Max(BaseBlock, (int)MathF.Sqrt((_width * _height) / 15000f));
        var time = (float)_time;
        var aspectX = _width / (float)_height;

        // UV step for one rendered block in normalized effect space.
        // This is used to estimate gradient direction for the specular pass.
        var du = 4f * _zoom * aspectX * block / _width;
        var dv = 4f * _zoom * block / _height;

        for (var y = 0; y < _height; y += block)
        {
            for (var x = 0; x < _width; x += block)
            {
                // Convert screen coordinates into aspect-correct UV space, then scroll with time.
                var uv = ToUv(x, y, time, aspectX);

                // Base color from the article's cosine palette plasma formula.
                var baseColor = EvaluateBaseColor(uv, time);

                // CPU approximation of shader derivatives:
                // sample neighboring UVs, measure color change, and treat that as surface slope.
                var colorDx = EvaluateBaseColor(new Vector2(uv.X + du, uv.Y), time);
                var colorDy = EvaluateBaseColor(new Vector2(uv.X, uv.Y + dv), time);
                var gradX = (colorDx - baseColor).Length();
                var gradY = (colorDy - baseColor).Length();

                // "Normal" built from gradient magnitudes plus a small positive Z component.
                // Flat zones keep higher Z and therefore stronger viewer-facing highlights.
                var normal = Vector3.Normalize(new Vector3(gradX, gradY, 0.5f / _height));
                var specularIntensity = MathF.Pow(MathF.Max(normal.Z, 0f), 2f) * _specular;

                // Warm highlight tint from the referenced implementation, with ambient floor.
                var warmTint = new Vector3(1f, 0.7f, 0.4f);
                var litColor = baseColor * (warmTint * specularIntensity + new Vector3(0.75f));

                // Final user tint and clamp into byte color range.
                var finalColor = Vector3.Clamp(new Vector3(
                    litColor.X * _tint.X,
                    litColor.Y * _tint.Y,
                    litColor.Z * _tint.Z), Vector3.Zero, Vector3.One);

                SdlFx.FillRect(
                    renderer,
                    x,
                    y,
                    block,
                    block,
                    (byte)(finalColor.X * 255f),
                    (byte)(finalColor.Y * 255f),
                    (byte)(finalColor.Z * 255f));
            }
        }
    }

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;
    public void Dispose() { }

    private Vector2 ToUv(int x, int y, float time, float aspectX)
    {
        var u = 4f * _zoom * (x / (float)_width) * aspectX + time * 0.3f;
        var v = 4f * _zoom * (y / (float)_height) + time * 0.3f;
        return new Vector2(u, v);
    }

    private static Vector3 EvaluateBaseColor(Vector2 uv, float time)
    {
        // Two oscillating phase terms evolve at different rates and directions.
        // Their mismatch is what creates the continuously morphing plasma flow.
        var phaseVertical = 0.1f + MathF.Cos(uv.Y + MathF.Sin(0.148f - time)) + 2.4f * time;
        var phaseHorizontal = 0.9f + MathF.Sin(uv.X + MathF.Cos(0.628f + time)) - 0.7f * time;

        // Radial distance introduces circular structure so the pattern is not purely linear.
        var radialDistance = uv.Length();

        // Main interference equation from the article:
        // multiply cosine and sine fields to produce sharp moving bands.
        var plasma = 7f * MathF.Cos(radialDistance + phaseHorizontal)
                       * MathF.Sin(phaseVertical + phaseHorizontal);

        // Cosine palette mapping with phase-shifted RGB channels.
        // 0.5 + 0.5*cos(...) remaps channel values from [-1,1] to [0,1].
        return new Vector3(
            0.5f + 0.5f * MathF.Cos(plasma + 0.2f),
            0.5f + 0.5f * MathF.Cos(plasma + 0.5f),
            0.5f + 0.5f * MathF.Cos(plasma + 0.9f));
    }
}
